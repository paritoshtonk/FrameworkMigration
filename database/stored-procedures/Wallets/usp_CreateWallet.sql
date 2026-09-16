-- ============================================================================
-- Procedure: usp_CreateWallet
-- Purpose: Create a new wallet holding record for a user
-- Inputs: @UserId, @Currency, @InitialQuantity, @AverageCost
-- Tables Modified: Wallets
-- ============================================================================

CREATE OR ALTER PROCEDURE usp_CreateWallet
    @UserId INT,
    @Currency NVARCHAR(20),
    @InitialQuantity DECIMAL(28, 8) = 0.00000000,
    @AverageCost DECIMAL(28, 8) = 0.00000000,
    @WalletId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM Wallets WHERE UserId = @UserId AND Currency = @Currency)
    BEGIN
        SELECT @WalletId = WalletId FROM Wallets WHERE UserId = @UserId AND Currency = @Currency;
        RETURN;
    END

    INSERT INTO Wallets (UserId, Currency, Quantity, AverageCost, CreatedDate, UpdatedDate)
    VALUES (@UserId, @Currency, @InitialQuantity, @AverageCost, SYSUTCDATETIME(), SYSUTCDATETIME());

    SET @WalletId = SCOPE_IDENTITY();
END;

