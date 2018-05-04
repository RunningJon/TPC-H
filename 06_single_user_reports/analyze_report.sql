SELECT description, extract('epoch' from duration) AS seconds 
FROM tpch_reports.load 
WHERE tuples = 0
ORDER BY 1;
