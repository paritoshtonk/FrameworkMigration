-- ============================================================================
-- 01_Tables.sql
-- CryptoTradingPlatform - Database Table Definitions
-- Target: Microsoft SQL Server
-- ============================================================================

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Users')
BEGIN
    CREATE TABLE Users (
        UserId INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        Username NVARCHAR(50) NOT NULL,
        Email NVARCHAR(100) NOT NULL,
        PasswordHash NVARCHAR(256) NOT NULL,
        FirstName NVARCHAR(50) NOT NULL,
        LastName NVARCHAR(50) NOT NULL,
        CreatedDate DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
        LastLoginDate DATETIME2(7) NULL,
        IsActive BIT NOT NULL DEFAULT 1
    );
END;

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Accounts')
BEGIN
    CREATE TABLE Accounts (
        AccountId INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        UserId INT NOT NULL,
        Currency NVARCHAR(10) NOT NULL DEFAULT 'USD',
        AvailableBalance DECIMAL(18, 2) NOT NULL DEFAULT 0.00,
        CreatedDate DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedDate DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME()
    );
END;

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Cryptocurrencies')
BEGIN
    CREATE TABLE Cryptocurrencies (
        CryptocurrencyId INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        Symbol NVARCHAR(20) NOT NULL,
        Name NVARCHAR(100) NOT NULL,
        CurrentPrice DECIMAL(28, 8) NOT NULL DEFAULT 0.00000000,
        PriceChange24h DECIMAL(18, 4) NOT NULL DEFAULT 0.0000,
        LastUpdated DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
        IsActive BIT NOT NULL DEFAULT 1
    );
END;

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Wallets')
BEGIN
    CREATE TABLE Wallets (
        WalletId INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        UserId INT NOT NULL,
        Currency NVARCHAR(20) NOT NULL,
        Quantity DECIMAL(28, 8) NOT NULL DEFAULT 0.00000000,
        AverageCost DECIMAL(28, 8) NOT NULL DEFAULT 0.00000000,
        CreatedDate DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedDate DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME()
    );
END;

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Orders')
BEGIN
    CREATE TABLE Orders (
        OrderId INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        UserId INT NOT NULL,
        Symbol NVARCHAR(20) NOT NULL,
        OrderType NVARCHAR(20) NOT NULL, -- 'Market', 'Limit'
        Side NVARCHAR(10) NOT NULL,      -- 'BUY', 'SELL'
        Quantity DECIMAL(28, 8) NOT NULL,
        Price DECIMAL(28, 8) NOT NULL,
        TotalValue DECIMAL(18, 2) NOT NULL,
        Status NVARCHAR(20) NOT NULL,    -- 'Pending', 'Executed', 'Cancelled', 'Rejected'
        CreatedDate DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
        ExecutedDate DATETIME2(7) NULL
    );
END;

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Trades')
BEGIN
    CREATE TABLE Trades (
        TradeId INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        OrderId INT NOT NULL,
        UserId INT NOT NULL,
        Symbol NVARCHAR(20) NOT NULL,
        Side NVARCHAR(10) NOT NULL,      -- 'BUY', 'SELL'
        Quantity DECIMAL(28, 8) NOT NULL,
        ExecutionPrice DECIMAL(28, 8) NOT NULL,
        TotalValue DECIMAL(18, 2) NOT NULL,
        RealizedProfitLoss DECIMAL(18, 2) NOT NULL DEFAULT 0.00,
        ExecutedDate DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME()
    );
END;

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Transactions')
BEGIN
    CREATE TABLE Transactions (
        TransactionId INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        UserId INT NOT NULL,
        TransactionType NVARCHAR(20) NOT NULL, -- 'BUY', 'SELL', 'DEPOSIT', 'WITHDRAWAL'
        Currency NVARCHAR(20) NOT NULL,        -- 'USD', 'BTC', etc.
        Amount DECIMAL(18, 2) NOT NULL,
        ReferenceId NVARCHAR(100) NULL,
        Status NVARCHAR(20) NOT NULL DEFAULT 'COMPLETED',
        CreatedDate DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME()
    );
END;

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Deposits')
BEGIN
    CREATE TABLE Deposits (
        DepositId INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        UserId INT NOT NULL,
        Amount DECIMAL(18, 2) NOT NULL,
        Currency NVARCHAR(10) NOT NULL DEFAULT 'USD',
        Status NVARCHAR(20) NOT NULL DEFAULT 'COMPLETED',
        CreatedDate DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
        ProcessedDate DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME()
    );
END;

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Withdrawals')
BEGIN
    CREATE TABLE Withdrawals (
        WithdrawalId INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        UserId INT NOT NULL,
        Amount DECIMAL(18, 2) NOT NULL,
        Currency NVARCHAR(10) NOT NULL DEFAULT 'USD',
        Status NVARCHAR(20) NOT NULL DEFAULT 'COMPLETED',
        CreatedDate DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
        ProcessedDate DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME()
    );
END;

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PriceHistory')
BEGIN
    CREATE TABLE PriceHistory (
        PriceHistoryId INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        CryptocurrencyId INT NOT NULL,
        Price DECIMAL(28, 8) NOT NULL,
        RecordedDate DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME()
    );
END;
