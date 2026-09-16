-- ============================================================================
-- Procedure: usp_GetCryptocurrencyBySymbol
-- Purpose: Retrieve cryptocurrency details and price by symbol
-- Inputs: @Symbol
-- Tables Accessed: Cryptocurrencies
-- ============================================================================

CREATE OR ALTER PROCEDURE usp_GetCryptocurrencyBySymbol
    @Symbol NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        CryptocurrencyId,
        Symbol,
        Name,
        CurrentPrice,
        PriceChange24h,
        LastUpdated,
        IsActive
    FROM Cryptocurrencies
    WHERE Symbol = @Symbol;
END;
