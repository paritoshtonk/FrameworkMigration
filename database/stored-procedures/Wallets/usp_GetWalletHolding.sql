-- ============================================================================
-- Procedure: usp_GetWalletHolding
-- Purpose: Retrieve a specific cryptocurrency holding for a user
-- Inputs: @UserId, @Currency
-- Tables Accessed: Wallets, Cryptocurrencies
-- ============================================================================

CREATE OR ALTER PROCEDURE usp_GetWalletHolding
    @UserId INT,
    @Currency NVARCHAR(20)
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
    WHERE w.UserId = @UserId AND w.Currency = @Currency;
END;

