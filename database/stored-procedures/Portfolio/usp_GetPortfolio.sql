-- ============================================================================
-- Procedure: usp_GetPortfolio
-- Purpose: Retrieve full portfolio summary and holdings list for a user
-- Inputs: @UserId
-- Outputs: 
--   Result Set 1: Portfolio Summary (CashBalance, HoldingsMarketValue, TotalPortfolioValue, InvestedValue, UnrealizedPL, RealizedPL, TotalPL)
--   Result Set 2: Holdings List (Symbol, Name, Quantity, AverageCost, CurrentPrice, CurrentValue, UnrealizedPL, UnrealizedPLPct)
-- Tables/Views Accessed: vw_UserPortfolioSummary, vw_UserActiveHoldings
-- ============================================================================

CREATE OR ALTER PROCEDURE usp_GetPortfolio
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Result Set 1: Portfolio Summary
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

    -- Result Set 2: Holdings
    SELECT 
        WalletId,
        UserId,
        Symbol,
        Name,
        Quantity,
        AverageCost,
        CurrentPrice,
        CurrentValue,
        TotalCost,
        UnrealizedProfitLoss,
        UnrealizedProfitLossPercentage,
        UpdatedDate
    FROM vw_UserActiveHoldings
    WHERE UserId = @UserId
    ORDER BY CurrentValue DESC;
END;
