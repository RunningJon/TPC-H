#!/bin/bash
set -e

PWD=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $PWD/../functions.sh
source_bashrc

step=load
init_log $step

GEN_DATA_SCALE=$1
EXPLAIN_ANALYZE=$2
RANDOM_DISTRIBUTION=$3
MULTI_USER_COUNT=$4
SINGLE_USER_ITERATIONS=$5

if [[ "$GEN_DATA_SCALE" == "" || "$EXPLAIN_ANALYZE" == "" || "$RANDOM_DISTRIBUTION" == "" || "$MULTI_USER_COUNT" == "" || "$SINGLE_USER_ITERATIONS" == "" ]]; then
	echo "You must provide the scale as a parameter in terms of Gigabytes, true/false to run queries with EXPLAIN ANALYZE option, true/false to use random distrbution, multi-user count, and the number of sql iterations."
	echo "Example: ./rollout.sh 100 false tpch false 5 1"
	exit 1
fi

ADMIN_HOME=$(eval echo ~$ADMIN_USER)

get_version
if [[ "$VERSION" == *"gpdb"* ]]; then
	filter="gpdb"
elif [ "$VERSION" == "postgresql" ]; then
	filter="postgresql"
else
	echo "ERROR: Unsupported VERSION $VERSION!"
	exit 1
fi

copy_script()
{
	echo "copy the start and stop scripts to the hosts in the cluster"
	for i in $(cat $PWD/../segment_hosts.txt); do
		echo "scp start_gpfdist.sh stop_gpfdist.sh $ADMIN_USER@$i:$ADMIN_HOME/"
		scp $PWD/start_gpfdist.sh $PWD/stop_gpfdist.sh $ADMIN_USER@$i:$ADMIN_HOME/
	done
}
stop_gpfdist()
{
	echo "stop gpfdist on all ports"
	for i in $(cat $PWD/../segment_hosts.txt); do
		ssh -n -f $i "bash -c 'cd ~/; ./stop_gpfdist.sh'"
	done
}
start_gpfdist()
{
	stop_gpfdist
	sleep 1
	for i in $(psql -A -t -c "select rank() over (partition by g.hostname order by p.fselocation), g.hostname, p.fselocation as path from gp_segment_configuration g join pg_filespace_entry p on g.dbid = p.fsedbid where content >= 0 order by g.hostname"); do
		CHILD=$(echo $i | awk -F '|' '{print $1}')
		EXT_HOST=$(echo $i | awk -F '|' '{print $2}')
		GEN_DATA_PATH=$(echo $i | awk -F '|' '{print $3}')
		GEN_DATA_PATH=$GEN_DATA_PATH/pivotalguru
		PORT=$(($GPFDIST_PORT + $CHILD))
		echo "executing on $EXT_HOST ./start_gpfdist.sh $PORT $GEN_DATA_PATH"
		ssh -n -f $EXT_HOST "bash -c 'cd ~/; ./start_gpfdist.sh $PORT $GEN_DATA_PATH'"
		sleep 1
	done
}

if [[ "$VERSION" == *"gpdb"* ]]; then
	copy_script
	start_gpfdist

	for i in $(ls $PWD/*.$filter.*.sql); do
		start_log

		id=$(echo $i | awk -F '.' '{print $1}')
		schema_name=$(echo $i | awk -F '.' '{print $2}')
		table_name=$(echo $i | awk -F '.' '{print $3}')

		echo "psql -f $i | grep INSERT | awk -F ' ' '{print \$3}'"
		tuples=$(psql -f $i | grep INSERT | awk -F ' ' '{print $3}'; exit ${PIPESTATUS[0]})

		log $tuples
	done
else

	if [ "$PGDATA" == "" ]; then
		echo "ERROR: Unable to determine PGDATA environment variable.  Be sure to have this set for the admin user."
		exit 1
	fi

	for i in $(ls $PWD/*.$filter.*.sql); do
		start_log

		id=$(echo $i | awk -F '.' '{print $1}')
		schema_name=$(echo $i | awk -F '.' '{print $2}')
		table_name=$(echo $i | awk -F '.' '{print $3}')

		for filename in $(ls $PGDATA/pivotalguru/$table_name*); do
			echo "psql -f $i -v filename=\"$filename\" | grep INSERT | awk -F ' ' '{print \$3}'"
			tuples=$(psql -f $i -v filename="$filename" | grep INSERT | awk -F ' ' '{print $3}'; exit ${PIPESTATUS[0]})

			log $tuples
		done
	done
fi

if [[ "$VERSION" == *"gpdb"* ]]; then
	stop_gpfdist

	#Analyze schema using analyzedb

	max_id=$(ls $PWD/*.sql | tail -1)
	i=$(basename $max_id | awk -F '.' '{print $1}')

	dbname="$PGDATABASE"
	if [ "$dbname" == "" ]; then
		dbname="$ADMIN_USER"
	fi

	if [ "$PGPORT" == "" ]; then
		export PGPORT=5432
	fi

	start_log

	schema_name="tpch"
	table_name="tpch"

	analyzedb -d $dbname -s tpch --full -a

	tuples="0"
	log $tuples
fi

end_step $step
