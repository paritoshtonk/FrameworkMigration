-- ============================================================================
-- SeedData.sql
-- Demo seed data for Legacy Cryptocurrency Trading Platform
-- Passwords for demo users: Password123!
-- ============================================================================

SET NOCOUNT ON;

-- 1. Cryptocurrencies
MERGE Cryptocurrencies AS target
USING (VALUES 
    ('BTC', 'Bitcoin', 77000.00000000, 1.2500, 1),
    ('ETH', 'Ethereum', 2450.00000000, -0.4500, 1),
    ('SOL', 'Solana', 105.00000000, 3.1000, 1),
    ('ADA', 'Cardano', 0.35000000, -1.2000, 1),
    ('XRP', 'Ripple', 1.35000000, 0.8500, 1)
) AS source (Symbol, Name, CurrentPrice, PriceChange24h, IsActive)
ON target.Symbol = source.Symbol
WHEN MATCHED THEN 
    UPDATE SET 
        Name = source.Name,
        CurrentPrice = source.CurrentPrice,
        PriceChange24h = source.PriceChange24h,
        LastUpdated = SYSUTCDATETIME()
WHEN NOT MATCHED THEN 
    INSERT (Symbol, Name, CurrentPrice, PriceChange24h, LastUpdated, IsActive)
    VALUES (source.Symbol, source.Name, source.CurrentPrice, source.PriceChange24h, SYSUTCDATETIME(), source.IsActive);

-- 2. Seed Demo Users (Password: Password123!)
DECLARE @DemoPasswordHash NVARCHAR(256) = '10000:B5QPbABmmw2wq/DfKFSp1Q==:w0Esu/KZwurDjf6r9GEgTskcbFQLSwwunYI+3dZXRgY=';

IF NOT EXISTS (SELECT 1 FROM Users WHERE Username = 'trader1')
BEGIN
    INSERT INTO Users (Username, Email, PasswordHash, FirstName, LastName, CreatedDate, LastLoginDate, IsActive)
    VALUES ('trader1', 'trader1@cryptotrading.local', @DemoPasswordHash, 'Paritosh', 'Tonk', SYSUTCDATETIME(), SYSUTCDATETIME(), 1);
END

IF NOT EXISTS (SELECT 1 FROM Users WHERE Username = 'trader2')
BEGIN
    INSERT INTO Users (Username, Email, PasswordHash, FirstName, LastName, CreatedDate, LastLoginDate, IsActive)
    VALUES ('trader2', 'alice@cryptotrading.local', @DemoPasswordHash, 'Alice', 'Smith', SYSUTCDATETIME(), NULL, 1);
END

IF NOT EXISTS (SELECT 1 FROM Users WHERE Username = 'demo_trader')
BEGIN
    INSERT INTO Users (Username, Email, PasswordHash, FirstName, LastName, CreatedDate, LastLoginDate, IsActive)
    VALUES ('demo_trader', 'bob@cryptotrading.local', @DemoPasswordHash, 'Bob', 'Trader', SYSUTCDATETIME(), NULL, 1);
END

-- 3. Accounts
DECLARE @User1Id INT = (SELECT UserId FROM Users WHERE Username = 'trader1');
DECLARE @User2Id INT = (SELECT UserId FROM Users WHERE Username = 'trader2');
DECLARE @DemoUserId INT = (SELECT UserId FROM Users WHERE Username = 'demo_trader');

IF NOT EXISTS (SELECT 1 FROM Accounts WHERE UserId = @User1Id AND Currency = 'USD')
    INSERT INTO Accounts (UserId, Currency, AvailableBalance, CreatedDate, UpdatedDate)
    VALUES (@User1Id, 'USD', 15400.00, SYSUTCDATETIME(), SYSUTCDATETIME());

IF NOT EXISTS (SELECT 1 FROM Accounts WHERE UserId = @User2Id AND Currency = 'USD')
    INSERT INTO Accounts (UserId, Currency, AvailableBalance, CreatedDate, UpdatedDate)
    VALUES (@User2Id, 'USD', 8250.00, SYSUTCDATETIME(), SYSUTCDATETIME());

IF NOT EXISTS (SELECT 1 FROM Accounts WHERE UserId = @DemoUserId AND Currency = 'USD')
    INSERT INTO Accounts (UserId, Currency, AvailableBalance, CreatedDate, UpdatedDate)
    VALUES (@DemoUserId, 'USD', 10000.00, SYSUTCDATETIME(), SYSUTCDATETIME());

-- 4. Initial Wallets for trader1
IF NOT EXISTS (SELECT 1 FROM Wallets WHERE UserId = @User1Id AND Currency = 'BTC')
    INSERT INTO Wallets (UserId, Currency, Quantity, AverageCost, CreatedDate, UpdatedDate)
    VALUES (@User1Id, 'BTC', 0.15000000, 65000.00000000, SYSUTCDATETIME(), SYSUTCDATETIME());

IF NOT EXISTS (SELECT 1 FROM Wallets WHERE UserId = @User1Id AND Currency = 'ETH')
    INSERT INTO Wallets (UserId, Currency, Quantity, AverageCost, CreatedDate, UpdatedDate)
    VALUES (@User1Id, 'ETH', 2.00000000, 2200.00000000, SYSUTCDATETIME(), SYSUTCDATETIME());

IF NOT EXISTS (SELECT 1 FROM Wallets WHERE UserId = @User1Id AND Currency = 'SOL')
    INSERT INTO Wallets (UserId, Currency, Quantity, AverageCost, CreatedDate, UpdatedDate)
    VALUES (@User1Id, 'SOL', 25.00000000, 90.00000000, SYSUTCDATETIME(), SYSUTCDATETIME());

