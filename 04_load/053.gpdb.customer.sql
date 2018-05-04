INSERT INTO tpch.customer
(c_custkey, c_name, c_address, c_nationkey, c_phone, c_acctbal, 
            c_mktsegment, c_comment)
SELECT c_custkey, c_name, c_address, c_nationkey, c_phone, c_acctbal, 
            c_mktsegment, c_comment
FROM ext_tpch.customer;
