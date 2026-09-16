-- ============================================================================
-- Procedure: usp_GetCryptocurrencies
-- Purpose: Retrieve list of all active cryptocurrencies with current prices
-- Tables Accessed: Cryptocurrencies
-- ============================================================================

CREATE OR ALTER PROCEDURE usp_GetCryptocurrencies
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
    WHERE IsActive = 1
    ORDER BY CryptocurrencyId ASC;
END;
