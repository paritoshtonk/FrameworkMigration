-- ============================================================================
-- Procedure: usp_CreateTransaction
-- Purpose: Insert a financial ledger transaction record
-- Inputs: @UserId, @TransactionType, @Currency, @Amount, @ReferenceId, @Status
-- Outputs: New TransactionId
-- Tables Modified: Transactions
-- ============================================================================

CREATE OR ALTER PROCEDURE usp_CreateTransaction
    @UserId INT,
    @TransactionType NVARCHAR(20),
    @Currency NVARCHAR(20),
    @Amount DECIMAL(18, 2),
    @ReferenceId NVARCHAR(100) = NULL,
    @Status NVARCHAR(20) = 'COMPLETED',
    @TransactionId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Transactions (UserId, TransactionType, Currency, Amount, ReferenceId, Status, CreatedDate)
    VALUES (@UserId, @TransactionType, @Currency, @Amount, @ReferenceId, @Status, SYSUTCDATETIME());

    SET @TransactionId = SCOPE_IDENTITY();
END;

