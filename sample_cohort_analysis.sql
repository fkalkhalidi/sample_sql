with mau AS
  (SELECT date(actual_delivery_time) AS dt,
          date_trunc('month', actual_delivery_time) AS month,
          consumer.id AS consumer_id
   FROM consumer
   JOIN order_cart ON consumer.id = order_cart.creator.id
   JOIN delivery ON delivery.id = order_cart.delivery_id
   GROUP BY 1,2,3),
first_dt AS
  (SELECT consumer_id,
          min(actual_delivery_time) AS first_dt,
          date_trunc('month', min(dt)) AS first_month
   FROM mau
   GROUP BY 1),
mau_consolidated AS
(SELECT d.month,
        d.consumer_id,
 		f.first_month
 FROM mau d
 JOIN first_dt f ON d.consumer_id = f.consumer_id),
cohorts_monthly AS
(SELECT first_month,
 		month as active_month,
 		extract(month from month) - extract(month from first_month)
                + 12*(extract(year from month) - extract(year from first_month)) as months_since_first,
            count(distinct consumer_id) as users,
 FROM mau_consolidated
 GROUP BY 1,2,3
 ORDER BY 1,2),
cohort_sizes AS
(SELECT first_month,
 		users,
 FROM cohorts_monthly
 WHERE months_since_first = 0)


SELECT cohorts_monthly.first_month,
	   cohorts_monthly.months_since_first,
	   ROUND((cohorts_monthly.users) / (cohort_sizes.users)::float * 100) as retention
FROM cohorts_monthly cm
JOIN cohort_sizes cs ON cm.first_month = cs.first_month
