-- ============================================================================
-- Procedure: usp_ExecuteBuyOrder
-- Purpose: Execute a simulated cryptocurrency BUY transaction atomically
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
--   4. Calculate trade value
--   5. Acquire exclusive lock on user account (UPDLOCK, HOLDLOCK)
--   6. Validate sufficient available cash balance
--   7. Insert Order (Status = 'Executed')
--   8. Insert Trade
--   9. Deduct cash from user Account
--  10. Insert or update user Wallet holding with weighted average cost
--  11. Insert Transaction ledger entry (Type = 'BUY')
--  12. Commit transaction atomically
--
-- Transaction:
--   SQL Server transaction with BEGIN TRY / BEGIN TRANSACTION / COMMIT / ROLLBACK
-- ============================================================================

CREATE OR ALTER PROCEDURE usp_ExecuteBuyOrder
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
    DECLARE @CurrentBalance DECIMAL(18, 2);
    DECLARE @CurrentWalletQty DECIMAL(28, 8) = 0.00000000;
    DECLARE @CurrentAvgCost DECIMAL(28, 8) = 0.00000000;
    DECLARE @NewQuantity DECIMAL(28, 8);
    DECLARE @NewAvgCost DECIMAL(28, 8);
    DECLARE @ExecutedDate DATETIME2(7) = SYSUTCDATETIME();

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Lock account row to prevent race conditions / concurrent double spending
        SELECT @CurrentBalance = AvailableBalance
        FROM Accounts WITH (UPDLOCK, HOLDLOCK)
        WHERE UserId = @UserId AND Currency = 'USD';

        IF @CurrentBalance IS NULL
        BEGIN
            RAISERROR('Account not found for user.', 16, 6);
        END

        IF @CurrentBalance < @TradeValue
        BEGIN
            RAISERROR('Insufficient balance for this purchase.', 16, 7);
        END

        -- 1. Create Order
        INSERT INTO Orders (UserId, Symbol, OrderType, Side, Quantity, Price, TotalValue, Status, CreatedDate, ExecutedDate)
        VALUES (@UserId, @Symbol, 'Market', 'BUY', @Quantity, @ExecutionPrice, @TradeValue, 'Executed', @ExecutedDate, @ExecutedDate);

        SET @OrderId = SCOPE_IDENTITY();

        -- 2. Create Trade
        INSERT INTO Trades (OrderId, UserId, Symbol, Side, Quantity, ExecutionPrice, TotalValue, RealizedProfitLoss, ExecutedDate)
        VALUES (@OrderId, @UserId, @Symbol, 'BUY', @Quantity, @ExecutionPrice, @TradeValue, 0.00, @ExecutedDate);

        SET @TradeId = SCOPE_IDENTITY();

        -- 3. Deduct Cash Balance
        UPDATE Accounts
        SET 
            AvailableBalance = AvailableBalance - @TradeValue,
            UpdatedDate = @ExecutedDate
        WHERE UserId = @UserId AND Currency = 'USD';

        -- 4. Update or Insert Wallet Holding
        IF EXISTS (SELECT 1 FROM Wallets WITH (UPDLOCK, HOLDLOCK) WHERE UserId = @UserId AND Currency = @Symbol)
        BEGIN
            SELECT 
                @CurrentWalletQty = Quantity,
                @CurrentAvgCost = AverageCost
            FROM Wallets WITH (UPDLOCK, HOLDLOCK)
            WHERE UserId = @UserId AND Currency = @Symbol;

            SET @NewQuantity = @CurrentWalletQty + @Quantity;
            -- Calculate weighted average cost
            SET @NewAvgCost = ((@CurrentWalletQty * @CurrentAvgCost) + (@Quantity * @ExecutionPrice)) / @NewQuantity;

            UPDATE Wallets
            SET 
                Quantity = @NewQuantity,
                AverageCost = @NewAvgCost,
                UpdatedDate = @ExecutedDate
            WHERE UserId = @UserId AND Currency = @Symbol;
        END
        ELSE
        BEGIN
            INSERT INTO Wallets (UserId, Currency, Quantity, AverageCost, CreatedDate, UpdatedDate)
            VALUES (@UserId, @Symbol, @Quantity, @ExecutionPrice, @ExecutedDate, @ExecutedDate);
        END

        -- 5. Create Transaction Ledger Entry
        INSERT INTO Transactions (UserId, TransactionType, Currency, Amount, ReferenceId, Status, CreatedDate)
        VALUES (@UserId, 'BUY', 'USD', @TradeValue, CAST(@TradeId AS NVARCHAR(100)), 'COMPLETED', @ExecutedDate);

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
            a.AvailableBalance AS RemainingBalance
        FROM Trades t
        INNER JOIN Accounts a ON t.UserId = a.UserId AND a.Currency = 'USD'
        WHERE t.TradeId = @TradeId;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;

