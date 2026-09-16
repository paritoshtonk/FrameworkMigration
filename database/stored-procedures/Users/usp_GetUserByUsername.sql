-- ============================================================================
-- Procedure: usp_GetUserByUsername
-- Purpose: Retrieve user record including PasswordHash for authentication
-- Inputs: @Username
-- Outputs: User record
-- Tables Accessed: Users
-- ============================================================================

CREATE OR ALTER PROCEDURE usp_GetUserByUsername
    @Username NVARCHAR(50)
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
    WHERE Username = @Username;
END;

