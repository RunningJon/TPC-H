#!/bin/bash
set -e

PWD=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $PWD/../functions.sh
source_bashrc
step="multi_user_reports"

init_log $step

get_version
if [[ "$VERSION" == *"gpdb"* ]]; then
	filter="gpdb"
elif [ "$VERSION" == "postgresql" ]; then
	filter="postgresql"
else
	echo "ERROR: Unsupported VERSION!"
	exit 1
fi

for i in $(ls $PWD/*.$filter.*.sql); do
	echo "psql -a -f $i"
	psql -a -f $i
	echo ""
done

for i in $(ls $PWD/*.copy.*.sql); do
	logstep=$(echo $i | awk -F 'copy.' '{print $2}' | awk -F '.' '{print $1}')
	logfile="$PWD""/../log/rollout_""$logstep"".log"
	logfile="'""$logfile""'"
	echo "psql -a -f $i -v LOGFILE=\"$logfile\""
	psql -a -f $i -v LOGFILE="$logfile"
	echo ""
done

psql -t -A -c "select 'analyze ' || n.nspname || '.' || c.relname || ';' from pg_class c join pg_namespace n on n.oid = c.relnamespace and n.nspname = 'tpch_testing'" | psql -t -A -e

psql -F $'\t' -A -P pager=off -f $PWD/detailed_report.sql
echo ""

end_step $step
