INSERT INTO tpch.region 
(r_regionkey, r_name, r_comment)
SELECT r_regionkey, r_name, r_comment 
FROM ext_tpch.region;
