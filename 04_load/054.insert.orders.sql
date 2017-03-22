INSERT INTO tpch.orders 
(o_orderkey, o_custkey, o_orderstatus, o_totalprice, o_orderdate, 
            o_orderpriority, o_clerk, o_shippriority, o_comment)
SELECT o_orderkey, o_custkey, o_orderstatus, o_totalprice, o_orderdate, 
            o_orderpriority, o_clerk, o_shippriority, o_comment 
FROM ext_tpch.orders;
