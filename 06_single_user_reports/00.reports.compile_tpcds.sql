DROP SCHEMA IF EXISTS tpch_reports CASCADE;
CREATE SCHEMA tpch_reports;

CREATE EXTERNAL WEB TABLE tpch_reports.compile_tpch
(id int, description varchar, tuples bigint, duration time) 
EXECUTE :EXECUTE ON MASTER
FORMAT 'TEXT' (DELIMITER '|');
