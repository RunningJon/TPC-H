INSERT INTO tpch.nation 
(n_nationkey, n_name, n_regionkey, n_comment)
SELECT n_nationkey, n_name, n_regionkey, n_comment
FROM ext_tpch.nation;
