-- ============================================================================
-- Procedure: usp_GetOrder
-- Purpose: Retrieve a single order by OrderId and UserId for authorization
-- Inputs: @OrderId, @UserId
-- Tables Accessed: Orders
-- ============================================================================

CREATE OR ALTER PROCEDURE usp_GetOrder
    @OrderId INT,
    @UserId INT = NULL
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
    WHERE OrderId = @OrderId
      AND (@UserId IS NULL OR UserId = @UserId);
END;
