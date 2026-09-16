-- ============================================================================
-- Procedure: usp_ExecuteSellOrder
-- Purpose: Execute a simulated cryptocurrency SELL transaction atomically
-- Inputs:
--   @UserId INT
--   @Symbol NVARCHAR(20)
--   @Quantity DECIMAL(28, 8)
--   @ExecutionPrice DECIMAL(28, 8)
--
-- Operations:
--   1. Validate user and active status
--   2. Validate cryptocurrency
--   3. Validate quantity and price
--   4. Lock user Wallet holding with (UPDLOCK, HOLDLOCK)
--   5. Validate user has sufficient cryptocurrency quantity
--   6. Calculate trade value and realized P/L: (ExecutionPrice - AverageCost) * Quantity
--   7. Insert Order (Status = 'Executed')
--   8. Insert Trade with RealizedProfitLoss
--   9. Reduce user Wallet holding
--  10. Increase user Account cash balance
--  11. Insert Transaction ledger entry (Type = 'SELL')
--  12. Commit transaction atomically
--
-- Transaction:
--   SQL Server transaction with BEGIN TRY / BEGIN TRANSACTION / COMMIT / ROLLBACK
-- ============================================================================

CREATE OR ALTER PROCEDURE usp_ExecuteSellOrder
    @UserId INT,
    @Symbol NVARCHAR(20),
    @Quantity DECIMAL(28, 8),
    @ExecutionPrice DECIMAL(28, 8),
    @TradeId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Validations
    IF @Quantity <= 0
    BEGIN
        RAISERROR('Quantity must be greater than zero.', 16, 1);
        RETURN;
    END

    IF @ExecutionPrice <= 0
    BEGIN
        RAISERROR('Execution price must be greater than zero.', 16, 2);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM Users WHERE UserId = @UserId AND IsActive = 1)
    BEGIN
        RAISERROR('User not found or inactive.', 16, 3);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM Cryptocurrencies WHERE Symbol = @Symbol AND IsActive = 1)
    BEGIN
        RAISERROR('Cryptocurrency symbol is invalid or inactive.', 16, 4);
        RETURN;
    END

    DECLARE @TradeValue DECIMAL(18, 2);
    SET @TradeValue = CAST(@Quantity * @ExecutionPrice AS DECIMAL(18, 2));

    IF @TradeValue <= 0.00
    BEGIN
        RAISERROR('Trade value must be greater than zero.', 16, 5);
        RETURN;
    END

    DECLARE @OrderId INT;
    DECLARE @OwnedQuantity DECIMAL(28, 8);
    DECLARE @AverageCost DECIMAL(28, 8);
    DECLARE @RealizedPL DECIMAL(18, 2);
    DECLARE @NewQuantity DECIMAL(28, 8);
    DECLARE @ExecutedDate DATETIME2(7) = SYSUTCDATETIME();

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Lock wallet row to prevent concurrent double-spending
        SELECT 
            @OwnedQuantity = Quantity,
            @AverageCost = AverageCost
        FROM Wallets WITH (UPDLOCK, HOLDLOCK)
        WHERE UserId = @UserId AND Currency = @Symbol;

        IF @OwnedQuantity IS NULL OR @OwnedQuantity < @Quantity
        BEGIN
            RAISERROR('Insufficient cryptocurrency holdings to execute this sell order.', 16, 6);
        END

        -- Calculate Realized Profit/Loss
        SET @RealizedPL = CAST((@ExecutionPrice - @AverageCost) * @Quantity AS DECIMAL(18, 2));

        -- 1. Create Order
        INSERT INTO Orders (UserId, Symbol, OrderType, Side, Quantity, Price, TotalValue, Status, CreatedDate, ExecutedDate)
        VALUES (@UserId, @Symbol, 'Market', 'SELL', @Quantity, @ExecutionPrice, @TradeValue, 'Executed', @ExecutedDate, @ExecutedDate);

        SET @OrderId = SCOPE_IDENTITY();

        -- 2. Create Trade
        INSERT INTO Trades (OrderId, UserId, Symbol, Side, Quantity, ExecutionPrice, TotalValue, RealizedProfitLoss, ExecutedDate)
        VALUES (@OrderId, @UserId, @Symbol, 'SELL', @Quantity, @ExecutionPrice, @TradeValue, @RealizedPL, @ExecutedDate);

        SET @TradeId = SCOPE_IDENTITY();

        -- 3. Reduce Wallet Holding
        SET @NewQuantity = @OwnedQuantity - @Quantity;

        UPDATE Wallets
        SET 
            Quantity = @NewQuantity,
            AverageCost = CASE WHEN @NewQuantity = 0 THEN 0.00000000 ELSE AverageCost END,
            UpdatedDate = @ExecutedDate
        WHERE UserId = @UserId AND Currency = @Symbol;

        -- 4. Credit Account Cash Balance
        UPDATE Accounts
        SET 
            AvailableBalance = AvailableBalance + @TradeValue,
            UpdatedDate = @ExecutedDate
        WHERE UserId = @UserId AND Currency = 'USD';

        -- 5. Create Transaction Ledger Entry
        INSERT INTO Transactions (UserId, TransactionType, Currency, Amount, ReferenceId, Status, CreatedDate)
        VALUES (@UserId, 'SELL', 'USD', @TradeValue, CAST(@TradeId AS NVARCHAR(100)), 'COMPLETED', @ExecutedDate);

        COMMIT TRANSACTION;

        -- Return Trade Summary
        SELECT 
            t.TradeId,
            t.OrderId,
            t.UserId,
            t.Symbol,
            t.Side,
            t.Quantity,
            t.ExecutionPrice,
            t.TotalValue,
            t.RealizedProfitLoss,
            t.ExecutedDate,
            a.AvailableBalance AS RemainingBalance,
            w.Quantity AS RemainingCryptoHolding
        FROM Trades t
        INNER JOIN Accounts a ON t.UserId = a.UserId AND a.Currency = 'USD'
        INNER JOIN Wallets w ON t.UserId = w.UserId AND w.Currency = t.Symbol
        WHERE t.TradeId = @TradeId;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;

