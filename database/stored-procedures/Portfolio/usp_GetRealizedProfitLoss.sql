-- ============================================================================
-- Procedure: usp_GetRealizedProfitLoss
-- Purpose: Calculate total realized profit/loss from executed trades for a user
-- Inputs: @UserId
-- Outputs: TotalRealizedProfitLoss
-- ============================================================================

CREATE OR ALTER PROCEDURE usp_GetRealizedProfitLoss
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        @UserId AS UserId,
        ISNULL(SUM(RealizedProfitLoss), 0.00) AS TotalRealizedProfitLoss
    FROM Trades
    WHERE UserId = @UserId;
END;

