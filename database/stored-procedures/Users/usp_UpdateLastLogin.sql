-- ============================================================================
-- Procedure: usp_UpdateLastLogin
-- Purpose: Record user successful login timestamp
-- Inputs: @UserId
-- Tables Modified: Users
-- ============================================================================

CREATE OR ALTER PROCEDURE usp_UpdateLastLogin
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Users
    SET LastLoginDate = SYSUTCDATETIME()
    WHERE UserId = @UserId;
END;
