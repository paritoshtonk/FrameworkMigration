-- ============================================================================
-- Procedure: usp_GetWithdrawalsByUser
-- Purpose: Retrieve withdrawal history for a specific user
-- Inputs: @UserId, @Limit
-- Tables Accessed: Withdrawals
-- ============================================================================

CREATE OR ALTER PROCEDURE usp_GetWithdrawalsByUser
    @UserId INT,
    @Limit INT = 100
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@Limit)
        WithdrawalId,
        UserId,
        Amount,
        Currency,
        Status,
        CreatedDate,
        ProcessedDate
    FROM Withdrawals
    WHERE UserId = @UserId
    ORDER BY CreatedDate DESC;
END;

