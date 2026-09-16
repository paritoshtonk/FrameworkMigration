-- ============================================================================
-- Procedure: usp_GetUnrealizedProfitLoss
-- Purpose: Calculate total unrealized profit/loss across all holdings for a user
-- Inputs: @UserId
-- Outputs: TotalUnrealizedProfitLoss
-- ============================================================================

CREATE OR ALTER PROCEDURE usp_GetUnrealizedProfitLoss
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        @UserId AS UserId,
        ISNULL(SUM(UnrealizedProfitLoss), 0.00) AS TotalUnrealizedProfitLoss
    FROM vw_UserActiveHoldings
    WHERE UserId = @UserId;
END;

