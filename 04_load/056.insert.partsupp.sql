INSERT INTO tpch.partsupp 
(ps_partkey, ps_suppkey, ps_availqty, ps_supplycost, ps_comment)
SELECT ps_partkey, ps_suppkey, ps_availqty, ps_supplycost, ps_comment 
FROM ext_tpch.partsupp;
