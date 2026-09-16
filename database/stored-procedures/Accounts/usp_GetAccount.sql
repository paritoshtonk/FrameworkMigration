-- ============================================================================
-- Procedure: usp_GetAccount
-- Purpose: Retrieve full account record for a user
-- Inputs: @UserId, @Currency
-- Tables Accessed: Accounts
-- ============================================================================

CREATE OR ALTER PROCEDURE usp_GetAccount
    @UserId INT,
    @Currency NVARCHAR(10) = 'USD'
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        AccountId,
        UserId,
        Currency,
        AvailableBalance,
        CreatedDate,
        UpdatedDate
    FROM Accounts
    WHERE UserId = @UserId AND Currency = @Currency;
END;
