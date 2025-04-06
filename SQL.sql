-- View All Data  
SELECT * FROM dbo.Main;  
SELECT * FROM dbo.Customers;  
SELECT * FROM dbo.Orders;  
SELECT * FROM dbo.Orders_Quantity;  
SELECT * FROM dbo.Shipping;  
SELECT * FROM dbo.Products;  

-- ======================
-- Sales & Revenue Analysis  
-- ======================

-- 1. Total sales for each region  
SELECT 
    c.Region,  
    ROUND(SUM(o.Quantity * p.Sales), 0) AS Total_Sales  
FROM Orders o  
JOIN Customers c ON o.[Customer ID] = c.[Customer ID]  
JOIN Products p ON o.[Product ID] = p.[Product ID]  
GROUP BY c.Region  
ORDER BY Total_Sales ASC;  

-- 2. Cities with highest and lowest sales  
SELECT  
    c.City,  
    ROUND(SUM(o.Quantity * p.Sales), 0) AS Total_Sales  
FROM Orders o  
JOIN Customers c ON o.[Customer ID] = c.[Customer ID]  
JOIN Products p ON o.[Product ID] = p.[Product ID]  
GROUP BY c.City  
ORDER BY Total_Sales DESC;  

-- 3. Top 10 best-selling products by revenue  
SELECT TOP 10  
    p.[Product Name],  
    SUM(o.Quantity) AS Total_Units_Sold,  
    ROUND(SUM(o.Quantity * p.Sales), 0) AS Total_Revenue  
FROM Orders o   
JOIN Products p ON o.[Product ID] = p.[Product ID]  
GROUP BY p.[Product Name]  
ORDER BY Total_Revenue DESC;  

-- 4. Sales variation across customer segments  
SELECT  
    c.Segment,  
    ROUND(SUM(o.Quantity * p.Sales), 0) AS Total_Sales,  
    ROUND(100.0 * SUM(o.Quantity * p.Sales) / SUM(SUM(o.Quantity * p.Sales)) OVER(), 2) AS Revenue_Percentage  
FROM Orders o   
JOIN Customers c ON o.[Customer ID] = c.[Customer ID]  
JOIN Products p ON o.[Product ID] = p.[Product ID]  
GROUP BY c.Segment  
ORDER BY Total_Sales DESC;  

-- 5. Sales trends over time (monthly/quarterly/yearly)  
SELECT   
    s.[ship-Year],  
    s.[Ship-Quarter],  
    FORMAT(DATEFROMPARTS(s.[ship-Year], s.[ship-Month], 1), 'MMM') AS Ship_Month_Name,  
    ROUND(SUM(o.Quantity * p.Sales), 0) AS Total_Sales  
FROM Orders o  
JOIN Shipping s ON o.[Order ID] = s.[Order ID]    
JOIN Products p ON o.[Product ID] = p.[Product ID]   
GROUP BY s.[ship-Year], s.[Ship-Quarter], s.[ship-Month]  
ORDER BY s.[ship-Year], s.[Ship-Quarter], s.[ship-Month];  

-- ======================
-- Customer Analysis  
-- ======================

-- 1. Top 10 customers by total purchases  
SELECT TOP 10  
    c.[Customer Name],  
    ROUND(SUM(o.Quantity * p.Sales), 0) AS Total_Sales  
FROM Customers c  
JOIN Orders o ON o.[Customer ID] = c.[Customer ID]  
JOIN Products p ON o.[Product ID] = p.[Product ID]  
GROUP BY c.[Customer Name]  
ORDER BY Total_Sales DESC;  

-- 2. Average order value per customer  
SELECT  
    c.[Customer Name],   
    ROUND(SUM(o.Quantity * p.Sales) / COUNT(DISTINCT o.[Order ID]), 0) AS Avg_Order_Value  
FROM Customers c  
JOIN Orders o ON c.[Customer ID] = o.[Customer ID]   
JOIN Products p ON o.[Product ID] = p.[Product ID]  
GROUP BY c.[Customer Name]  
ORDER BY Avg_Order_Value DESC;  

-- 3. Regions with the most customers  
SELECT  
    c.Region,  
    COUNT(c.[Customer ID]) AS Total_Customers  
FROM Customers c  
GROUP BY c.Region  
ORDER BY Total_Customers DESC;  

-- ======================
-- Shipping & Logistics  
-- ======================

-- 1. How does the shipping mode affect delivery times?  
SELECT  
    s.[Ship Mode],  
    COUNT(*) AS Shipment_Count,  
    ROUND(AVG(s.Duration), 2) AS Avg_Duration  
FROM Shipping s  
GROUP BY s.[Ship Mode]  
ORDER BY Avg_Duration DESC;  

