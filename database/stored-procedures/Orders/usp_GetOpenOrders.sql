-- ============================================================================
-- Procedure: usp_GetOpenOrders
-- Purpose: Retrieve open/pending orders for a specific user
-- Inputs: @UserId
-- Tables Accessed: Orders
-- ============================================================================

CREATE OR ALTER PROCEDURE usp_GetOpenOrders
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
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
    WHERE UserId = @UserId AND Status = 'Pending'
    ORDER BY CreatedDate DESC;
END;
