-- ============================================================================
-- Procedure: usp_GetUserById
-- Purpose: Retrieve user profile information by UserId
-- Inputs: @UserId
-- Outputs: Single row user details
-- Tables Accessed: Users
-- ============================================================================

CREATE OR ALTER PROCEDURE usp_GetUserById
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;

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

