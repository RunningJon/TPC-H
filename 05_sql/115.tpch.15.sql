:EXPLAIN_ANALYZE
-- using 1490193659 as a seed to the RNG

with revenue (supplier_no, total_revenue) as (
		select
			l_suppkey,
			sum(l_extendedprice * (1-l_discount))
		from
			lineitem
		where
			l_shipdate >= date '1994-05-01'
			and l_shipdate < date '1994-05-01' + interval '3 months'
		group by
			l_suppkey
)


select
	s_suppkey,
	s_name,
	s_address,
	s_phone,
	total_revenue
from
	supplier,
	revenue
where
	s_suppkey = supplier_no
	and total_revenue = (
		select
			max(total_revenue)
		from
			revenue
	)
order by
	s_suppkey;
