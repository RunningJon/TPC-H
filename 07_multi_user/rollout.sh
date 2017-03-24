#!/bin/bash

set -e

GEN_DATA_SCALE=$1
EXPLAIN_ANALYZE=$2
SQL_VERSION=$3
RANDOM_DISTRIBUTION=$4
MULTI_USER_COUNT=$5
SINGLE_USER_ITERATIONS=$6

if [[ "$GEN_DATA_SCALE" == "" || "$EXPLAIN_ANALYZE" == "" || "$SQL_VERSION" == "" || "$RANDOM_DISTRIBUTION" == "" || "$MULTI_USER_COUNT" == "" || "$SINGLE_USER_ITERATIONS" == "" ]]; then
        echo "You must provide the scale as a parameter in terms of Gigabytes, true/false to run queries with EXPLAIN ANALYZE option, the SQL_VERSION, and true/false to use random distrbution."
        echo "Example: ./rollout.sh 100 false tpch false 5 1"
        echo "This will create 100 GB of data for this test, not run EXPLAIN ANALYZE, use standard TPC-DS, not use random distribution and use 5 sessions for the multi-user test."
        exit 1
fi

if [ "$MULTI_USER_COUNT" -eq "0" ]; then
	echo "MULTI_USER_COUNT set at 0 so exiting..."
	exit 0
fi

PWD=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $PWD/../functions.sh
source_bashrc

get_psql_count()
{
	psql_count=$(ps -ef | grep psql | grep multi_user | grep -v grep | wc -l)
}

get_file_count()
{
	file_count=$(ls $PWD/../log/end_testing* 2> /dev/null | wc -l)
}

get_file_count
if [ "$file_count" -ne "$MULTI_USER_COUNT" ]; then
	rm -f $PWD/../log/end_testing_*.log
	rm -f $PWD/../log/testing*.log
	rm -f $PWD/../log/rollout_testing_*.log
	rm -f $PWD/../log/*multi.explain_analyze.log

	if [[ "$SQL_VERSION" == "tpch" ]]; then
		#Create queries
		echo "cd $PWD/queries"
		cd $PWD/queries
		for i in $(seq 1 $MULTI_USER_COUNT); do
			sql_dir="$PWD"/../$SQL_VERSION/"$i"
			echo "checking for directory $sql_dir"
			if [ ! -d "$sql_dir" ]; then
				echo "mkdir -p $sql_dir"
				mkdir -p $sql_dir
			fi
			echo "rm -f $sql_dir/*.sql"
			rm -f $sql_dir/*.sql
			echo "./qgen -p $i -c -v > $sql_dir/multi.sql"
			./qgen -p $i -c -v > $sql_dir/multi.sql
		done
		cd ..
	else
		echo "ERROR: Unsupported SQL VERSION!"
		exit 1
	fi

	for x in $(seq 1 $MULTI_USER_COUNT); do
		session_log=$PWD/../log/testing_session_$x.log
		echo "$PWD/test.sh $x $SQL_VERSION $EXPLAIN_ANALYZE"
		$PWD/test.sh $x $SQL_VERSION $EXPLAIN_ANALYZE > $session_log 2>&1 < $session_log &
	done

	sleep 60

	get_psql_count
	echo "Now executing queries. This make take a while."
	echo -ne "Executing queries."
	while [ "$psql_count" -gt "0" ]; do
		now=$(date)
		echo "$now"
		if ls $PWD/../log/rollout_testing_* 1>/dev/null 2>&1; then
			wc -l $PWD/../log/rollout_testing_*
		else
			echo "No queries complete yet."
		fi

		sleep 60
		get_psql_count
	done
	echo "queries complete"
	echo ""

	get_file_count

	if [ "$file_count" -ne "$MULTI_USER_COUNT" ]; then
		echo "The number of successfully completed sessions is less than expected!"
		echo "Please review the log files to determine which queries failed."
		exit 1
	fi
fi
