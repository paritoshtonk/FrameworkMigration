-- ============================================================================
-- Procedure: usp_GetTransactionById
-- Purpose: Retrieve a single transaction record by id and validate user ownership
-- Inputs: @TransactionId, @UserId
-- Tables Accessed: Transactions
-- ============================================================================

CREATE OR ALTER PROCEDURE usp_GetTransactionById
    @TransactionId INT,
    @UserId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        TransactionId,
        UserId,
        TransactionType,
        Currency,
        Amount,
        ReferenceId,
        Status,
        CreatedDate
    FROM Transactions
    WHERE TransactionId = @TransactionId
      AND (@UserId IS NULL OR UserId = @UserId);
END;

