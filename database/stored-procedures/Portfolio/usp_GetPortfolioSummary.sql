-- ============================================================================
-- Procedure: usp_GetPortfolioSummary
-- Purpose: Retrieve high level portfolio totals and balance for a user
-- Inputs: @UserId
-- Tables/Views Accessed: vw_UserPortfolioSummary
-- ============================================================================

CREATE OR ALTER PROCEDURE usp_GetPortfolioSummary
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        UserId,
        Username,
        CashBalance,
        InvestedValue,
        HoldingsMarketValue,
        TotalPortfolioValue,
        UnrealizedProfitLoss,
        RealizedProfitLoss,
        TotalProfitLoss
    FROM vw_UserPortfolioSummary
    WHERE UserId = @UserId;
END;
