CREATE DATABASE retail_analytics;
USE retail_analytics;
SHOW TABLES;

-- Alter Table & Column Name.

ALTER TABLE customer_profiles
rename to customers;

ALTER TABLE product_inventory
rename to product;

ALTER TABLE sales_transaction
rename to sales;

SELECT * FROM customers;
DESC customers;

SELECT * FROM product;
DESC product;

SELECT * FROM sales;
DESC sales;

SELECT COUNT(*) From Product;
SELECT COUNT(*) From Customers;
SELECT COUNT(*) From sales;

-- ï»¿CustomerID -> CustomerID
-- ï»¿ProductID -> ProductID
-- ï»¿TransactionID -> TransactionID

ALTER TABLE Customers
RENAME COLUMN ï»¿CustomerID TO CustomerID;

ALTER TABLE Product
RENAME COLUMN ï»¿ProductID TO ProductID;

ALTER TABLE sales
RENAME COLUMN ï»¿TransactionID TO TransactionID;

-- Checking Null and Blank Values.

SELECT * FROM customers WHERE CustomerID IS NULL;
SELECT * FROM product WHERE ProductID IS NULL;
SELECT * FROM sales WHERE TransactionID IS NULL;

--  Identify Missing Values in Location 
SELECT * FROM Customers;
SELECT * FROM Customers WHERE Location LIKE "";
SELECT COUNT(*) FROM Customers WHERE Location LIKE "";

UPDATE Customers 
SET Location = "Unknown"
WHERE Location LIKE "";

UPDATE Customers 
SET Location = "Unknown"
WHERE Location IS NULL;

-- Checking If any Duplicate values is there or not.

SELECT 
	CustomerID, 
    COUNT(*) 
FROM customers
GROUP BY CustomerID
HAVING COUNT(*) > 1;

SELECT 
	ProductID, 
    COUNT(*) 
FROM product
GROUP BY ProductID
HAVING COUNT(*) > 1;

SELECT 
	CustomerID, 
    COUNT(*) 
FROM customers
GROUP BY CustomerID
HAVING COUNT(*) > 1;

--  Seperating Table according to Unique Values. 
SELECT 
	TransactionID,
    COUNT(*)
FROM sales
GROUP BY TransactionID
HAVING COUNT(*) > 1;

CREATE TABLE sales_unique AS 
SELECT DISTINCT * FROM sales;

DROP TABLE sales;
ALTER TABLE sales_unique RENAME TO sales;

-- Q.1. Finding Out Any Discrepancies in the price?
SELECT * FROM sales;
SELECT * FROM product;

SELECT
	TransactionID,
    s.Price AS TransactionPrice,
    p.Price AS InventoryPrice
FROM sales s
JOIN product p
ON s.ProductID = p.ProductID
WHERE p.price <> s.price;

-- UPDATE Price of ProductID - 51
-- UPDATE sales
-- SET Price = 93.12
-- WHERE ProductID = 51; IN (51,2,343,54,12,42,644,334)

SET SQL_SAFE_UPDATES = 0;
UPDATE sales s
SET Price = (
	SELECT p.price FROM product p 
    WHERE s.ProductID = p.ProductID 
)
WHERE s.ProductID IN (
	SELECT ProductID FROM product p
    WHERE p.price <> s.price
);

-- Q.2. Changing Data Type of the date column in a seperate column.

CREATE TABLE sales_updates AS 
SELECT 
	* , 
    STR_TO_DATE(TransactionDate , '%d-%m-%Y') AS TransactionDate_updated
FROM sales; 

SELECT * FROM sales_updates;

DROP TABLE sales;

ALTER TABLE sales_updates RENAME TO sales;
SELECT * FROM sales;

-- Q.3. Total Customers?

SELECT COUNT(DISTINCT CustomerID)
FROM sales;

-- Q.4: Finding Out Total Revenue ?
SELECT 
	ProductID,
    SUM(QuantityPurchased * Price) AS TotalRevenue
FROM sales
GROUP BY ProductID
ORDER BY TotalRevenue DESC 
LIMIT 10;


-- Q.5: Top performing Product by Per unit?
SELECT
	ProductID,
    SUM(QuantityPurchased) AS TotalUnitsSold,
    SUM(QuantityPurchased * Price) AS TotalSales
FROM sales
GROUP BY ProductID
ORDER BY TotalSales DESC;

-- Q.6: Number Of Transaction by Per Customer?
SELECT
	CustomerID,
    COUNT(*) AS NumberOfTransactions
FROM sales
GROUP BY CustomerID
ORDER BY NumberOfTransactions DESC;

-- Q.7: Which Categories generate Highest Sales ?
SELECT * FROM sales;
SELECT * FROM product;

SELECT 
	p.Category,
    SUM(s.QuantityPurchased) AS TotalUnitsSold,
    SUM(s.QuantityPurchased * s.Price) AS TotalSales
FROM sales s
JOIN product p
ON s.ProductID = p.ProductID
GROUP BY Category
ORDER BY TotalSales DESC;

-- Q.8: List top 10 Products by Least amount of Unit Sold ?
SELECT * FROM sales;
SELECT
	ProductID,
    SUM(QuantityPurchased) AS TotalUnitsSold
