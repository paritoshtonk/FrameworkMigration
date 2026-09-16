-- ============================================================================
-- vw_UserActiveHoldings.sql
-- Active cryptocurrency holdings with live market prices and calculated values
-- ============================================================================

CREATE OR ALTER VIEW vw_UserActiveHoldings AS
SELECT 
    w.WalletId,
    w.UserId,
    w.Currency AS Symbol,
    c.Name,
    w.Quantity,
    w.AverageCost,
    ISNULL(c.CurrentPrice, 0) AS CurrentPrice,
    CAST(w.Quantity * ISNULL(c.CurrentPrice, 0) AS DECIMAL(18,2)) AS CurrentValue,
    CAST(w.Quantity * w.AverageCost AS DECIMAL(18,2)) AS TotalCost,
    CAST((w.Quantity * ISNULL(c.CurrentPrice, 0)) - (w.Quantity * w.AverageCost) AS DECIMAL(18,2)) AS UnrealizedProfitLoss,
    CASE 
        WHEN (w.Quantity * w.AverageCost) > 0 
        THEN CAST((((w.Quantity * ISNULL(c.CurrentPrice, 0)) - (w.Quantity * w.AverageCost)) / (w.Quantity * w.AverageCost)) * 100.0 AS DECIMAL(18,2))
        ELSE 0.00 
    END AS UnrealizedProfitLossPercentage,
    w.UpdatedDate
FROM Wallets w
LEFT JOIN Cryptocurrencies c ON w.Currency = c.Symbol
WHERE w.Quantity > 0;
