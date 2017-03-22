#!/bin/bash
set -e
source ../functions.sh
DEMO=tpch
HOSTNAME=`hostname`
DATA_DIR=$1
DEMO_DIR=$2
GPFDIST_PORT=$3

PWD=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

echo ""
echo "############################################################################"
echo "Demo Configuration"
echo "############################################################################"
echo "DATA_DIR: $DATA_DIR"
echo "DEMO_DIR: $DEMO_DIR"
echo "GPFDIST_PORT: $GPFDIST_PORT"

if [ "$GPFDIST_PORT" == "" ]; then
	echo "Error: Unable to determine parameters for this script!"
	exit 1
fi

#compile dbgen if needed
if [[ ! -f $PWD/dbgen || ! -f $PWD/qgen || ! -f $PWD/dists.dss ]]; then
	cd "$PWD/tpch_2_17_0/dbgen"
	make
	pwd
	cp dbgen ../../
	cp qgen ../../
	cp dists.dss ../../
	cd ../../
fi

#use dbgen to generate the data if needed
count=`ls /$DATA_DIR/$DEMO_DIR/data/*.tbl 2> /dev/null | wc -l`
if [ "$count" -ne "8" ]; then
	rm -f /$DATA_DIR/$DEMO_DIR/data/*.tbl
	./dbgen -vf -s 1
	mv *.tbl /$DATA_DIR/$DEMO_DIR/data/
fi

echo ""
echo "############################################################################"
echo "This is a demonstration of the performance and SQL compliance of Pivotal"
echo "HAWQ using the TPC-H benchmark. The size of the benchmark is 1GB which was"
echo "chosen to work on a single node VM.  Also, the tables are stored in the"
echo "parquet format using snappy compression." 
echo "The TPC-H benchmark has defined queries with parameters that should be"
echo "chosen at random.  To simplify this demo, the \"query validation\""
echo "parameters were used for all queries instead of picking a value at random."
echo "Steps:"
echo "1. Create a \"reports\" schema in HAWQ to store execution times"
echo "2. Load 1GB of TPC-H data into HAWQ"
echo "3. Create and load tables into HAWQ"
echo "4. Execute TPC-H SELECT statements with HAWQ"
echo "5. Capture performance metrics for each step with the grand total"
echo "############################################################################"
echo ""
read -p "Hit enter to continue..."
echo ""
source_bashrc
set_psqlrc
start_gpfdist
create_reports_schema "$PWD"
remove_old_log "$PWD"

echo "############################################################################"
echo "HAWQ Begin"
echo "############################################################################"
#HAWQ Tables
for i in $( ls *.hawq.sql ); do
	table_name=`echo $i | awk -F '.' ' { print $2 "." $3 } '`
	file_name=`echo $i | awk -F '.' ' { print $3 } '`
	echo $i
	#begin time
	T="$(date +%s%N)"

	LOCATION="'gpfdist://$HOSTNAME:$GPFDIST_PORT/$file_name.tbl'"
	psql -a -P pager=off -f $i -v LOCATION=$LOCATION
	echo ""

	log
done
echo ""
echo "############################################################################"
echo "Completed HAWQ"
echo "############################################################################"
echo ""
stop_gpfdist
echo "############################################################################"
echo "Results"
echo "############################################################################"
echo ""
psql -P pager=off -f report.sql
echo ""
echo "############################################################################"
echo "Notice the Average Load Time, Average Query Time, and Total Time."
echo "Next, explore the scripts from this demo to better understand how this demo"
echo "was implemented: $PWD"
echo "############################################################################"
