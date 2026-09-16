-- ============================================================================
-- Procedure: usp_GetOrdersByUser
-- Purpose: Retrieve all orders placed by a specific user
-- Inputs: @UserId, @Limit
-- Tables Accessed: Orders
-- ============================================================================

CREATE OR ALTER PROCEDURE usp_GetOrdersByUser
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
    WHERE UserId = @UserId
    ORDER BY CreatedDate DESC;
END;
