-- ============================================================================
-- Procedure: usp_GetLatestCryptoPrice
-- Purpose: Retrieve the latest recorded price for a cryptocurrency
-- Inputs: @Symbol
-- Outputs: Price, LastUpdated
-- Tables Accessed: Cryptocurrencies
-- ============================================================================

CREATE OR ALTER PROCEDURE usp_GetLatestCryptoPrice
    @Symbol NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        Symbol,
        CurrentPrice,
        PriceChange24h,
        LastUpdated
    FROM Cryptocurrencies
    WHERE Symbol = @Symbol;
END;
