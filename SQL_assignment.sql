-- Problem 1

-- steps-
-- 1- found all the customers with max_amount who opted to (pick up, ordered) in 2018 and using 'DOTCOM' CHANNEL 
-- 2- flagged customers with max amount <= $35
-- 3- aggregated to get count and percentage of customers never placed a pick up order of over $35


SELECT SUM(AMOUNT_FLAG) AS COUNT_NEVER_OVER_35, SUM(AMOUNT_FLAG)/COUNT(AMOUNT_FLAG) AS PERC_NEVER_OVER_35
FROM 
(
	SELECT UGC_ID, 
		   CASE WHEN MAX_AMOUNT <= 35 THEN 1 ELSE 0 END AS AMOUNT_FLAG
	FROM (
		SELECT UGC_ID, MAX(AMOUNT) AS MAX_AMOUNT
		  FROM TRANSACTIONS
		 WHERE CAST(visit_date AS DATE) BETWEEN '2018-01-01' AND '2018-12-31'
		   AND CHANNEL = 'DOTCOM'
		   AND SERVICE_ID IN (8, 11)
		GROUP BY UGC_ID
		  ) AS B
) AS C;
-- -------------------------------------------------------------------------------------------------------------   
-- Problem 2
-- steps-
-- 1- I calculated monthly revenue based on channel for every month in 2017
-- 2- Used the window function to get cumulative revenue channel wise for each month

SELECT CHANNEL, CURRENT_MONTH, SUM(AMOUNT_SUM) OVER(PARTITION BY CHANNEL ORDER BY CURRENT_MONTH) AS Cumulative_revenue
FROM (
	SELECT CHANNEL, MONTH(CAST(visit_date AS DATE)) AS CURRENT_MONTH, SUM(AMOUNT) AS AMOUNT_SUM
	  FROM TRANSACTIONS
	 WHERE CAST(visit_date AS DATE) BETWEEN '2017-01-01' AND '2017-12-31'
	 AND CHANNEL IN ('DOTCOM', 'OG')
	GROUP BY CHANNEL, MONTH(CAST(visit_date AS DATE))
	) AS B
GROUP BY CHANNEL, CURRENT_MONTH

-- -----------------------------------------------------------------------------------------------------------
-- Problem 3

-- I am creating the structure as follows. 
-- Q1-Q2 will give me the percentage of shopppers who shopped in Q1 shopped again in Q2.
-- Q2-Q4 will give me the percentage of shopppers who shopped in Q2 shopped again in Q4.
-- All of the rest follows the same pattern for every year.

-- YEAR QUARTER   Q+1      Q+2      Q+3
-- 2018    1     Q1-Q2    Q1-Q3    Q1-Q4	
-- 2018    2     Q2-Q3    Q2-Q4
-- 2018    3     Q3-Q4
-- 2018    4

-- steps-
-- 1- I create a CTE "TRANSACTIONS_2". This table contains shopper which shopped in particular quarter of a year
-- 2- Used the above created table and lagged for each quarters to get data for next quarters for same shopper, which gives the above structure
-- 3- aggregated data on 'QUARTER' and got percentage of customers repeated in next quarter

WITH TRANSACTIONS_2 AS 
(
SELECT UGC_ID, YEAR(CAST(visit_date AS DATE)) AS CURRENT_YEAR, QUARTER
FROM (
	SELECT UGC_ID,
	CASE 
	WHEN MONTH(CAST(visit_date AS DATE)) BETWEEN 4 AND 6 THEN 1
	WHEN MONTH(CAST(visit_date AS DATE)) BETWEEN 7 AND 9 THEN 2
	WHEN MONTH(CAST(visit_date AS DATE)) BETWEEN 10 AND 12 THEN 3
	WHEN MONTH(CAST(visit_date AS DATE)) BETWEEN 1 AND 3 THEN 4
	END AS QUARTER
	FROM TRANSACTIONS
	) AS B
GROUP BY UGC_ID, CURRENT_YEAR, QUARTER
)

SELECT CURRENT_YEAR,QUARTER,
       COUNT(QUARTER_PLUS_1)/COUNT(QUARTER),
       COUNT(QUARTER_PLUS_2)/COUNT(QUARTER),
	   COUNT(QUARTER_PLUS_3)/COUNT(QUARTER)
FROM (
	SELECT *, 
	LEAD(QUARTER, 1) OVER(PARTITION BY UGC_ID, CURRENT_YEAR ORDER BY QUARTER) AS QUARTER_PLUS_1,
	LEAD(QUARTER, 2) OVER(PARTITION BY UGC_ID, CURRENT_YEAR ORDER BY QUARTER) AS QUARTER_PLUS_2,
	LEAD(QUARTER, 3) OVER(PARTITION BY UGC_ID, CURRENT_YEAR ORDER BY QUARTER) AS QUARTER_PLUS_3
	FROM TRANSACTIONS_2
	) AS C
GROUP BY CURRENT_YEAR, QUARTER;

