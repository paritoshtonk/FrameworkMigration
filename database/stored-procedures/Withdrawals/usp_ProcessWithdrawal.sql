-- ============================================================================
-- Procedure: usp_ProcessWithdrawal
-- Purpose: Process simulated fiat withdrawal atomically
-- Inputs: @UserId, @Amount, @Currency
-- Outputs: @WithdrawalId, remaining balance
-- Operations:
--   1. Validate user and amount
--   2. Acquire exclusive lock on user Account (UPDLOCK, HOLDLOCK)
--   3. Validate available balance >= withdrawal amount
--   4. Insert Withdrawal record
--   5. Deduct Account available balance
--   6. Insert Transaction ledger entry (Type = 'WITHDRAWAL')
--   7. Commit transaction atomically
-- ============================================================================

CREATE OR ALTER PROCEDURE usp_ProcessWithdrawal
    @UserId INT,
    @Amount DECIMAL(18, 2),
    @Currency NVARCHAR(10) = 'USD',
    @WithdrawalId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @Amount <= 0
    BEGIN
        RAISERROR('Withdrawal amount must be greater than zero.', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM Users WHERE UserId = @UserId AND IsActive = 1)
    BEGIN
        RAISERROR('User not found or inactive.', 16, 2);
        RETURN;
    END

    DECLARE @CurrentBalance DECIMAL(18, 2);
    DECLARE @ProcessedDate DATETIME2(7) = SYSUTCDATETIME();

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Lock account row exclusively to eliminate race condition / double spend
        SELECT @CurrentBalance = AvailableBalance
        FROM Accounts WITH (UPDLOCK, HOLDLOCK)
        WHERE UserId = @UserId AND Currency = @Currency;

        IF @CurrentBalance IS NULL
        BEGIN
            RAISERROR('Account not found for user.', 16, 3);
        END

        IF @CurrentBalance < @Amount
        BEGIN
            RAISERROR('Insufficient balance for this withdrawal.', 16, 4);
        END

        -- 1. Create Withdrawal Record
        INSERT INTO Withdrawals (UserId, Amount, Currency, Status, CreatedDate, ProcessedDate)
        VALUES (@UserId, @Amount, @Currency, 'COMPLETED', @ProcessedDate, @ProcessedDate);

        SET @WithdrawalId = SCOPE_IDENTITY();

        -- 2. Deduct Account Balance
        UPDATE Accounts
        SET 
            AvailableBalance = AvailableBalance - @Amount,
            UpdatedDate = @ProcessedDate
        WHERE UserId = @UserId AND Currency = @Currency;

        -- 3. Create Transaction Ledger Entry
        INSERT INTO Transactions (UserId, TransactionType, Currency, Amount, ReferenceId, Status, CreatedDate)
        VALUES (@UserId, 'WITHDRAWAL', @Currency, @Amount, CAST(@WithdrawalId AS NVARCHAR(100)), 'COMPLETED', @ProcessedDate);

        COMMIT TRANSACTION;

        -- Return Withdrawal Summary
        SELECT 
            w.WithdrawalId,
            w.UserId,
            w.Amount,
            w.Currency,
            w.Status,
            w.CreatedDate,
            w.ProcessedDate,
            a.AvailableBalance AS RemainingBalance
        FROM Withdrawals w
        INNER JOIN Accounts a ON w.UserId = a.UserId AND a.Currency = w.Currency
        WHERE w.WithdrawalId = @WithdrawalId;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;

