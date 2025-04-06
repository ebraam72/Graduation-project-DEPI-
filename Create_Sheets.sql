-- Create Customers table
SELECT DISTINCT 
    [Customer ID], 
    [Customer Name], 
    Segment, 
    Country, 
    City, 
    State, 
    Region, 
    [Postal Code]
INTO Customers
FROM dbo.Main

-- Create Products table
SELECT DISTINCT 
    [Product ID], 
    [Product Name], 
    Category, 
    Sales, 
	[Sub-Category],
    [ship-Day]
INTO Products
FROM dbo.Main

-- Calculate Quantity for each Order ID and Product ID
SELECT 
    [Order ID], 
    [Product ID], 
    COUNT(*) AS Quantity
INTO Orders_Quantity
FROM dbo.Main
GROUP BY [Order ID], [Product ID]

-- Create Orders table and join with Quantity
SELECT DISTINCT 
    o.[Order ID], 
    o.[Customer ID], 
    o.[Product ID], 
    o.[Order Date], 
    o.[order-Day], 
    o.[order-Month], 
    o.[order-Year], 
    q.Quantity
INTO Orders
FROM dbo.Main o
LEFT JOIN Orders_Quantity q 
ON o.[Order ID] = q.[Order ID] AND o.[Product ID] = q.[Product ID]

-- Create Shipping table
SELECT DISTINCT 
    [Order ID], 
    [Ship Mode], 
    [Ship Date], 
    [ship-Day], 
    [ship-Month], 
    [ship-Year],
	 DATEPART(QUARTER, [Ship Date]) AS [Ship-Quarter],
    Duration
INTO Shipping
FROM dbo.Main
