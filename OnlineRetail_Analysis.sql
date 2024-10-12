--● What are the top 10 products by revenue? 
SELECT StockCode, Description, SUM(TotalPrice) AS TotalRevenue
FROM `custom-blade-407700.online_retail.online-retail-cleaned` OnlineRetail
WHERE StockCode NOT IN ('DOT','M','POST') --Removing the non-product records (Transational Category)
GROUP BY StockCode, Description
ORDER BY TotalRevenue DESC
LIMIT 10




--● What is the average order value (AOV) per country? 
----Method 1 (with CTE):
WITH OrderValue AS (
  SELECT 
    InvoiceNo,
    ROUND(SUM(TotalPrice), 2) AS OrderValue
  FROM `custom-blade-407700.online_retail.online-retail-cleaned` OnlineRetail
  GROUP BY InvoiceNo
)

SELECT 
  Country, AVG(Distinct OrderValue.OrderValue) AS AOV
FROM `custom-blade-407700.online_retail.online-retail-cleaned` OnlineRetail
  LEFT JOIN OrderValue ON OnlineRetail.InvoiceNo = OrderValue.InvoiceNo
GROUP BY Country
ORDER BY AOV DESC

--Method 2 (without CTE):
SELECT 
  Country, 
  ROUND(SUM(TotalPrice)/COUNT(DISTINCT InvoiceNo), 2) AS AOV
FROM `custom-blade-407700.online_retail.online-retail-cleaned` OnlineRetail
GROUP BY Country
ORDER BY AOV DESC






--● Which countries have the highest customer lifetime value (CLTV)? 
--(Assume CLTV is simply total revenue per customer) 

SELECT 
  Country, 
  ROUND(SUM(TotalPrice)/COUNT(DISTINCT CustomerID), 2) AS CLTV
FROM `custom-blade-407700.online_retail.online-retail-cleaned` OnlineRetail
WHERE CustomerID NOT LIKE ('0%') --Excluding the dummy CustomerIDs
GROUP BY Country
ORDER BY CLTV DESC


--● What is the monthly trend of revenue over time? 
WITH MonthlyRevenue AS (
  SELECT
    DATE_TRUNC(InvoiceDate, MONTH) AS Month,
    SUM(TotalPrice) AS Revenue
  FROM
    `custom-blade-407700.online_retail.online-retail-cleaned` OnlineRetail
  GROUP BY Month
)

--● What is the monthly trend of revenue over time? (With Month-over-Month Change)

SELECT
  Month,
  Revenue,
  LAG(Revenue) OVER (ORDER BY month) AS LastMonthRevenue,
  ROUND((Revenue - LAG(Revenue) OVER (ORDER BY Month)) / LAG(Revenue) OVER (ORDER BY Month) * 100, 2) AS MonthlyRevenueChange
FROM
  MonthlyRevenue
ORDER BY
  Month

---* Seasonal Patterns:
WITH OrderValue AS (
  SELECT 
    InvoiceNo,
    ROUND(SUM(TotalPrice), 2) AS OrderValue
  FROM `custom-blade-407700.online_retail.online-retail-cleaned` OnlineRetail
  GROUP BY InvoiceNo
),

MonthlyData AS (
  SELECT
    EXTRACT(YEAR FROM InvoiceDate) AS Year,
    EXTRACT(MONTH FROM InvoiceDate) AS Month,
    SUM(TotalPrice) AS TotalSales,
    COUNT(DISTINCT OnlineRetail.InvoiceNo) AS TotalTransactions,
    AVG(DISTINCT OrderValue) AS AOV
  FROM `custom-blade-407700.online_retail.online-retail-cleaned` OnlineRetail
    LEFT JOIN OrderValue ov ON OnlineRetail.InvoiceNo = ov.InvoiceNO
  GROUP BY Year, Month
),
YearlyAVG AS (
  SELECT
    Year,
    AVG(TotalSales) AS YearlyAvgSales,
    AVG(TotalTransactions) AS YearlyAvgTransactions,
    AVG(AOV) AS YearlyAOV
  FROM MonthlyData
  GROUP BY Year
)

SELECT
  md.Year,
  md.Month,
  md.TotalSales,
  ya.YearlyAvgSales,
  ROUND((md.TotalSales - ya.YearlyAvgSales) / ya.YearlyAvgSales * 100, 2) AS SalesPercentageDeviation,
  md.TotalTransactions AS TotalMonthlyTransactions,
  (ya.YearlyAvgTransactions) AS AverageMonthlyTransactions,
  ROUND((md.TotalTransactions - ya.YearlyAvgTransactions) / ya.YearlyAvgTransactions * 100, 2) AS TransactionsPercentageDeviation,
  ROUND(md.AOV, 2) AS MonthlyAverageOrderValue,
  ROUND(ya.YearlyAOV, 2) AS YearlyAverageOrderValue,
  ROUND((md.AOV - ya.YearlyAOV) / ya.YearlyAOV * 100, 2) AS AOVPercentageDeviation
FROM MonthlyData md
JOIN YearlyAVG ya ON md.Year = ya.Year
ORDER BY md.Year, md.Month

--- 2: 
SELECT 
  EXTRACT(YEAR FROM InvoiceDate) AS Year,
  EXTRACT(MONTH FROM InvoiceDate) AS Month,
  ROUND(SUM(TotalPrice)/COUNT(DISTINCT InvoiceNo), 2) AS AOV,
  COUNT(DISTINCT InvoiceNo) AS NumberOfOrders,
  ROUND(SUM(TotalPrice), 2) AS TotalRevenue
FROM `custom-blade-407700.online_retail.online-retail-cleaned` OnlineRetail
GROUP BY Year, Month
ORDER BY Year, Month


---------------------------------------------------------------------------------------------------- Extra Analysis ----------------------------------------------------------------------------------------------------

--● What are the total sales by day of the week?

SELECT 
  FORMAT_DATE('%A', InvoiceDate) AS DayOfWeek,
  ROUND(SUM(TotalPrice), 2) AS TotalSales
FROM `custom-blade-407700.online_retail.online-retail-cleaned` OnlineRetail
GROUP BY DayOfWeek
ORDER BY 
  CASE DayOfWeek
    WHEN 'Monday' THEN 1
    WHEN 'Tuesday' THEN 2
    WHEN 'Wednesday' THEN 3
    WHEN 'Thursday' THEN 4
    WHEN 'Friday' THEN 5
    WHEN 'Saturday' THEN 6
    WHEN 'Sunday' THEN 7
  END



