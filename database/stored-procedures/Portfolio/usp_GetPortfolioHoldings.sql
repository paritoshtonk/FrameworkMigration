-- ============================================================================
-- Procedure: usp_GetPortfolioHoldings
-- Purpose: Retrieve cryptocurrency holdings with market metrics for a user
-- Inputs: @UserId
-- Tables/Views Accessed: vw_UserActiveHoldings
-- ============================================================================

CREATE OR ALTER PROCEDURE usp_GetPortfolioHoldings
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        WalletId,
        UserId,
        Symbol,
        Name,
        Quantity,
        AverageCost,
        CurrentPrice,
        CurrentValue,
        TotalCost,
        UnrealizedProfitLoss,
        UnrealizedProfitLossPercentage,
        UpdatedDate
    FROM vw_UserActiveHoldings
    WHERE UserId = @UserId
    ORDER BY CurrentValue DESC;
END;
