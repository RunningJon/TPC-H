INSERT INTO tpch.part
(p_partkey, p_name, p_mfgr, p_brand, p_type, p_size, p_container, 
            p_retailprice, p_comment)
SELECT p_partkey, p_name, p_mfgr, p_brand, p_type, p_size, p_container, 
            p_retailprice, p_comment 
FROM ext_tpch.part;
