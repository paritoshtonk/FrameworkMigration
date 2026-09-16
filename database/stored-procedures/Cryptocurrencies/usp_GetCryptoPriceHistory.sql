-- ============================================================================
-- Procedure: usp_GetCryptoPriceHistory
-- Purpose: Retrieve price history for a cryptocurrency up to a specified limit
-- Inputs: @Symbol, @Limit
-- Tables Accessed: Cryptocurrencies, PriceHistory
-- ============================================================================

CREATE OR ALTER PROCEDURE usp_GetCryptoPriceHistory
    @Symbol NVARCHAR(20),
    @Limit INT = 100
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@Limit)
        ph.PriceHistoryId,
        c.Symbol,
        ph.Price,
        ph.RecordedDate
    FROM PriceHistory ph
    INNER JOIN Cryptocurrencies c ON ph.CryptocurrencyId = c.CryptocurrencyId
    WHERE c.Symbol = @Symbol
    ORDER BY ph.RecordedDate DESC;
END;