-- 2. Relationship between shipping mode and customer satisfaction  
WITH Customer_Orders AS (  
    SELECT  
        o.[Customer ID],  
        s.[Ship Mode],  
        COUNT(s.[Order ID]) AS Order_Count  
    FROM Shipping s  
    JOIN Orders o ON s.[Order ID] = o.[Order ID]    
    GROUP BY o.[Customer ID], s.[Ship Mode]  
),  
Repeat_Customers AS (  
    SELECT  
        [Ship Mode],  
        COUNT(CASE WHEN Order_Count > 1 THEN 1 END) AS Repeat_Customers,  
        COUNT(*) AS Total_Customers  
    FROM Customer_Orders  
    GROUP BY [Ship Mode]  
)  
SELECT  
    s.[Ship Mode],  
    COUNT(*) AS Shipment_Count,  
    ROUND(AVG(s.Duration), 2) AS Avg_Duration,  
    rc.Total_Customers,  
    rc.Repeat_Customers,  
    ROUND(100.0 * rc.Repeat_Customers / NULLIF(rc.Total_Customers, 0), 2) AS Repeat_Purchase_Rate  
FROM Shipping s  
JOIN Repeat_Customers rc ON s.[Ship Mode] = rc.[Ship Mode]  
GROUP BY s.[Ship Mode], rc.Total_Customers, rc.Repeat_Customers  
ORDER BY Repeat_Purchase_Rate DESC;  

-- 3. Do any states or regions have longer shipping times?  
SELECT  
    c.[Region],  
    c.[State],  
    ROUND(AVG(ABS(DATEDIFF(DAY, o.[Order Date], s.[Ship Date]))), 2) AS Avg_Shipping_Time  
FROM Orders o  
JOIN Shipping s ON o.[Order ID] = s.[Order ID]  
JOIN Customers c ON o.[Customer ID] = c.[Customer ID]  
GROUP BY c.[Region], c.[State]  
ORDER BY Avg_Shipping_Time DESC;  

-- ======================
-- Product Performance & Inventory Management  
-- ======================

-- 1. Which product categories generate the highest revenue?  
SELECT  
    p.Category,  
    ROUND(SUM(o.Quantity * p.Sales), 0) AS Total_Revenue  
FROM Products p  
JOIN Orders o ON p.[Product ID] = o.[Product ID]  
GROUP BY p.Category  
ORDER BY Total_Revenue DESC;  

-- 2. Which sub-categories have the highest profit margins?  
SELECT  
    p.[Sub-Category],  
    ROUND(SUM(o.Quantity * p.Sales), 0) AS Total_Revenue  
FROM Products p  
JOIN Orders o ON p.[Product ID] = o.[Product ID]  
GROUP BY p.[Sub-Category]  
ORDER BY Total_Revenue DESC;  

-- 3. Are there any underperforming products with consistently low sales?  
SELECT 
    p.[Product Name], 
    SUM(o.Quantity) AS Total_Units_Sold,
    ROUND(SUM(o.Quantity * p.Sales), 0) AS Total_Revenue
FROM Orders o
JOIN Products p ON o.[Product ID] = p.[Product ID]
GROUP BY p.[Product Name]
HAVING SUM(o.Quantity) < 10  
   OR SUM(o.Quantity * p.Sales) < 1000 
ORDER BY Total_Revenue ASC, Total_Units_Sold ASC;

-- 4. How do seasonal trends affect product demand?  
SELECT  
    s.[ship-Year], 
    s.[Ship-Quarter], 
    FORMAT(DATEFROMPARTS(s.[ship-Year], s.[ship-Month], 1), 'MMM') AS Ship_Month, 
    p.[Category],  
    SUM(o.Quantity) AS Total_Units_Sold, 
    ROUND(SUM(o.Quantity * p.Sales), 0) AS Total_Revenue
FROM Orders o
JOIN Shipping s ON o.[Order ID] = s.[Order ID]  
JOIN Products p ON o.[Product ID] = p.[Product ID] 
GROUP BY s.[ship-Year], s.[Ship-Quarter], s.[ship-Month], p.[Category]
ORDER BY s.[ship-Year], s.[Ship-Quarter], s.[ship-Month], Total_Revenue DESC;

-- ======================
-- Sales & Demand Analysis (with Quantity)  
-- ======================

-- 1. What are the top 10 best-selling products by quantity sold?  
SELECT TOP 10 
    p.[Product Name],
    SUM(oq.Quantity) AS Total_Quantity_Sold
FROM Products p
JOIN Orders_Quantity oq ON oq.[Product ID] = p.[Product ID]
GROUP BY p.[Product Name]
ORDER BY Total_Quantity_Sold DESC;

-- 2. What is the total quantity sold per region?  
SELECT 
    c.Region,
    SUM(oq.Quantity) AS Total_Quantity_Sold
