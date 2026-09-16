-- ============================================================================
-- Procedure: usp_GetTradesByUser
-- Purpose: Retrieve trade history for a specific user
-- Inputs: @UserId, @Limit
-- Tables Accessed: Trades
-- ============================================================================

CREATE OR ALTER PROCEDURE usp_GetTradesByUser
    @UserId INT,
    @Limit INT = 100
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@Limit)
        TradeId,
        OrderId,
        UserId,
        Symbol,
        Side,
        Quantity,
        ExecutionPrice,
        TotalValue,
        RealizedProfitLoss,
        ExecutedDate
    FROM Trades
    WHERE UserId = @UserId
    ORDER BY ExecutedDate DESC;
END;

