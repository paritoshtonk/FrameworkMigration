-- ============================================================================
-- Procedure: usp_GetUserByEmail
-- Purpose: Retrieve user record including PasswordHash by email
-- Inputs: @Email
-- Outputs: User record
-- Tables Accessed: Users
-- ============================================================================

CREATE OR ALTER PROCEDURE usp_GetUserByEmail
    @Email NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        UserId,
        Username,
        Email,
        PasswordHash,
        FirstName,
        LastName,
        CreatedDate,
        LastLoginDate,
        IsActive
    FROM Users
    WHERE Email = @Email;
END;

