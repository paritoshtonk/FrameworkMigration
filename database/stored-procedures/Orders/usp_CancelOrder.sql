-- ============================================================================
-- Procedure: usp_CancelOrder
-- Purpose: Cancel an eligible pending order
-- Inputs: @OrderId, @UserId
-- Validations:
--   - Order must exist
--   - Order must belong to the requesting user
--   - Order must be in 'Pending' status (cannot cancel 'Executed' order)
-- Tables Modified: Orders
-- ============================================================================

CREATE OR ALTER PROCEDURE usp_CancelOrder
    @OrderId INT,
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @CurrentStatus NVARCHAR(20);
    DECLARE @OrderUserId INT;

    SELECT 
        @CurrentStatus = Status,
        @OrderUserId = UserId
    FROM Orders
    WHERE OrderId = @OrderId;

    IF @OrderUserId IS NULL
    BEGIN
        RAISERROR('Order not found.', 16, 1);
        RETURN;
    END

    IF @OrderUserId <> @UserId
    BEGIN
        RAISERROR('Unauthorized. You do not own this order.', 16, 2);
        RETURN;
    END

    IF @CurrentStatus = 'Executed'
    BEGIN
        RAISERROR('Cannot cancel an executed order.', 16, 3);
        RETURN;
    END

    IF @CurrentStatus = 'Cancelled'
    BEGIN
        RAISERROR('Order is already cancelled.', 16, 4);
        RETURN;
    END

    IF @CurrentStatus <> 'Pending'
    BEGIN
        RAISERROR('Order cannot be cancelled in its current state.', 16, 5);
        RETURN;
    END

    UPDATE Orders
    SET 
        Status = 'Cancelled',
        ExecutedDate = SYSUTCDATETIME()
    WHERE OrderId = @OrderId;

    SELECT 
        OrderId,
        UserId,
        Symbol,
        OrderType,
        Side,
        Quantity,
        Price,
        TotalValue,
        Status,
        CreatedDate,
        ExecutedDate
    FROM Orders
    WHERE OrderId = @OrderId;
END;
