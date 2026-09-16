-- ============================================================================
-- Procedure: usp_GetTransactionsByUser
-- Purpose: Retrieve financial transaction ledger entries for a user
-- Inputs: @UserId, @Limit
-- Tables Accessed: Transactions
-- ============================================================================

CREATE OR ALTER PROCEDURE usp_GetTransactionsByUser
    @UserId INT,
    @Limit INT = 100
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@Limit)
        TransactionId,
        UserId,
        TransactionType,
        Currency,
        Amount,
        ReferenceId,
        Status,
        CreatedDate
    FROM Transactions
    WHERE UserId = @UserId
    ORDER BY CreatedDate DESC;
END;

