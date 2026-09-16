-- ============================================================================
-- Procedure: usp_CreateAccount
-- Purpose: Create an account for a user in a given currency (default USD)
-- Inputs: @UserId, @Currency, @InitialBalance
-- Tables Modified: Accounts
-- ============================================================================

CREATE OR ALTER PROCEDURE usp_CreateAccount
    @UserId INT,
    @Currency NVARCHAR(10) = 'USD',
    @InitialBalance DECIMAL(18, 2) = 0.00,
    @AccountId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM Accounts WHERE UserId = @UserId AND Currency = @Currency)
    BEGIN
        SELECT @AccountId = AccountId FROM Accounts WHERE UserId = @UserId AND Currency = @Currency;
        RETURN;
    END

    INSERT INTO Accounts (UserId, Currency, AvailableBalance, CreatedDate, UpdatedDate)
    VALUES (@UserId, @Currency, @InitialBalance, SYSUTCDATETIME(), SYSUTCDATETIME());

    SET @AccountId = SCOPE_IDENTITY();
END;