FROM sales
GROUP BY ProductID
HAVING TotalUnitsSold > 0
ORDER BY TotalUnitsSold
LIMIT 10;

-- Q.9: Identiying Sales trend to get to know revenue pattern of the company?
SELECT * FROM sales;

SELECT 
	TransactionDate_updated AS DATETRANS,
    COUNT(*) AS Transaction_count,
    SUM(QuantityPurchased) AS TotalUnitsSold,
    SUM(QuantityPurchased * Price) AS TotalSales
FROM sales
GROUP BY DATETRANS
ORDER BY DATETRANS DESC;

-- Q.10: Month Over Month Growth Rate of Sales?
Select * FROM sales;

WITH MonthSales AS (
	SELECT
		EXTRACT(MONTH FROM TransactionDate_updated) AS month,
		ROUND(SUM(QuantityPurchased * Price),2) AS total_sales
	FROM sales
    GROUP BY EXTRACT(MONTH FROM TransactionDate_updated)
)
SELECT
	month,
    total_sales,
    LAG(total_sales) OVER (ORDER BY month) AS previous_month_sales,
    ROUND(((total_sales - LAG(total_sales) OVER (ORDER BY month)) / 
    LAG(total_sales) OVER (ORDER BY month)) * 100,2) AS mom_growth_percentage
FROM MonthSales
ORDER BY month;

-- Q.11: Which Customer are high value Customers [High Purchase Frequency]?
SELECT * FROM sales;

SELECT 
	CustomerID,
    COUNT(*) AS  NumberOfTransactions,
    SUM(QuantityPurchased * Price) AS TotalSpent
FROM sales 
GROUP BY CustomerID
HAVING NumberOfTransactions > 10 AND TotalSpent > 1000
ORDER BY TotalSpent DESC;

-- Q.12: Which Customers have very few Purchases or Occasional Customers [Low Purchase Frequency]?

SELECT 
	CustomerID,
    COUNT(*) AS  NumberOfTransactions,
    SUM(QuantityPurchased * Price) AS TotalSpent
FROM sales 
GROUP BY CustomerID
HAVING NumberOfTransactions <= 2
ORDER BY NumberOfTransactions ASC, TotalSpent DESC;

-- Q.13: Using a Sales Table find out number of times each customer has purchased each product or Find Repeated Customer?
SELECT * FROM sales;

SELECT 
	CustomerID,
    ProductID,
    COUNT(*) AS TimesPurchased
FROM sales
GROUP BY CustomerID, ProductID
HAVING TimesPurchased > 1
ORDER BY TimesPurchased DESC;

-- Q.14 : Finding Loyal Indicator.

SELECT * FROM sales;

WITH transanctionDate AS (
	SELECT
		CustomerID,
        STR_TO_DATE(TransactionDate, '%d-%m-%Y') AS TransactionDate
	FROM sales
)
SELECT
	CustomerID,
    MIN(TransactionDate) AS FirstPurchase,
    MAX(TransactionDate) AS LastPurchase,
    DATEDIFF(MAX(TransactionDate),MIN(TransactionDate)) AS DaysBetweenPurchases
FROM transanctionDate
GROUP BY CustomerID
HAVING DaysBetweenPurchases > 0
ORDER BY DaysBetweenPurchases DESC;

-- Q.15: Finding Customer Segmentation by Quantity

SELECT * FROM customers;
SELECT * FROM sales;

CREATE TABLE customer_segment AS
	SELECT 
		CustomerID,
		CASE
			WHEN TotalQuantity BETWEEN 1 AND 10 THEN 'Low'
			WHEN TotalQuantity BETWEEN 11 AND 30 THEN 'Med'
			WHEN TotalQuantity > 30 THEN 'High'
            ELSE 'None'
		END AS CustomerSegment
	FROM (
		SELECT
			c.CustomerID,
            SUM(s.QuantityPurchased) AS TotalQuantity
		FROM Customers c
        JOIN sales s
        ON c.CustomerID = s.CustomerID
        GROUP BY CustomerID
    ) AS customer_totals;
    
SELECT * FROM customer_segment;

SELECT 
	CustomerSegment,
	COUNT(*)
FROM customer_segment
GROUP BY CustomerSegment;

-- Q.16. Sales By Month?
SELECT
	EXTRACT(MONTH FROM TransactionDate_updated) AS month,
	ROUND(SUM(QuantityPurchased * Price),2) AS total_sales
	FROM sales
	GROUP BY month
	ORDER BY month;
    
-- Q.17: Revenue by customer Location?
SELECT 
  c.Location,
  SUM(QuantityPurchased * Price) AS TotalRevenue
FROM sales s
JOIN customers c
ON s.CustomerID = c.CustomerID
GROUP BY c.Location;

-- Q.18. Ranking products by sales?
SELECT 
  p.ProductName,
  p.Category,
  SUM(s.QuantityPurchased * s.Price) AS TotalRevenue,
  RANK() OVER(ORDER BY SUM(s.QuantityPurchased * s.Price) DESC) AS rank_no
FROM sales s
JOIN product p
ON s.ProductID = p.ProductID
GROUP BY p.ProductName,p.Category;

