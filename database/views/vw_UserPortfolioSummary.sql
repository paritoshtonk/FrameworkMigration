-- ============================================================================
-- vw_UserPortfolioSummary.sql
-- Aggregated portfolio view per user
-- ============================================================================

CREATE OR ALTER VIEW vw_UserPortfolioSummary AS
SELECT 
    u.UserId,
    u.Username,
    ISNULL(a.AvailableBalance, 0) AS CashBalance,
    ISNULL(h.InvestedCost, 0) AS InvestedValue,
    ISNULL(h.TotalMarketValue, 0) AS HoldingsMarketValue,
    CAST(ISNULL(a.AvailableBalance, 0) + ISNULL(h.TotalMarketValue, 0) AS DECIMAL(18,2)) AS TotalPortfolioValue,
    ISNULL(h.TotalUnrealizedPL, 0) AS UnrealizedProfitLoss,
    ISNULL(t.TotalRealizedPL, 0) AS RealizedProfitLoss,
    CAST(ISNULL(h.TotalUnrealizedPL, 0) + ISNULL(t.TotalRealizedPL, 0) AS DECIMAL(18,2)) AS TotalProfitLoss
FROM Users u
LEFT JOIN Accounts a ON u.UserId = a.UserId AND a.Currency = 'USD'
LEFT JOIN (
    SELECT 
        UserId,
        SUM(TotalCost) AS InvestedCost,
        SUM(CurrentValue) AS TotalMarketValue,
        SUM(UnrealizedProfitLoss) AS TotalUnrealizedPL
    FROM vw_UserActiveHoldings
    GROUP BY UserId
) h ON u.UserId = h.UserId
LEFT JOIN (
    SELECT 
        UserId,
        SUM(RealizedProfitLoss) AS TotalRealizedPL
    FROM Trades
    GROUP BY UserId
) t ON u.UserId = t.UserId;
