-- ============================================================================
-- Procedure: usp_CreateOrder
-- Purpose: Insert a new cryptocurrency order
-- Inputs: @UserId, @Symbol, @OrderType, @Side, @Quantity, @Price, @Status
-- Outputs: New OrderId
-- Tables Modified: Orders
-- ============================================================================

CREATE OR ALTER PROCEDURE usp_CreateOrder
    @UserId INT,
    @Symbol NVARCHAR(20),
    @OrderType NVARCHAR(20),
    @Side NVARCHAR(10),
    @Quantity DECIMAL(28, 8),
    @Price DECIMAL(28, 8),
    @Status NVARCHAR(20) = 'Pending',
    @OrderId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TotalValue DECIMAL(18, 2);
    SET @TotalValue = CAST(@Quantity * @Price AS DECIMAL(18, 2));

    INSERT INTO Orders (UserId, Symbol, OrderType, Side, Quantity, Price, TotalValue, Status, CreatedDate)
    VALUES (@UserId, @Symbol, @OrderType, @Side, @Quantity, @Price, @TotalValue, @Status, SYSUTCDATETIME());

    SET @OrderId = SCOPE_IDENTITY();
END;
