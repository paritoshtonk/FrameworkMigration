-- ============================================================================
-- Procedure: usp_GetAccountBalance
-- Purpose: Retrieve available cash balance for a user
-- Inputs: @UserId, @Currency
-- Outputs: AvailableBalance
-- Tables Accessed: Accounts
-- ============================================================================

CREATE OR ALTER PROCEDURE usp_GetAccountBalance
    @UserId INT,
    @Currency NVARCHAR(10) = 'USD'
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        UserId,
        Currency,
        ISNULL(AvailableBalance, 0.00) AS AvailableBalance
    FROM Accounts
    WHERE UserId = @UserId AND Currency = @Currency;
END;
