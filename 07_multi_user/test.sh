#!/bin/bash

set -e

PWD=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $PWD/../functions.sh

session_id=$1
SQL_VERSION=$2
EXPLAIN_ANALYZE=$3

if [[ "$session_id" == "" || "$SQL_VERSION" == "" || "$EXPLAIN_ANALYZE" == "" ]]; then
	echo "Error: you must provide the session id, SQL_VERSION, and explain analyze true/false as parameters."
	echo "Example: ./rollout.sh 2 tpch false"
	echo "This will execute the TPC-H queries for sesion 2 that are dynamically without explain analyze."
	echo "created with qgen and not use EXPLAIN ANALYZE."
	exit 1
fi

source_bashrc

step=testing_$session_id

init_log $step

if [ "$SQL_VERSION" == "tpch" ]; then
	sql_dir=$PWD/$SQL_VERSION/$session_id

	query_id=100

	for order in $(seq 1 22); do
		query_id=$((query_id+1))
		query_number=$(grep begin $sql_dir/multi.sql | head -n"$order" | tail -n1 | awk -F ' ' '{print $2}')
		q=$(printf %02d $order)
		start_position=$(grep -n "begin q""$q" $sql_dir/multi.sql | awk -F ':' '{print $1}')
		end_position=$(grep -n "end q""$q" $sql_dir/multi.sql | awk -F ':' '{print $1}')
		target_filename="$query_id"".query.""$query_number"".sql"
		#add explain analyze 
		echo "echo \":EXPLAIN_ANALYZE\" > $sql_dir/$target_filename"
		echo ":EXPLAIN_ANALYZE" > $sql_dir/$target_filename
		echo "sed -n \"$start_position\",\"$end_position\"p $sql_dir/multi.sql >> $sql_dir/$target_filename"
		sed -n "$start_position","$end_position"p $sql_dir/multi.sql >> $sql_dir/$target_filename
	done
	echo "rm -f $sql_dir/multi.sql"
	rm -f $sql_dir/multi.sql 
else
	echo "ERROR: Unsupported SQL Version!"
	exit 1
fi

tuples="0"
for i in $(ls $sql_dir/*.sql); do

	start_log
	id=$i
	schema_name=$session_id
	table_name=$(basename $i | awk -F '.' '{print $3}')

	if [ "$EXPLAIN_ANALYZE" == "false" ]; then
		echo "psql -A -q -t -P pager=off -v ON_ERROR_STOP=ON -v EXPLAIN_ANALYZE="" -f $i | wc -l"
		tuples=$(psql -A -q -t -P pager=off -v ON_ERROR_STOP=ON -v EXPLAIN_ANALYZE="" -f $i | wc -l; exit ${PIPESTATUS[0]})
		tuples=$(($tuples-1))
	else
		myfilename=$(basename $i)
		mylogfile=$PWD/../log/"$session_id"".""$myfilename"".multi.explain_analyze.log"
		echo "psql -A -q -t -P pager=off -v ON_ERROR_STOP=ON -v EXPLAIN_ANALYZE=\"EXPLAIN ANALYZE\" -f $i"
		psql -A -q -t -P pager=off -v ON_ERROR_STOP=ON -v EXPLAIN_ANALYZE="EXPLAIN ANALYZE" -f $i > $mylogfile
		tuples="0"
	fi
		
	#remove the extra line that \timing adds
	log $tuples
done

end_step $step
