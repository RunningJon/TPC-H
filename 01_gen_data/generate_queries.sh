#!/bin/bash

PWD=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $PWD/../functions.sh
source_bashrc

set -e

query_id=1

echo "rm -f $PWD/../05_sql/*.tpch.*.sql"
rm -f $PWD/../05_sql/*.tpch.*.sql

cd $PWD/queries

for i in $(ls $PWD/*.sql |  xargs -n 1 basename); do
	q=$(echo $i | awk -F '.' '{print $1}')
	id=$(printf %02d $q)
	file_id="1""$id"
	filename=$file_id.tpch.$id.sql

	echo "echo \":EXPLAIN_ANALYZE\" > $PWD/../../05_sql/$filename"
	echo ":EXPLAIN_ANALYZE" > $PWD/../../05_sql/$filename
	echo "./qgen $q >> $PWD/../../05_sql/$filename"
	./qgen $q >> $PWD/../../05_sql/$filename
done

cd ..

