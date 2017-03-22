#!/bin/bash
set -e

PWD=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $PWD/../functions.sh
source_bashrc

step=compile_tpch
init_log $step
start_log
schema_name="tpch"
table_name="compile"

make_tpc()
{
	#compile dbgen
	cd $PWD/dbgen
	rm -f *.o
	make
	cd ..
}
copy_queries()
{
	rm -rf $PWD/../*_gen_data/queries
	rm -rf $PWD/../*_multi_user/queries
	cp -R dbgen/queries $PWD/../*_gen_data/
	cp -R dbgen/queries $PWD/../*_multi_user/
}
copy_tpc()
{
	cp $PWD/dbgen/qgen ../*_gen_data/queries/
	cp $PWD/dbgen/dists.dss ../*_gen_data/queries/
	cp $PWD/dbgen/qgen ../*_multi_user/queries/
	cp $PWD/dbgen/dists.dss ../*_multi_user/queries/

	#copy the compiled dbgen program to the segment hosts
	for i in $(cat $PWD/../segment_hosts.txt); do
		echo "copy tpch binaries to $i:$ADMIN_HOME"
		scp dbgen/dbgen dbgen/dists.dss $i:$ADMIN_HOME/
	done
}

make_tpc
create_hosts_file
copy_queries
copy_tpc
log

end_step $step
