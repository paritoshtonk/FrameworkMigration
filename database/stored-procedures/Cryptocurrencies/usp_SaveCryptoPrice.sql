-- ============================================================================
-- Procedure: usp_SaveCryptoPrice
-- Purpose: Update cryptocurrency live price and record historical snapshot
-- Inputs: @Symbol, @Price, @PriceChange24h
-- Tables Modified: Cryptocurrencies, PriceHistory
-- Transaction: Atomic SQL Transaction
-- ============================================================================

CREATE OR ALTER PROCEDURE usp_SaveCryptoPrice
    @Symbol NVARCHAR(20),
    @Price DECIMAL(28, 8),
    @PriceChange24h DECIMAL(18, 4) = 0.0000
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @CryptoId INT;

    SELECT @CryptoId = CryptocurrencyId 
    FROM Cryptocurrencies 
    WHERE Symbol = @Symbol;

    IF @CryptoId IS NULL
    BEGIN
        RAISERROR('Cryptocurrency symbol not recognized.', 16, 1);
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE Cryptocurrencies
        SET 
            CurrentPrice = @Price,
            PriceChange24h = @PriceChange24h,
            LastUpdated = SYSUTCDATETIME()
        WHERE CryptocurrencyId = @CryptoId;

        INSERT INTO PriceHistory (CryptocurrencyId, Price, RecordedDate)
        VALUES (@CryptoId, @Price, SYSUTCDATETIME());

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
