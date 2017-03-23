########################################################################################
TPC-H benchmark scripts for HAWQ and Greenplum database.
########################################################################################

########################################################################################
TPC-H Information
########################################################################################
Based on version 2.17.1 of TPC-H.

########################################################################################
Query Options
########################################################################################
- Initial version only supports the standard, TPC-H queries.
SQL_VERSION="tpch"

You can have the queries execute with "EXPLAIN ANALYZE" in order to see exactly the 
query plan used, the cost, the memory used, etc.  This is done in tpch_variables.sh
like this:
EXPLAIN_ANALYZE="true"

Note: The EXPLAIN ANALYZE option is only available when using the standard TPC-H 
queries.

########################################################################################
Storage Options
########################################################################################
Table storage is defined in functions.sh and is configured for optimal performance. 

########################################################################################
Prerequisites
########################################################################################
1. Greenplum Database or Pivotal HDB (Apache HAWQ) installed and running
2. Connectivity is possible to the MASTER_HOST and from the Data Nodes / Segment Hosts
3. Root access

########################################################################################
Installation
########################################################################################
1. ssh to the master host with root
ssh root@mdw

2. Download the tpch.sh file
curl https://raw.githubusercontent.com/pivotalguru/TPC-H/master/tpch.sh > tpch.sh
chmod 755 tpch.sh

########################################################################################
Variables and Configuration
########################################################################################
By default, the installation will create the scripts in /pivotalguru/TPC-H on the 
Master host.  Variables can be changed by editing the dynamically configured 
/root/tpch_variables.sh file that is created the first time tpch.sh is run.  

Also by default, TPC-H files are generated on each Segment Host / Data Node in the 
Segement's PGDATA/pivotalguru directory.  If there isn't enough space in this directory
in each Segment, you can create a symbolic link to a drive location that does have 
enough space.

########################################################################################
HAWQ 2.x
########################################################################################
For HAWQ 2.x, this directory is named PGDATA/pivotalguru_$i where $i is 1 to 
the GUC hawq_rm_nvseg_perquery_perseg_limit.  See notes below for more information. 
Example creating links with PGDATA = /data1/segment
with gpssh as root:
for i in $(seq 1 8); do mkdir /data$i/pivotalguru; done
chown gpadmin:gpadmin /data*/pivotalguru
for i in $(seq 1 8); do ln -s /data$i/pivotalguru /data/hawq/segment/pivotalguru_$i; done

The above is only for HAWQ 2.0.  For GPDB and HAWQ 1.3, the segment directory structure
is different.

########################################################################################
Ambari installation
########################################################################################
If Ambari is used to manage the cluster, you will need to add the following changes to
"Custom hawq-site.xml":
optimizer_analyze_root_partition [on]
optimizer [on]

Change:
VM Overcommit Ratio [100]
Segment Memory Usage Limit [200] (based on the availability of RAM)
hawq_rm_stmt_vseg_memory [16gb] (based on the availability of RAM)
gp_autostats_mode [none]

Refer to Pivotal HDB documentation on how to set the Segment Memory Usage, VM Overcommit
Ratio, and Statement Memory settings.

########################################################################################
Execution
########################################################################################
1. Execute tpch.sh
./tpch.sh

########################################################################################
Notes
########################################################################################
- tpch_variables.sh file will be created with variables you can adjust
- Files for the benchmark will be created in a sub-directory named pivotalguru located 
in each segment directory on each segment host / data node.
You can update these directories to be symbolic links to better utilize the disk 
volumes you have available.
- Example of running tpch as root as a background process:
nohup ./tpch.sh > tpch.log 2>&1 < tpch.log &

########################################################################################
TPC-H Minor Modifications
########################################################################################
1. Query alternative 15 was used in favor of the original so it is easier to parse in
these scripts.  Performance is essentially the same for both versions.
2. Query 1 documentation doesn't match query provided by TPC.  Range is supposed to be
dynamically set between 60 and 120 days and substitution doesn't seem to be working
with qgen.  So, hard code 90 days until this can be fixed by TPC.

