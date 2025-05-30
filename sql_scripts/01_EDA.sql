/* Exploratory Data Analysis*/

-- Database Exploration
SELECT * FROM INFORMATION_SCHEMA.TABLES;

SELECT * FROM INFORMATION_SCHEMA.COLUMNS;

-- Dimensions Exploration

-- 1. Customers & Geography data
SELECT
MAX(Age) as oldest_customer,
MIN(Age) as youngest_customer
FROM dbo.customers;

SELECT
Gender,
COUNT(CustomerID) as total_customers
FROM dbo.customers
GROUP BY Gender;

SELECT
g.GeographyID,
g.Country,
g.City,
COUNT(c.CustomerID) as total_customers,
CONCAT(CAST(COUNT(c.CustomerID) as FLOAT)/(SELECT COUNT(CustomerID) FROM dbo.customers) *100,'%') as customer_percentage
FROM dbo.geography g
LEFT JOIN dbo.customers c
ON g.GeographyID = c.GeographyID
GROUP BY g.GeographyID,
g.Country,
g.City
ORDER BY total_customers DESC;


-- 2. Product Data
SELECT
MIN(Price) as min_price,
MAX(Price) as max_price
FROM dbo.products;

WITH price_cat AS(
SELECT
*,
CASE WHEN Price < 50 THEN 'Low'
	 WHEN Price BETWEEN 50 AND 200 THEN 'Medium'
	 ELSE 'High'
END as PriceCategory
FROM dbo.products)

SELECT 
PriceCategory,
COUNT(ProductID) as total_products
FROM price_cat
GROUP BY PriceCategory
ORDER BY total_products;



-- Measures Exploration
-- 1. Customer Journey
SELECT
DISTINCT Stage,
Action
FROM dbo.customer_journey
ORDER BY Stage;


SELECT
ProductID,
Stage,
Action,
ROUND(AVG(Duration),2) as avg_duaration
FROM dbo.customer_journey
GROUP BY ProductID, Stage, Action
ORDER BY ProductID, Stage, Action;


SELECT
ProductID,
Stage,
Action,
COUNT(JourneyID) as journey_count
FROM dbo.customer_journey
GROUP BY ProductID, Stage, Action
ORDER BY ProductID, Stage, Action;





