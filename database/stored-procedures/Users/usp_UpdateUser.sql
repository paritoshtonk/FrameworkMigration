-- ============================================================================
-- Procedure: usp_UpdateUser
-- Purpose: Update profile details for a user
-- Inputs: @UserId, @FirstName, @LastName, @Email
-- Tables Accessed: Users
-- Tables Modified: Users
-- ============================================================================

CREATE OR ALTER PROCEDURE usp_UpdateUser
    @UserId INT,
    @FirstName NVARCHAR(50),
    @LastName NVARCHAR(50),
    @Email NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM Users WHERE Email = @Email AND UserId <> @UserId)
    BEGIN
        RAISERROR('Email is already in use by another account.', 16, 1);
        RETURN;
    END

    UPDATE Users
    SET 
        FirstName = @FirstName,
        LastName = @LastName,
        Email = @Email
    WHERE UserId = @UserId;

    SELECT 
        UserId,
        Username,
        Email,
        FirstName,
        LastName,
        CreatedDate,
        LastLoginDate,
        IsActive
    FROM Users
    WHERE UserId = @UserId;
END;

