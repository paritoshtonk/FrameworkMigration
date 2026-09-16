-- ============================================================================
-- Procedure: usp_GetPortfolioPerformance
-- Purpose: Calculate comprehensive performance metrics for a user
-- Inputs: @UserId
-- Outputs: Overall performance return, deposits, withdrawals, trade metrics
-- Tables Accessed: Accounts, Trades, Deposits, Withdrawals, vw_UserPortfolioSummary
-- ============================================================================

CREATE OR ALTER PROCEDURE usp_GetPortfolioPerformance
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TotalDeposited DECIMAL(18,2) = 0.00;
    DECLARE @TotalWithdrawn DECIMAL(18,2) = 0.00;
    DECLARE @TotalTradesCount INT = 0;

    SELECT @TotalDeposited = ISNULL(SUM(Amount), 0.00)
    FROM Deposits
    WHERE UserId = @UserId AND Status = 'COMPLETED';

    SELECT @TotalWithdrawn = ISNULL(SUM(Amount), 0.00)
    FROM Withdrawals
    WHERE UserId = @UserId AND Status = 'COMPLETED';

    SELECT @TotalTradesCount = COUNT(*)
    FROM Trades
    WHERE UserId = @UserId;

    SELECT 
        s.UserId,
        s.Username,
        s.CashBalance,
        s.InvestedValue,
        s.HoldingsMarketValue,
        s.TotalPortfolioValue,
        s.UnrealizedProfitLoss,
        s.RealizedProfitLoss,
        s.TotalProfitLoss,
        CASE 
            WHEN s.InvestedValue > 0 
            THEN CAST((s.TotalProfitLoss / s.InvestedValue) * 100.0 AS DECIMAL(18,2))
            ELSE 0.00
        END AS ReturnPercentage,
        @TotalDeposited AS TotalDeposited,
        @TotalWithdrawn AS TotalWithdrawn,
        @TotalTradesCount AS TotalTradesCount
    FROM vw_UserPortfolioSummary s
    WHERE s.UserId = @UserId;
END;
