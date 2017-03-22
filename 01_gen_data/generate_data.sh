#!/bin/bash
set -e

PWD=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

GEN_DATA_SCALE=$1
CHILD=$2
PARALLEL=$3
GEN_DATA_PATH=$4
SINGLE_SEGMENT="0"
DATA_DIRECTORY="$GEN_DATA_PATH"

if [[ "$GEN_DATA_SCALE" == "" || "$CHILD" == "" || "$PARALLEL" == "" || "$GEN_DATA_PATH" == "" ]]; then
        echo "You must the scale, child, parallel, and gen_data_path."
        echo "Example: ./rollout.sh 100 1 8 /data1/primary/gpseg0/pivotalguru/"
        exit 1
fi

if [[ ! -d "$DATA_DIRECTORY" && ! -L "$DATA_DIRECTORY" ]]; then
	mkdir $DATA_DIRECTORY
fi

rm -f $DATA_DIRECTORY/*

export DSS_PATH=$DATA_DIRECTORY

#for single nodes, you might only have a single segment but dbgen requires at least 2
if [ "$PARALLEL" -eq "1" ]; then
	PARALLEL="2"
	SINGLE_SEGMENT="1"
fi

cd $PWD
$PWD/dbgen -s $GEN_DATA_SCALE -C $PARALLEL -S $CHILD -v
if [ "$CHILD" -gt "1" ]; then
	rm -f $DATA_DIRECTORY/nation.tbl
	rm -f $DATA_DIRECTORY/region.tbl
	touch $DATA_DIRECTORY/nation.tbl
	touch $DATA_DIRECTORY/region.tbl
fi

#for single nodes, you might only have a single segment but dbgen requires at least 2
if [ "$SINGLE_SEGMENT" -eq "1" ]; then
	CHILD="2"
	#build the second list of files
	$PWD/dbgen -s $GEN_DATA_SCALE -C $PARALLEL -S $CHILD -f -v
fi
