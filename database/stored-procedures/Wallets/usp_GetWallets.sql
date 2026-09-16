-- ============================================================================
-- Procedure: usp_GetWallets
-- Purpose: Retrieve all cryptocurrency wallet holdings for a user
-- Inputs: @UserId
-- Tables Accessed: Wallets, Cryptocurrencies
-- ============================================================================

CREATE OR ALTER PROCEDURE usp_GetWallets
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        w.WalletId,
        w.UserId,
        w.Currency,
        c.Name AS CurrencyName,
        w.Quantity,
        w.AverageCost,
        w.CreatedDate,
        w.UpdatedDate
    FROM Wallets w
    LEFT JOIN Cryptocurrencies c ON w.Currency = c.Symbol
    WHERE w.UserId = @UserId AND w.Quantity > 0
    ORDER BY w.Currency ASC;
END;