-- Wallets for trader2
IF NOT EXISTS (SELECT 1 FROM Wallets WHERE UserId = @User2Id AND Currency = 'ETH')
    INSERT INTO Wallets (UserId, Currency, Quantity, AverageCost, CreatedDate, UpdatedDate)
    VALUES (@User2Id, 'ETH', 1.50000000, 2300.00000000, SYSUTCDATETIME(), SYSUTCDATETIME());

IF NOT EXISTS (SELECT 1 FROM Wallets WHERE UserId = @User2Id AND Currency = 'ADA')
    INSERT INTO Wallets (UserId, Currency, Quantity, AverageCost, CreatedDate, UpdatedDate)
    VALUES (@User2Id, 'ADA', 1000.00000000, 0.32000000, SYSUTCDATETIME(), SYSUTCDATETIME());

-- 5. Sample Financial Ledger & Transactions for trader1
IF NOT EXISTS (SELECT 1 FROM Deposits WHERE UserId = @User1Id)
BEGIN
    INSERT INTO Deposits (UserId, Amount, Currency, Status, CreatedDate, ProcessedDate)
    VALUES (@User1Id, 25000.00, 'USD', 'COMPLETED', DATEADD(DAY, -10, SYSUTCDATETIME()), DATEADD(DAY, -10, SYSUTCDATETIME()));

    DECLARE @Dep1Id INT = SCOPE_IDENTITY();

    INSERT INTO Transactions (UserId, TransactionType, Currency, Amount, ReferenceId, Status, CreatedDate)
    VALUES (@User1Id, 'DEPOSIT', 'USD', 25000.00, CAST(@Dep1Id AS NVARCHAR(100)), 'COMPLETED', DATEADD(DAY, -10, SYSUTCDATETIME()));
END

IF NOT EXISTS (SELECT 1 FROM Withdrawals WHERE UserId = @User1Id)
BEGIN
    INSERT INTO Withdrawals (UserId, Amount, Currency, Status, CreatedDate, ProcessedDate)
    VALUES (@User1Id, 2000.00, 'USD', 'COMPLETED', DATEADD(DAY, -2, SYSUTCDATETIME()), DATEADD(DAY, -2, SYSUTCDATETIME()));

    DECLARE @With1Id INT = SCOPE_IDENTITY();

    INSERT INTO Transactions (UserId, TransactionType, Currency, Amount, ReferenceId, Status, CreatedDate)
    VALUES (@User1Id, 'WITHDRAWAL', 'USD', 2000.00, CAST(@With1Id AS NVARCHAR(100)), 'COMPLETED', DATEADD(DAY, -2, SYSUTCDATETIME()));
END

-- 6. Sample Orders & Trades for trader1
IF NOT EXISTS (SELECT 1 FROM Orders WHERE UserId = @User1Id)
BEGIN
    -- Historical Buy BTC
    INSERT INTO Orders (UserId, Symbol, OrderType, Side, Quantity, Price, TotalValue, Status, CreatedDate, ExecutedDate)
    VALUES (@User1Id, 'BTC', 'Market', 'BUY', 0.20000000, 65000.00000000, 13000.00, 'Executed', DATEADD(DAY, -8, SYSUTCDATETIME()), DATEADD(DAY, -8, SYSUTCDATETIME()));
    DECLARE @Ord1Id INT = SCOPE_IDENTITY();

    INSERT INTO Trades (OrderId, UserId, Symbol, Side, Quantity, ExecutionPrice, TotalValue, RealizedProfitLoss, ExecutedDate)
    VALUES (@Ord1Id, @User1Id, 'BTC', 'BUY', 0.20000000, 65000.00000000, 13000.00, 0.00, DATEADD(DAY, -8, SYSUTCDATETIME()));
    DECLARE @Trd1Id INT = SCOPE_IDENTITY();

    INSERT INTO Transactions (UserId, TransactionType, Currency, Amount, ReferenceId, Status, CreatedDate)
    VALUES (@User1Id, 'BUY', 'USD', 13000.00, CAST(@Trd1Id AS NVARCHAR(100)), 'COMPLETED', DATEADD(DAY, -8, SYSUTCDATETIME()));

    -- Partial Sell BTC at profit
    INSERT INTO Orders (UserId, Symbol, OrderType, Side, Quantity, Price, TotalValue, Status, CreatedDate, ExecutedDate)
    VALUES (@User1Id, 'BTC', 'Market', 'SELL', 0.05000000, 72000.00000000, 3600.00, 'Executed', DATEADD(DAY, -4, SYSUTCDATETIME()), DATEADD(DAY, -4, SYSUTCDATETIME()));
    DECLARE @Ord2Id INT = SCOPE_IDENTITY();

    INSERT INTO Trades (OrderId, UserId, Symbol, Side, Quantity, ExecutionPrice, TotalValue, RealizedProfitLoss, ExecutedDate)
    VALUES (@Ord2Id, @User1Id, 'BTC', 'SELL', 0.05000000, 72000.00000000, 3600.00, 350.00, DATEADD(DAY, -4, SYSUTCDATETIME()));
    DECLARE @Trd2Id INT = SCOPE_IDENTITY();

    INSERT INTO Transactions (UserId, TransactionType, Currency, Amount, ReferenceId, Status, CreatedDate)
    VALUES (@User1Id, 'SELL', 'USD', 3600.00, CAST(@Trd2Id AS NVARCHAR(100)), 'COMPLETED', DATEADD(DAY, -4, SYSUTCDATETIME()));
END
