-- ============================================================================
-- Procedure: usp_UpdateWalletHolding
-- Purpose: Update quantity and average cost for an existing wallet holding
-- Inputs: @UserId, @Currency, @Quantity, @AverageCost
-- Tables Modified: Wallets
-- ============================================================================

CREATE OR ALTER PROCEDURE usp_UpdateWalletHolding
    @UserId INT,
    @Currency NVARCHAR(20),
    @Quantity DECIMAL(28, 8),
    @AverageCost DECIMAL(28, 8)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Wallets
    SET 
        Quantity = @Quantity,
        AverageCost = @AverageCost,
        UpdatedDate = SYSUTCDATETIME()
    WHERE UserId = @UserId AND Currency = @Currency;
END;

