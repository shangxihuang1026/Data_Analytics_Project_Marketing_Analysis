-- 1. Dimension Tables
-- Product Table
SELECT
ProductID,
ProductName,
Price,
CASE WHEN Price < 50 THEN 'LOW'
	 WHEN Price BETWEEN 50 AND 200 THEN 'Medium'
	 ELSE 'High'
END as PriceCategory
FROM dbo.products;


-- Customer & Geography Tables
SELECT
c.CustomerID,
c.CustomerName,
c.Email,
c.Gender,
c.Age,
CASE WHEN Age < 25 THEN 'Below 25'
	 WHEN Age BETWEEN 25 AND 40 THEN '25-40'
	 WHEN AGE BETWEEN 40 AND 55 THEN '40-55'
	 ELSE 'Above 55'
END as AgeGroup,
g.Country,
g.City
FROM dbo.customers c
LEFT JOIN dbo.geography g
ON c.GeographyID = g.GeographyID;


-- 2. Fact Tables

-- customer_review: Fix whitespace issures in the ReviewText
SELECT
ReviewID,
CustomerID,
ProductID,
ReviewDate,
Rating,
REPLACE(ReviewText,'  ',' ') as ReviewText
FROM dbo.customer_reviews

-- engagement_data
SELECT
EngagementID,
ContentID,
UPPER(REPLACE(ContentType,'socialmedia','Social Media')) as ContentType,
Likes,
FORMAT(CONVERT(DATE,EngagementDate),'MM/dd/yyyy') as EngagementDate,
CampaignID,
ProductID,
LEFT(ViewsClicksCombined,CHARINDEX('-',ViewsClicksCombined)-1) as Views, -- Extract Views information
RIGHT(ViewsClicksCombined, LEN(ViewsClicksCombined)-CHARINDEX('-',ViewsClicksCombined)) as Clicks -- Extract Clicks information
FROM dbo.engagement_data
WHERE ContentType != 'newsletter';




-- customer_journey
WITH cleaned_customer_journey AS(
SELECT
JourneyID,
CustomerID,
ProductID,
VisitDate,
REPLACE(REPLACE(REPLACE(Stage, 'checkout', 'Checkout'), 'homepage', 'Homepage'),'productpage', 'ProductPage') as Stage,
Action,
Duration,
ROW_NUMBER() OVER(PARTITION BY JourneyID, CustomerID, ProductID, VisitDate, Stage, Action ORDER BY Duration) as duplicates, -- count duplicates
ROUND(AVG(Duration) OVER(PARTITION BY VisitDate),2) as avg_day_duration
FROM dbo.customer_journey)

SELECT
JourneyID,
CustomerID,
ProductID,
VisitDate,
Stage,
Action,
COALESCE(Duration, avg_day_duration) as Duration -- replace NULL values with the average duration of the corresponding VisitDate
FROM cleaned_customer_journey
WHERE duplicates = 1


SELECT
ProductID,
Stage,
Action,
COUNT(Duration) as ActionTimes
FROM dbo.customer_journey
GROUP BY ProductID,
Stage,
Action
ORDER BY ProductID,
Stage,
Action



