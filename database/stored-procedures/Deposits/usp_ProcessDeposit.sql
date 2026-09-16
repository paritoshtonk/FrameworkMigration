-- ============================================================================
-- Procedure: usp_ProcessDeposit
-- Purpose: Process simulated fiat deposit atomically
-- Inputs: @UserId, @Amount, @Currency
-- Outputs: @DepositId, new balance
-- Operations:
--   1. Validate user and amount
--   2. Insert Deposit record
--   3. Lock and credit Account balance
--   4. Insert Transaction ledger entry (Type = 'DEPOSIT')
--   5. Commit transaction atomically
-- ============================================================================

CREATE OR ALTER PROCEDURE usp_ProcessDeposit
    @UserId INT,
    @Amount DECIMAL(18, 2),
    @Currency NVARCHAR(10) = 'USD',
    @DepositId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @Amount <= 0
    BEGIN
        RAISERROR('Deposit amount must be greater than zero.', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM Users WHERE UserId = @UserId AND IsActive = 1)
    BEGIN
        RAISERROR('User not found or inactive.', 16, 2);
        RETURN;
    END

    DECLARE @ProcessedDate DATETIME2(7) = SYSUTCDATETIME();

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Create Deposit Record
        INSERT INTO Deposits (UserId, Amount, Currency, Status, CreatedDate, ProcessedDate)
        VALUES (@UserId, @Amount, @Currency, 'COMPLETED', @ProcessedDate, @ProcessedDate);

        SET @DepositId = SCOPE_IDENTITY();

        -- 2. Update Account AvailableBalance
        IF EXISTS (SELECT 1 FROM Accounts WITH (UPDLOCK, HOLDLOCK) WHERE UserId = @UserId AND Currency = @Currency)
        BEGIN
            UPDATE Accounts
            SET 
                AvailableBalance = AvailableBalance + @Amount,
                UpdatedDate = @ProcessedDate
            WHERE UserId = @UserId AND Currency = @Currency;
        END
        ELSE
        BEGIN
            INSERT INTO Accounts (UserId, Currency, AvailableBalance, CreatedDate, UpdatedDate)
            VALUES (@UserId, @Currency, @Amount, @ProcessedDate, @ProcessedDate);
        END

        -- 3. Create Transaction Ledger Entry
        INSERT INTO Transactions (UserId, TransactionType, Currency, Amount, ReferenceId, Status, CreatedDate)
        VALUES (@UserId, 'DEPOSIT', @Currency, @Amount, CAST(@DepositId AS NVARCHAR(100)), 'COMPLETED', @ProcessedDate);

        COMMIT TRANSACTION;

        -- Return Deposit Summary
        SELECT 
            d.DepositId,
            d.UserId,
            d.Amount,
            d.Currency,
            d.Status,
            d.CreatedDate,
            d.ProcessedDate,
            a.AvailableBalance AS NewBalance
        FROM Deposits d
        INNER JOIN Accounts a ON d.UserId = a.UserId AND a.Currency = d.Currency
        WHERE d.DepositId = @DepositId;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
