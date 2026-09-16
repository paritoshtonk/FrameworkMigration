-- ============================================================================
-- Procedure: usp_UpdateOrderStatus
-- Purpose: Update the status of an existing order
-- Inputs: @OrderId, @Status, @ExecutedDate
-- Tables Modified: Orders
-- ============================================================================

CREATE OR ALTER PROCEDURE usp_UpdateOrderStatus
    @OrderId INT,
    @Status NVARCHAR(20),
    @ExecutedDate DATETIME2(7) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Orders
    SET 
        Status = @Status,
        ExecutedDate = CASE WHEN @Status = 'Executed' AND @ExecutedDate IS NULL THEN SYSUTCDATETIME() ELSE @ExecutedDate END
    WHERE OrderId = @OrderId;
END;
