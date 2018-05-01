CREATE TABLE tpch_reports.init
(id int, description varchar, tuples bigint, duration time) 
DISTRIBUTED BY (id);
