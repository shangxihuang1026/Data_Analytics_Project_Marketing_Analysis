/* Conversion Analysis*/

-- Base query that joins customers, products, geography tables to customer_journey table
CREATE VIEW base_query AS
SELECT
j.JourneyID,
j.CustomerID,
c.CustomerName,
c.Gender,
c.Age,
CASE WHEN c.Age < 25 THEN 'Below 25'
	 WHEN c.Age BETWEEN 25 AND 35 THEN '25 to 35'
	 WHEN c.Age BETWEEN 35 AND 50 THEN '35 to 50'
	 ELSE 'Above 50'
END AS AgeGroup,
g.Country,
g.City,
j.ProductID,
p.ProductName,
j.VisitDate,
YEAR(j.VisitDate) AS VisitYear,
MONTH(j.VisitDate) AS VisitMonth,
j.Stage,
j.Action,
j.Duration
FROM dbo.customer_journey j
LEFT JOIN dbo.customers c
ON j.CustomerID = c.CustomerID
LEFT JOIN dbo.geography g
ON c.GeographyID = g.GeographyID
LEFT JOIN dbo.products p
ON j.ProductID = p.ProductID;

SELECT
*
FROM dbo.base_query

-- Base Query (customer)
-- DROP VIEW base_conversion_customer;
CREATE VIEW base_conversion_customer AS
WITH basics AS(
SELECT
CustomerID,
CustomerName,
Gender,
Age,
AgeGroup,
Country,
City,
SUM(CASE WHEN Action = 'View' OR Action = 'Click' THEN 1 ELSE 0 END) AS total_views_clicks,
SUM(CASE WHEN Action = 'Purchase' THEN 1 ELSE 0 END) AS total_purchases
FROM dbo.base_query
GROUP BY
CustomerID,
CustomerName,
Gender,
Age,
AgeGroup,
Country,
City)

SELECT
*,
ROUND((CAST(total_purchases AS FLOAT)/total_views_clicks),4) AS conversion_rate
FROM basics;



-- Base Query (product)
-- DROP VIEW base_conversion_product;
CREATE VIEW base_conversion_product AS
WITH basics AS(
SELECT
ProductID,
ProductName,
VisitYear,
SUM(CASE WHEN Action = 'View' OR Action = 'Click' THEN 1 ELSE 0 END) AS total_views_clicks,
SUM(CASE WHEN Action = 'Purchase' THEN 1 ELSE 0 END) AS total_purchases
FROM dbo.base_query
GROUP BY ProductID,
ProductName,
VisitYear)

SELECT
*,
ROUND((CAST(total_purchases AS FLOAT)/NULLIF(total_views_clicks,0)),4) AS conversion_rate
FROM basics;






-- Average Conversion Rate by Customer Gender
SELECT
Gender,
ROUND(AVG(conversion_rate),4) AS avg_conv_rate
FROM base_conversion_customer
GROUP BY Gender

-- Average Conversion Rate by Customer Age Group
SELECT
AgeGroup,
ROUND(AVG(conversion_rate),4) AS avg_conv_rate
FROM base_conversion_customer
GROUP BY AgeGroup
ORDER BY avg_conv_rate DESC

-- Average Conversion Rate by Country
SELECT
Country,
ROUND(AVG(conversion_rate),4) AS avg_conv_rate
FROM base_conversion_customer
GROUP BY Country
ORDER BY avg_conv_rate DESC;


-- Yearly Conversion Rate by Product 
SELECT
*,
CASE WHEN conversion_rate < LAG(conversion_rate,1) OVER(PARTITION BY ProductID ORDER BY VisitYear) THEN 'Decrease'
	 WHEN conversion_rate > LAG(conversion_rate,1) OVER(PARTITION BY ProductID ORDER BY VisitYear) THEN 'Increase'
	 WHEN LAG(conversion_rate,1) OVER(PARTITION BY ProductID ORDER BY VisitYear) IS NULL THEN '-'
	 ELSE 'Unchanged'
END AS conv_change
FROM base_conversion_product;


