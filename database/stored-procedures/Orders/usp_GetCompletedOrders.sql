-- ============================================================================
-- Procedure: usp_GetCompletedOrders
-- Purpose: Retrieve completed (Executed, Cancelled, Rejected) orders for a user
-- Inputs: @UserId, @Limit
-- Tables Accessed: Orders
-- ============================================================================

CREATE OR ALTER PROCEDURE usp_GetCompletedOrders
    @UserId INT,
    @Limit INT = 100
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@Limit)
        OrderId,
        UserId,
        Symbol,
        OrderType,
        Side,
        Quantity,
        Price,
        TotalValue,
        Status,
        CreatedDate,
        ExecutedDate
    FROM Orders
    WHERE UserId = @UserId AND Status IN ('Executed', 'Cancelled', 'Rejected')
    ORDER BY ISNULL(ExecutedDate, CreatedDate) DESC;
END;
