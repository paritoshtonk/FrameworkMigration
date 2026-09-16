-- ============================================================================
-- Procedure: usp_GetDepositsByUser
-- Purpose: Retrieve deposit history for a specific user
-- Inputs: @UserId, @Limit
-- Tables Accessed: Deposits
-- ============================================================================

CREATE OR ALTER PROCEDURE usp_GetDepositsByUser
    @UserId INT,
    @Limit INT = 100
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@Limit)
        DepositId,
        UserId,
        Amount,
        Currency,
        Status,
        CreatedDate,
        ProcessedDate
    FROM Deposits
    WHERE UserId = @UserId
    ORDER BY CreatedDate DESC;
END;
