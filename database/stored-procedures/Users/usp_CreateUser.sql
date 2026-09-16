-- ============================================================================
-- Procedure: usp_CreateUser
-- Purpose: Register a new user and automatically initialize their USD account
-- Inputs: @Username, @Email, @PasswordHash, @FirstName, @LastName
-- Outputs: New UserId
-- Tables Accessed: Users, Accounts
-- Tables Modified: Users, Accounts
-- Transaction: Atomic SQL Transaction
-- ============================================================================

CREATE OR ALTER PROCEDURE usp_CreateUser
    @Username NVARCHAR(50),
    @Email NVARCHAR(100),
    @PasswordHash NVARCHAR(256),
    @FirstName NVARCHAR(50),
    @LastName NVARCHAR(50),
    @NewUserId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF EXISTS (SELECT 1 FROM Users WHERE Username = @Username)
    BEGIN
        RAISERROR('Username already exists.', 16, 1);
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM Users WHERE Email = @Email)
    BEGIN
        RAISERROR('Email already exists.', 16, 2);
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO Users (Username, Email, PasswordHash, FirstName, LastName, CreatedDate, IsActive)
        VALUES (@Username, @Email, @PasswordHash, @FirstName, @LastName, SYSUTCDATETIME(), 1);

        SET @NewUserId = SCOPE_IDENTITY();

        -- Automatically create default USD account
        INSERT INTO Accounts (UserId, Currency, AvailableBalance, CreatedDate, UpdatedDate)
        VALUES (@NewUserId, 'USD', 0.00, SYSUTCDATETIME(), SYSUTCDATETIME());

        COMMIT TRANSACTION;

        SELECT 
            UserId, Username, Email, FirstName, LastName, CreatedDate, LastLoginDate, IsActive
        FROM Users
        WHERE UserId = @NewUserId;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
