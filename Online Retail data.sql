-- This file Contains the Stored Procedure/Functions/views for Online Retail data -------

----For Finding Avg Days between order by Customer -------
CREATE PROCEDURE `Avg_Days_btw_order`()
BEGIN
SELECT CustomerID, ROUND(AVG(DATEDIFF(NextOrderDate, InvoiceDate))) AS AvgDaysBetweenReorders,Country
FROM (
    SELECT CustomerID, InvoiceDate,
           LEAD(InvoiceDate) OVER (PARTITION BY CustomerID ORDER BY InvoiceDate) AS NextOrderDate,Country
    FROM `online retail`
) AS subquery
GROUP BY CustomerID,Country
having AvgDaysBetweenReorders>0
order by AvgDaysBetweenReorders desc;

END


----- Top 3 Selling Products -------------

CREATE PROCEDURE `Top3sellingproducts2011`()
Begin


 with Top3 as (SELECT
		MONTH(InvoiceDate) AS Month,
    StockCode,
    Description,
    SUM(Quantity) AS TotalQuantity,
    RANK() OVER (PARTITION BY MONTH(InvoiceDate) ORDER BY SUM(Quantity) DESC) AS Ranking
    FROM `online retail`
       where YEAR(InvoiceDate)= 2011
GROUP BY Month, StockCode, Description

)

SELECT * from Top3
where Ranking <4;
End


---------Customer Retention rate----------


CREATE PROCEDURE `CalculateCustomerRetentionRate`()
BEGIN
    DECLARE total_customers INT;
    DECLARE retained_customers INT;
    DECLARE retention_rate DECIMAL(5, 2);

    -- Total customers
    SELECT COUNT(DISTINCT CustomerID) INTO total_customers
    FROM `online retail`;

    -- Retained customers (purchased in at least two different months)
    SELECT COUNT(DISTINCT CustomerID) INTO retained_customers
    FROM (
        SELECT CustomerID
        FROM `online retail`
        GROUP BY CustomerID
        HAVING COUNT(DISTINCT DATE_FORMAT(InvoiceDate, '%Y-%m')) >= 2
    ) AS retained;

    -- Calculate retention rate
    SET retention_rate = (retained_customers / total_customers) * 100;

    -- Return the result
    SELECT retention_rate AS RetentionRate;
END

------------- Average Order Value -----------------

CREATE PROCEDURE `CalculateAverageOrderValue`()
BEGIN
    SELECT YEAR(InvoiceDate) AS Year, MONTH(InvoiceDate) AS Month,
           AVG(Quantity * UnitPrice) AS AverageOrderValue
    FROM `online retail`
    GROUP BY YEAR(InvoiceDate), MONTH(InvoiceDate)
    ORDER BY Year, Month;
END


--------------Functions--------------

------------Revenue by Date Range---------

CREATE FUNCTION `GetTotalRevenueByDateRange`(StartDate DATE, EndDate DATE) RETURNS decimal(10,2)
    READS SQL DATA
BEGIN
    DECLARE totalRevenue DECIMAL(10, 2);

    SELECT SUM(UnitPrice * Quantity) INTO totalRevenue
    FROM `online retail`
    WHERE InvoiceDate >= StartDate AND InvoiceDate <= EndDate;

    RETURN totalRevenue;
END


--- Revenue by Month and Year ------------


CREATE FUNCTION `GetRevenueByMonthAndYear`(monthNum INT, yearNum INT) RETURNS decimal(10,2)
    READS SQL DATA
BEGIN
    DECLARE revenue DECIMAL(10, 2);

    SELECT SUM(UnitPrice * Quantity) INTO revenue
    FROM `online retail`
    WHERE MONTH(InvoiceDate) = monthNum AND YEAR(InvoiceDate) = yearNum;

    RETURN revenue;
END