FROM Customers c
JOIN Orders o ON c.[Customer ID] = o.[Customer ID] 
JOIN Orders_Quantity oq ON oq.[Order ID] = o.[Order ID]
GROUP BY c.Region
ORDER BY Total_Quantity_Sold DESC;

-- 3. How does the quantity sold vary across different customer segments?  
SELECT 
    c.Segment,
    SUM(oq.Quantity) AS Total_Quantity_Sold
FROM Customers c
JOIN Orders o ON c.[Customer ID] = o.[Customer ID] 
JOIN Orders_Quantity oq ON oq.[Order ID] = o.[Order ID]
GROUP BY c.Segment
ORDER BY Total_Quantity_Sold DESC;

-- 4. What is the average quantity per order for each product?  
SELECT 
    p.[Product Name],
    AVG(oq.Quantity) AS Average_Quantity_Per_Order,
    SUM(oq.Quantity) AS Total_Quantity_Sold
FROM Orders o
JOIN Orders_Quantity oq ON o.[Order ID] = oq.[Order ID]  
JOIN Products p ON oq.[Product ID] = p.[Product ID]  
GROUP BY p.[Product Name]
ORDER BY Average_Quantity_Per_Order DESC, Total_Quantity_Sold DESC;

-- 5. Are there any products with consistently low quantity sales that may need promotion or discontinuation?  
SELECT 
    p.[Product Name],
    COUNT(DISTINCT oq.[Order ID]) AS Orders_Count,
    SUM(oq.Quantity) AS Total_Quantity_Sold,
    AVG(oq.Quantity) AS Average_Quantity_Per_Order
FROM Products p
JOIN Orders_Quantity oq ON oq.[Product ID] = p.[Product ID]
GROUP BY p.[Product Name]
HAVING 
    SUM(oq.Quantity) < 50 AND 
    COUNT(DISTINCT oq.[Order ID]) < 10 AND 
    AVG(oq.Quantity) < 3
ORDER BY Total_Quantity_Sold ASC;

-- ======================
-- Inventory & Supply Chain Insights  
-- ======================

-- 1. Which products have the highest demand based on quantity sold?  
SELECT 
    p.[Product Name],
    SUM(oq.Quantity) AS Total_Quantity_Sold
FROM Products p
JOIN Orders_Quantity oq ON oq.[Product ID] = p.[Product ID]
GROUP BY p.[Product Name]
ORDER BY Total_Quantity_Sold DESC;

-- 2. What is the reorder frequency needed for different products to meet demand?  
SELECT 
    p.[Product Name],
    SUM(oq.Quantity) / COUNT(DISTINCT o.[Order ID]) AS Average_Daily_Sales,  -- Calculate the average daily sales
    5 AS Lead_Time_Days, 
    ROUND(SUM(oq.Quantity) / COUNT(DISTINCT o.[Order ID]) * 5, 0) AS Estimated_Reorder_Quantity  -- Estimate how much to reorder
FROM Products p
JOIN Orders_Quantity oq ON oq.[Product ID] = p.[Product ID]
JOIN Orders o ON o.[Order ID] = oq.[Order ID]
GROUP BY p.[Product Name]
ORDER BY Average_Daily_Sales DESC;

-- 3. Are there any seasonal fluctuations in product demand based on quantity sold?  
SELECT  
    s.[ship-Year],  
    s.[Ship-Quarter],  
    FORMAT(DATEFROMPARTS(s.[ship-Year], s.[ship-Month], 1), 'MMM') AS Ship_Month_Name,  
    p.[Product Name],  
    SUM(oq.Quantity) AS Total_Quantity_Sold  
FROM Orders o  
JOIN Shipping s ON o.[Order ID] = s.[Order ID]    
JOIN Products p ON o.[Product ID] = p.[Product ID]  
JOIN Orders_Quantity oq ON oq.[Order ID] = o.[Order ID]  
GROUP BY s.[ship-Year], s.[Ship-Quarter], s.[ship-Month], p.[Product Name]  
ORDER BY s.[ship-Year], s.[Ship-Quarter], s.[ship-Month], Total_Quantity_Sold DESC;

-- 4. Which shipping modes are preferred for high-quantity orders?  
SELECT  
    s.[Ship Mode],  
    COUNT(*) AS Total_Orders,  
    SUM(o.Quantity) AS Total_Quantity_Ordered,  
    AVG(o.Quantity) AS Avg_Quantity_Per_Order  
FROM Shipping s  
JOIN Orders o ON s.[Order ID] = o.[Order ID]  
GROUP BY s.[Ship Mode]  
HAVING SUM(o.Quantity) > 1000  
ORDER BY Total_Quantity_Ordered DESC;
