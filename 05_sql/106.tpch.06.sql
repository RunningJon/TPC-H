:EXPLAIN_ANALYZE
-- using 1490193659 as a seed to the RNG


select
	sum(l_extendedprice * l_discount) as revenue
from
	lineitem
where
	l_shipdate >= date '1996-01-01'
	and l_shipdate < date '1996-01-01' + interval '1 year'
	and l_discount between 0.05 - 0.01 and 0.05 + 0.01
	and l_quantity < 25;
