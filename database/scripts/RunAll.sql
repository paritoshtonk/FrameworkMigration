-- ============================================================================
-- RunAll.sql
-- Master idempotent database creation & initialization script
-- Usage: sqlcmd -S "(localdb)\CryptoTradingDB" -i RunAll.sql
-- ============================================================================

IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'CryptoTradingDB')
BEGIN
    CREATE DATABASE CryptoTradingDB;
END
GO

USE CryptoTradingDB;
GO

PRINT '==============================================';
PRINT 'Initializing CryptoTrading Platform Database';
PRINT '==============================================';
GO

-- 1. Schema Migrations Journal Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = '__SchemaMigrations')
BEGIN
    CREATE TABLE __SchemaMigrations (
        MigrationId INT IDENTITY(1,1) PRIMARY KEY,
        ScriptFileName NVARCHAR(260) NOT NULL UNIQUE,
        AppliedDate DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME()
    );
END
GO

PRINT 'Step 1: Creating Tables...';
GO

-- 01_Tables
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
END
GO

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
END
GO

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
END
GO

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
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Orders')
BEGIN
    CREATE TABLE Orders (
        OrderId INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        UserId INT NOT NULL,
        Symbol NVARCHAR(20) NOT NULL,
        OrderType NVARCHAR(20) NOT NULL,
        Side NVARCHAR(10) NOT NULL,
        Quantity DECIMAL(28, 8) NOT NULL,
        Price DECIMAL(28, 8) NOT NULL,
        TotalValue DECIMAL(18, 2) NOT NULL,
        Status NVARCHAR(20) NOT NULL,
        CreatedDate DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
        ExecutedDate DATETIME2(7) NULL
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Trades')
BEGIN
    CREATE TABLE Trades (
        TradeId INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        OrderId INT NOT NULL,
        UserId INT NOT NULL,
        Symbol NVARCHAR(20) NOT NULL,
        Side NVARCHAR(10) NOT NULL,
        Quantity DECIMAL(28, 8) NOT NULL,
        ExecutionPrice DECIMAL(28, 8) NOT NULL,
        TotalValue DECIMAL(18, 2) NOT NULL,
        RealizedProfitLoss DECIMAL(18, 2) NOT NULL DEFAULT 0.00,
        ExecutedDate DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME()
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Transactions')
BEGIN
    CREATE TABLE Transactions (
        TransactionId INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        UserId INT NOT NULL,
        TransactionType NVARCHAR(20) NOT NULL,
        Currency NVARCHAR(20) NOT NULL,
        Amount DECIMAL(18, 2) NOT NULL,
        ReferenceId NVARCHAR(100) NULL,
        Status NVARCHAR(20) NOT NULL DEFAULT 'COMPLETED',
        CreatedDate DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME()
    );
END
GO

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
END
GO

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
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PriceHistory')
BEGIN
    CREATE TABLE PriceHistory (
        PriceHistoryId INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        CryptocurrencyId INT NOT NULL,
        Price DECIMAL(28, 8) NOT NULL,
        RecordedDate DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME()
    );
END
GO

PRINT 'Step 2: Creating Constraints & Foreign Keys...';
GO

IF NOT EXISTS (SELECT * FROM sys.key_constraints WHERE name = 'UQ_Users_Username')
    ALTER TABLE Users ADD CONSTRAINT UQ_Users_Username UNIQUE (Username);
GO

IF NOT EXISTS (SELECT * FROM sys.key_constraints WHERE name = 'UQ_Users_Email')
    ALTER TABLE Users ADD CONSTRAINT UQ_Users_Email UNIQUE (Email);
GO

IF NOT EXISTS (SELECT * FROM sys.key_constraints WHERE name = 'UQ_Cryptocurrencies_Symbol')
    ALTER TABLE Cryptocurrencies ADD CONSTRAINT UQ_Cryptocurrencies_Symbol UNIQUE (Symbol);
GO

IF NOT EXISTS (SELECT * FROM sys.key_constraints WHERE name = 'UQ_Wallets_User_Currency')
    ALTER TABLE Wallets ADD CONSTRAINT UQ_Wallets_User_Currency UNIQUE (UserId, Currency);
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Accounts_Users')
    ALTER TABLE Accounts ADD CONSTRAINT FK_Accounts_Users FOREIGN KEY (UserId) REFERENCES Users(UserId);
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Wallets_Users')
    ALTER TABLE Wallets ADD CONSTRAINT FK_Wallets_Users FOREIGN KEY (UserId) REFERENCES Users(UserId);
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Orders_Users')
    ALTER TABLE Orders ADD CONSTRAINT FK_Orders_Users FOREIGN KEY (UserId) REFERENCES Users(UserId);
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Trades_Orders')
    ALTER TABLE Trades ADD CONSTRAINT FK_Trades_Orders FOREIGN KEY (OrderId) REFERENCES Orders(OrderId);
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Trades_Users')
    ALTER TABLE Trades ADD CONSTRAINT FK_Trades_Users FOREIGN KEY (UserId) REFERENCES Users(UserId);
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Transactions_Users')
    ALTER TABLE Transactions ADD CONSTRAINT FK_Transactions_Users FOREIGN KEY (UserId) REFERENCES Users(UserId);
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Deposits_Users')
    ALTER TABLE Deposits ADD CONSTRAINT FK_Deposits_Users FOREIGN KEY (UserId) REFERENCES Users(UserId);
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Withdrawals_Users')
    ALTER TABLE Withdrawals ADD CONSTRAINT FK_Withdrawals_Users FOREIGN KEY (UserId) REFERENCES Users(UserId);
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_PriceHistory_Cryptocurrencies')
    ALTER TABLE PriceHistory ADD CONSTRAINT FK_PriceHistory_Cryptocurrencies FOREIGN KEY (CryptocurrencyId) REFERENCES Cryptocurrencies(CryptocurrencyId);
GO

IF NOT EXISTS (SELECT * FROM sys.check_constraints WHERE name = 'CK_Accounts_AvailableBalance')
    ALTER TABLE Accounts ADD CONSTRAINT CK_Accounts_AvailableBalance CHECK (AvailableBalance >= 0);
GO

IF NOT EXISTS (SELECT * FROM sys.check_constraints WHERE name = 'CK_Wallets_Quantity')
    ALTER TABLE Wallets ADD CONSTRAINT CK_Wallets_Quantity CHECK (Quantity >= 0);
GO

IF NOT EXISTS (SELECT * FROM sys.check_constraints WHERE name = 'CK_Wallets_AverageCost')
    ALTER TABLE Wallets ADD CONSTRAINT CK_Wallets_AverageCost CHECK (AverageCost >= 0);
GO

IF NOT EXISTS (SELECT * FROM sys.check_constraints WHERE name = 'CK_Orders_Quantity')
    ALTER TABLE Orders ADD CONSTRAINT CK_Orders_Quantity CHECK (Quantity > 0);
GO

IF NOT EXISTS (SELECT * FROM sys.check_constraints WHERE name = 'CK_Trades_Quantity')
    ALTER TABLE Trades ADD CONSTRAINT CK_Trades_Quantity CHECK (Quantity > 0);
GO

IF NOT EXISTS (SELECT * FROM sys.check_constraints WHERE name = 'CK_Deposits_Amount')
    ALTER TABLE Deposits ADD CONSTRAINT CK_Deposits_Amount CHECK (Amount > 0);
GO

IF NOT EXISTS (SELECT * FROM sys.check_constraints WHERE name = 'CK_Withdrawals_Amount')
    ALTER TABLE Withdrawals ADD CONSTRAINT CK_Withdrawals_Amount CHECK (Amount > 0);
GO

PRINT 'Step 3: Creating Indexes...';
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Orders_UserId_Status')
    CREATE NONCLUSTERED INDEX IX_Orders_UserId_Status ON Orders (UserId, Status) INCLUDE (Symbol, Side, Quantity, Price, TotalValue, CreatedDate);
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Trades_UserId_ExecutedDate')
    CREATE NONCLUSTERED INDEX IX_Trades_UserId_ExecutedDate ON Trades (UserId, ExecutedDate DESC) INCLUDE (Symbol, Side, Quantity, ExecutionPrice, TotalValue, RealizedProfitLoss);
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Transactions_UserId_CreatedDate')
    CREATE NONCLUSTERED INDEX IX_Transactions_UserId_CreatedDate ON Transactions (UserId, CreatedDate DESC) INCLUDE (TransactionType, Currency, Amount, ReferenceId, Status);
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Wallets_UserId')
    CREATE NONCLUSTERED INDEX IX_Wallets_UserId ON Wallets (UserId) INCLUDE (Currency, Quantity, AverageCost);
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Deposits_UserId_CreatedDate')
    CREATE NONCLUSTERED INDEX IX_Deposits_UserId_CreatedDate ON Deposits (UserId, CreatedDate DESC);
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Withdrawals_UserId_CreatedDate')
    CREATE NONCLUSTERED INDEX IX_Withdrawals_UserId_CreatedDate ON Withdrawals (UserId, CreatedDate DESC);
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_PriceHistory_CryptocurrencyId_RecordedDate')
    CREATE NONCLUSTERED INDEX IX_PriceHistory_CryptocurrencyId_RecordedDate ON PriceHistory (CryptocurrencyId, RecordedDate DESC);
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Cryptocurrencies_Symbol')
    CREATE NONCLUSTERED INDEX IX_Cryptocurrencies_Symbol ON Cryptocurrencies (Symbol) INCLUDE (Name, CurrentPrice, PriceChange24h, LastUpdated, IsActive);
GO

PRINT 'Step 4: Creating Views...';
GO

CREATE OR ALTER VIEW vw_UserActiveHoldings AS
SELECT 
    w.WalletId,
    w.UserId,
    w.Currency AS Symbol,
    c.Name,
    w.Quantity,
    w.AverageCost,
    ISNULL(c.CurrentPrice, 0) AS CurrentPrice,
    CAST(w.Quantity * ISNULL(c.CurrentPrice, 0) AS DECIMAL(18,2)) AS CurrentValue,
    CAST(w.Quantity * w.AverageCost AS DECIMAL(18,2)) AS TotalCost,
    CAST((w.Quantity * ISNULL(c.CurrentPrice, 0)) - (w.Quantity * w.AverageCost) AS DECIMAL(18,2)) AS UnrealizedProfitLoss,
    CASE 
        WHEN (w.Quantity * w.AverageCost) > 0 
        THEN CAST((((w.Quantity * ISNULL(c.CurrentPrice, 0)) - (w.Quantity * w.AverageCost)) / (w.Quantity * w.AverageCost)) * 100.0 AS DECIMAL(18,2))
        ELSE 0.00 
    END AS UnrealizedProfitLossPercentage,
    w.UpdatedDate
FROM Wallets w
LEFT JOIN Cryptocurrencies c ON w.Currency = c.Symbol
WHERE w.Quantity > 0;
GO

CREATE OR ALTER VIEW vw_UserPortfolioSummary AS
SELECT 
    u.UserId,
    u.Username,
    ISNULL(a.AvailableBalance, 0) AS CashBalance,
    ISNULL(h.InvestedCost, 0) AS InvestedValue,
    ISNULL(h.TotalMarketValue, 0) AS HoldingsMarketValue,
    CAST(ISNULL(a.AvailableBalance, 0) + ISNULL(h.TotalMarketValue, 0) AS DECIMAL(18,2)) AS TotalPortfolioValue,
    ISNULL(h.TotalUnrealizedPL, 0) AS UnrealizedProfitLoss,
    ISNULL(t.TotalRealizedPL, 0) AS RealizedProfitLoss,
    CAST(ISNULL(h.TotalUnrealizedPL, 0) + ISNULL(t.TotalRealizedPL, 0) AS DECIMAL(18,2)) AS TotalProfitLoss
FROM Users u
LEFT JOIN Accounts a ON u.UserId = a.UserId AND a.Currency = 'USD'
LEFT JOIN (
    SELECT 
        UserId,
        SUM(TotalCost) AS InvestedCost,
        SUM(CurrentValue) AS TotalMarketValue,
        SUM(UnrealizedProfitLoss) AS TotalUnrealizedPL
    FROM vw_UserActiveHoldings
    GROUP BY UserId
) h ON u.UserId = h.UserId
LEFT JOIN (
    SELECT 
        UserId,
        SUM(RealizedProfitLoss) AS TotalRealizedPL
    FROM Trades
    GROUP BY UserId
) t ON u.UserId = t.UserId;
GO

PRINT 'Step 5: Creating Stored Procedures...';
GO

-- Users
CREATE OR ALTER PROCEDURE usp_CreateUser
    @Username NVARCHAR(50),
    @Email NVARCHAR(100),
    @PasswordHash NVARCHAR(256),
    @FirstName NVARCHAR(50),
    @LastName NVARCHAR(50),
    @NewUserId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF EXISTS (SELECT 1 FROM Users WHERE Username = @Username)
    BEGIN
        RAISERROR('Username already exists.', 16, 1);
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM Users WHERE Email = @Email)
    BEGIN
        RAISERROR('Email already exists.', 16, 2);
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO Users (Username, Email, PasswordHash, FirstName, LastName, CreatedDate, IsActive)
        VALUES (@Username, @Email, @PasswordHash, @FirstName, @LastName, SYSUTCDATETIME(), 1);

        SET @NewUserId = SCOPE_IDENTITY();

        INSERT INTO Accounts (UserId, Currency, AvailableBalance, CreatedDate, UpdatedDate)
        VALUES (@NewUserId, 'USD', 0.00, SYSUTCDATETIME(), SYSUTCDATETIME());

        COMMIT TRANSACTION;

        SELECT 
            UserId, Username, Email, FirstName, LastName, CreatedDate, LastLoginDate, IsActive
        FROM Users
        WHERE UserId = @NewUserId;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE usp_GetUserById
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT UserId, Username, Email, FirstName, LastName, CreatedDate, LastLoginDate, IsActive
    FROM Users WHERE UserId = @UserId;
END;
GO

CREATE OR ALTER PROCEDURE usp_GetUserByUsername
    @Username NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT UserId, Username, Email, PasswordHash, FirstName, LastName, CreatedDate, LastLoginDate, IsActive
    FROM Users WHERE Username = @Username;
END;
GO

CREATE OR ALTER PROCEDURE usp_GetUserByEmail
    @Email NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT UserId, Username, Email, PasswordHash, FirstName, LastName, CreatedDate, LastLoginDate, IsActive
    FROM Users WHERE Email = @Email;
END;
GO

CREATE OR ALTER PROCEDURE usp_UpdateUser
    @UserId INT,
    @FirstName NVARCHAR(50),
    @LastName NVARCHAR(50),
    @Email NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM Users WHERE Email = @Email AND UserId <> @UserId)
    BEGIN
        RAISERROR('Email is already in use by another account.', 16, 1);
        RETURN;
    END

    UPDATE Users
    SET FirstName = @FirstName, LastName = @LastName, Email = @Email
    WHERE UserId = @UserId;

    SELECT UserId, Username, Email, FirstName, LastName, CreatedDate, LastLoginDate, IsActive
    FROM Users WHERE UserId = @UserId;
END;
GO

CREATE OR ALTER PROCEDURE usp_UpdateLastLogin
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Users SET LastLoginDate = SYSUTCDATETIME() WHERE UserId = @UserId;
END;
GO

-- Accounts
CREATE OR ALTER PROCEDURE usp_CreateAccount
    @UserId INT,
    @Currency NVARCHAR(10) = 'USD',
    @InitialBalance DECIMAL(18, 2) = 0.00,
    @AccountId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM Accounts WHERE UserId = @UserId AND Currency = @Currency)
    BEGIN
        SELECT @AccountId = AccountId FROM Accounts WHERE UserId = @UserId AND Currency = @Currency;
        RETURN;
    END

    INSERT INTO Accounts (UserId, Currency, AvailableBalance, CreatedDate, UpdatedDate)
    VALUES (@UserId, @Currency, @InitialBalance, SYSUTCDATETIME(), SYSUTCDATETIME());

    SET @AccountId = SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE usp_GetAccount
    @UserId INT,
    @Currency NVARCHAR(10) = 'USD'
AS
BEGIN
    SET NOCOUNT ON;
    SELECT AccountId, UserId, Currency, AvailableBalance, CreatedDate, UpdatedDate
    FROM Accounts WHERE UserId = @UserId AND Currency = @Currency;
END;
GO

CREATE OR ALTER PROCEDURE usp_GetAccountBalance
    @UserId INT,
    @Currency NVARCHAR(10) = 'USD'
AS
BEGIN
    SET NOCOUNT ON;
    SELECT UserId, Currency, ISNULL(AvailableBalance, 0.00) AS AvailableBalance
    FROM Accounts WHERE UserId = @UserId AND Currency = @Currency;
END;
GO

-- Cryptocurrencies
CREATE OR ALTER PROCEDURE usp_GetCryptocurrencies
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CryptocurrencyId, Symbol, Name, CurrentPrice, PriceChange24h, LastUpdated, IsActive
    FROM Cryptocurrencies WHERE IsActive = 1 ORDER BY CryptocurrencyId ASC;
END;
GO

CREATE OR ALTER PROCEDURE usp_GetCryptocurrencyBySymbol
    @Symbol NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CryptocurrencyId, Symbol, Name, CurrentPrice, PriceChange24h, LastUpdated, IsActive
    FROM Cryptocurrencies WHERE Symbol = @Symbol;
END;
GO

CREATE OR ALTER PROCEDURE usp_SaveCryptoPrice
    @Symbol NVARCHAR(20),
    @Price DECIMAL(28, 8),
    @PriceChange24h DECIMAL(18, 4) = 0.0000
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @CryptoId INT;
    SELECT @CryptoId = CryptocurrencyId FROM Cryptocurrencies WHERE Symbol = @Symbol;

    IF @CryptoId IS NULL
    BEGIN
        RAISERROR('Cryptocurrency symbol not recognized.', 16, 1);
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE Cryptocurrencies
        SET CurrentPrice = @Price, PriceChange24h = @PriceChange24h, LastUpdated = SYSUTCDATETIME()
        WHERE CryptocurrencyId = @CryptoId;

        INSERT INTO PriceHistory (CryptocurrencyId, Price, RecordedDate)
        VALUES (@CryptoId, @Price, SYSUTCDATETIME());
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE usp_GetLatestCryptoPrice
    @Symbol NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT Symbol, CurrentPrice, PriceChange24h, LastUpdated
    FROM Cryptocurrencies WHERE Symbol = @Symbol;
END;
GO

CREATE OR ALTER PROCEDURE usp_GetCryptoPriceHistory
    @Symbol NVARCHAR(20),
    @Limit INT = 100
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (@Limit) ph.PriceHistoryId, c.Symbol, ph.Price, ph.RecordedDate
    FROM PriceHistory ph
    INNER JOIN Cryptocurrencies c ON ph.CryptocurrencyId = c.CryptocurrencyId
    WHERE c.Symbol = @Symbol
    ORDER BY ph.RecordedDate DESC;
END;
GO

-- Wallets
CREATE OR ALTER PROCEDURE usp_GetWallets
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT w.WalletId, w.UserId, w.Currency, c.Name AS CurrencyName, w.Quantity, w.AverageCost, w.CreatedDate, w.UpdatedDate
    FROM Wallets w
    LEFT JOIN Cryptocurrencies c ON w.Currency = c.Symbol
    WHERE w.UserId = @UserId AND w.Quantity > 0
    ORDER BY w.Currency ASC;
END;
GO

CREATE OR ALTER PROCEDURE usp_GetWalletHolding
    @UserId INT,
    @Currency NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT w.WalletId, w.UserId, w.Currency, c.Name AS CurrencyName, w.Quantity, w.AverageCost, w.CreatedDate, w.UpdatedDate
    FROM Wallets w
    LEFT JOIN Cryptocurrencies c ON w.Currency = c.Symbol
    WHERE w.UserId = @UserId AND w.Currency = @Currency;
END;
GO

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
GO

CREATE OR ALTER PROCEDURE usp_UpdateWalletHolding
    @UserId INT,
    @Currency NVARCHAR(20),
    @Quantity DECIMAL(28, 8),
    @AverageCost DECIMAL(28, 8)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Wallets
    SET Quantity = @Quantity, AverageCost = @AverageCost, UpdatedDate = SYSUTCDATETIME()
    WHERE UserId = @UserId AND Currency = @Currency;
END;
GO

-- Portfolio
CREATE OR ALTER PROCEDURE usp_GetPortfolio
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT UserId, Username, CashBalance, InvestedValue, HoldingsMarketValue, TotalPortfolioValue, UnrealizedProfitLoss, RealizedProfitLoss, TotalProfitLoss
    FROM vw_UserPortfolioSummary WHERE UserId = @UserId;

    SELECT WalletId, UserId, Symbol, Name, Quantity, AverageCost, CurrentPrice, CurrentValue, TotalCost, UnrealizedProfitLoss, UnrealizedProfitLossPercentage, UpdatedDate
    FROM vw_UserActiveHoldings WHERE UserId = @UserId
    ORDER BY CurrentValue DESC;
END;
GO

CREATE OR ALTER PROCEDURE usp_GetPortfolioHoldings
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT WalletId, UserId, Symbol, Name, Quantity, AverageCost, CurrentPrice, CurrentValue, TotalCost, UnrealizedProfitLoss, UnrealizedProfitLossPercentage, UpdatedDate
    FROM vw_UserActiveHoldings WHERE UserId = @UserId
    ORDER BY CurrentValue DESC;
END;
GO

CREATE OR ALTER PROCEDURE usp_GetPortfolioSummary
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT UserId, Username, CashBalance, InvestedValue, HoldingsMarketValue, TotalPortfolioValue, UnrealizedProfitLoss, RealizedProfitLoss, TotalProfitLoss
    FROM vw_UserPortfolioSummary WHERE UserId = @UserId;
END;
GO

CREATE OR ALTER PROCEDURE usp_GetPortfolioPerformance
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @TotalDeposited DECIMAL(18,2) = 0.00;
    DECLARE @TotalWithdrawn DECIMAL(18,2) = 0.00;
    DECLARE @TotalTradesCount INT = 0;

    SELECT @TotalDeposited = ISNULL(SUM(Amount), 0.00) FROM Deposits WHERE UserId = @UserId AND Status = 'COMPLETED';
    SELECT @TotalWithdrawn = ISNULL(SUM(Amount), 0.00) FROM Withdrawals WHERE UserId = @UserId AND Status = 'COMPLETED';
    SELECT @TotalTradesCount = COUNT(*) FROM Trades WHERE UserId = @UserId;

    SELECT 
        s.UserId, s.Username, s.CashBalance, s.InvestedValue, s.HoldingsMarketValue, s.TotalPortfolioValue,
        s.UnrealizedProfitLoss, s.RealizedProfitLoss, s.TotalProfitLoss,
        CASE WHEN s.InvestedValue > 0 THEN CAST((s.TotalProfitLoss / s.InvestedValue) * 100.0 AS DECIMAL(18,2)) ELSE 0.00 END AS ReturnPercentage,
        @TotalDeposited AS TotalDeposited,
        @TotalWithdrawn AS TotalWithdrawn,
        @TotalTradesCount AS TotalTradesCount
    FROM vw_UserPortfolioSummary s WHERE s.UserId = @UserId;
END;
GO

CREATE OR ALTER PROCEDURE usp_GetUnrealizedProfitLoss
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT @UserId AS UserId, ISNULL(SUM(UnrealizedProfitLoss), 0.00) AS TotalUnrealizedProfitLoss
    FROM vw_UserActiveHoldings WHERE UserId = @UserId;
END;
GO

CREATE OR ALTER PROCEDURE usp_GetRealizedProfitLoss
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT @UserId AS UserId, ISNULL(SUM(RealizedProfitLoss), 0.00) AS TotalRealizedProfitLoss
    FROM Trades WHERE UserId = @UserId;
END;
GO

-- Orders
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
    DECLARE @TotalValue DECIMAL(18, 2) = CAST(@Quantity * @Price AS DECIMAL(18, 2));

    INSERT INTO Orders (UserId, Symbol, OrderType, Side, Quantity, Price, TotalValue, Status, CreatedDate)
    VALUES (@UserId, @Symbol, @OrderType, @Side, @Quantity, @Price, @TotalValue, @Status, SYSUTCDATETIME());

    SET @OrderId = SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE usp_GetOrder
    @OrderId INT,
    @UserId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT OrderId, UserId, Symbol, OrderType, Side, Quantity, Price, TotalValue, Status, CreatedDate, ExecutedDate
    FROM Orders WHERE OrderId = @OrderId AND (@UserId IS NULL OR UserId = @UserId);
END;
GO

CREATE OR ALTER PROCEDURE usp_GetOrdersByUser
    @UserId INT,
    @Limit INT = 100
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (@Limit) OrderId, UserId, Symbol, OrderType, Side, Quantity, Price, TotalValue, Status, CreatedDate, ExecutedDate
    FROM Orders WHERE UserId = @UserId ORDER BY CreatedDate DESC;
END;
GO

CREATE OR ALTER PROCEDURE usp_GetOpenOrders
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT OrderId, UserId, Symbol, OrderType, Side, Quantity, Price, TotalValue, Status, CreatedDate, ExecutedDate
    FROM Orders WHERE UserId = @UserId AND Status = 'Pending' ORDER BY CreatedDate DESC;
END;
GO

CREATE OR ALTER PROCEDURE usp_GetCompletedOrders
    @UserId INT,
    @Limit INT = 100
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (@Limit) OrderId, UserId, Symbol, OrderType, Side, Quantity, Price, TotalValue, Status, CreatedDate, ExecutedDate
    FROM Orders WHERE UserId = @UserId AND Status IN ('Executed', 'Cancelled', 'Rejected')
    ORDER BY ISNULL(ExecutedDate, CreatedDate) DESC;
END;
GO

CREATE OR ALTER PROCEDURE usp_UpdateOrderStatus
    @OrderId INT,
    @Status NVARCHAR(20),
    @ExecutedDate DATETIME2(7) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Orders
    SET Status = @Status, ExecutedDate = CASE WHEN @Status = 'Executed' AND @ExecutedDate IS NULL THEN SYSUTCDATETIME() ELSE @ExecutedDate END
    WHERE OrderId = @OrderId;
END;
GO

CREATE OR ALTER PROCEDURE usp_CancelOrder
    @OrderId INT,
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @CurrentStatus NVARCHAR(20);
    DECLARE @OrderUserId INT;

    SELECT @CurrentStatus = Status, @OrderUserId = UserId FROM Orders WHERE OrderId = @OrderId;

    IF @OrderUserId IS NULL BEGIN RAISERROR('Order not found.', 16, 1); RETURN; END
    IF @OrderUserId <> @UserId BEGIN RAISERROR('Unauthorized. You do not own this order.', 16, 2); RETURN; END
    IF @CurrentStatus = 'Executed' BEGIN RAISERROR('Cannot cancel an executed order.', 16, 3); RETURN; END
    IF @CurrentStatus = 'Cancelled' BEGIN RAISERROR('Order is already cancelled.', 16, 4); RETURN; END
    IF @CurrentStatus <> 'Pending' BEGIN RAISERROR('Order cannot be cancelled in its current state.', 16, 5); RETURN; END

    UPDATE Orders SET Status = 'Cancelled', ExecutedDate = SYSUTCDATETIME() WHERE OrderId = @OrderId;

    SELECT OrderId, UserId, Symbol, OrderType, Side, Quantity, Price, TotalValue, Status, CreatedDate, ExecutedDate
    FROM Orders WHERE OrderId = @OrderId;
END;
GO

-- Trades
CREATE OR ALTER PROCEDURE usp_ExecuteBuyOrder
    @UserId INT,
    @Symbol NVARCHAR(20),
    @Quantity DECIMAL(28, 8),
    @ExecutionPrice DECIMAL(28, 8),
    @TradeId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @Quantity <= 0 BEGIN RAISERROR('Quantity must be greater than zero.', 16, 1); RETURN; END
    IF @ExecutionPrice <= 0 BEGIN RAISERROR('Execution price must be greater than zero.', 16, 2); RETURN; END
    IF NOT EXISTS (SELECT 1 FROM Users WHERE UserId = @UserId AND IsActive = 1) BEGIN RAISERROR('User not found or inactive.', 16, 3); RETURN; END
    IF NOT EXISTS (SELECT 1 FROM Cryptocurrencies WHERE Symbol = @Symbol AND IsActive = 1) BEGIN RAISERROR('Cryptocurrency symbol is invalid or inactive.', 16, 4); RETURN; END

    DECLARE @TradeValue DECIMAL(18, 2) = CAST(@Quantity * @ExecutionPrice AS DECIMAL(18, 2));
    IF @TradeValue <= 0.00 BEGIN RAISERROR('Trade value must be greater than zero.', 16, 5); RETURN; END

    DECLARE @OrderId INT;
    DECLARE @CurrentBalance DECIMAL(18, 2);
    DECLARE @CurrentWalletQty DECIMAL(28, 8) = 0.00000000;
    DECLARE @CurrentAvgCost DECIMAL(28, 8) = 0.00000000;
    DECLARE @NewQuantity DECIMAL(28, 8);
    DECLARE @NewAvgCost DECIMAL(28, 8);
    DECLARE @ExecutedDate DATETIME2(7) = SYSUTCDATETIME();

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @CurrentBalance = AvailableBalance
        FROM Accounts WITH (UPDLOCK, HOLDLOCK)
        WHERE UserId = @UserId AND Currency = 'USD';

        IF @CurrentBalance IS NULL BEGIN RAISERROR('Account not found for user.', 16, 6); END
        IF @CurrentBalance < @TradeValue BEGIN RAISERROR('Insufficient balance for this purchase.', 16, 7); END

        INSERT INTO Orders (UserId, Symbol, OrderType, Side, Quantity, Price, TotalValue, Status, CreatedDate, ExecutedDate)
        VALUES (@UserId, @Symbol, 'Market', 'BUY', @Quantity, @ExecutionPrice, @TradeValue, 'Executed', @ExecutedDate, @ExecutedDate);
        SET @OrderId = SCOPE_IDENTITY();

        INSERT INTO Trades (OrderId, UserId, Symbol, Side, Quantity, ExecutionPrice, TotalValue, RealizedProfitLoss, ExecutedDate)
        VALUES (@OrderId, @UserId, @Symbol, 'BUY', @Quantity, @ExecutionPrice, @TradeValue, 0.00, @ExecutedDate);
        SET @TradeId = SCOPE_IDENTITY();

        UPDATE Accounts
        SET AvailableBalance = AvailableBalance - @TradeValue, UpdatedDate = @ExecutedDate
        WHERE UserId = @UserId AND Currency = 'USD';

        IF EXISTS (SELECT 1 FROM Wallets WITH (UPDLOCK, HOLDLOCK) WHERE UserId = @UserId AND Currency = @Symbol)
        BEGIN
            SELECT @CurrentWalletQty = Quantity, @CurrentAvgCost = AverageCost
            FROM Wallets WITH (UPDLOCK, HOLDLOCK) WHERE UserId = @UserId AND Currency = @Symbol;

            SET @NewQuantity = @CurrentWalletQty + @Quantity;
            SET @NewAvgCost = ((@CurrentWalletQty * @CurrentAvgCost) + (@Quantity * @ExecutionPrice)) / @NewQuantity;

            UPDATE Wallets
            SET Quantity = @NewQuantity, AverageCost = @NewAvgCost, UpdatedDate = @ExecutedDate
            WHERE UserId = @UserId AND Currency = @Symbol;
        END
        ELSE
        BEGIN
            INSERT INTO Wallets (UserId, Currency, Quantity, AverageCost, CreatedDate, UpdatedDate)
            VALUES (@UserId, @Symbol, @Quantity, @ExecutionPrice, @ExecutedDate, @ExecutedDate);
        END

        INSERT INTO Transactions (UserId, TransactionType, Currency, Amount, ReferenceId, Status, CreatedDate)
        VALUES (@UserId, 'BUY', 'USD', @TradeValue, CAST(@TradeId AS NVARCHAR(100)), 'COMPLETED', @ExecutedDate);

        COMMIT TRANSACTION;

        SELECT t.TradeId, t.OrderId, t.UserId, t.Symbol, t.Side, t.Quantity, t.ExecutionPrice, t.TotalValue, t.RealizedProfitLoss, t.ExecutedDate, a.AvailableBalance AS RemainingBalance
        FROM Trades t
        INNER JOIN Accounts a ON t.UserId = a.UserId AND a.Currency = 'USD'
        WHERE t.TradeId = @TradeId;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE usp_ExecuteSellOrder
    @UserId INT,
    @Symbol NVARCHAR(20),
    @Quantity DECIMAL(28, 8),
    @ExecutionPrice DECIMAL(28, 8),
    @TradeId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @Quantity <= 0 BEGIN RAISERROR('Quantity must be greater than zero.', 16, 1); RETURN; END
    IF @ExecutionPrice <= 0 BEGIN RAISERROR('Execution price must be greater than zero.', 16, 2); RETURN; END
    IF NOT EXISTS (SELECT 1 FROM Users WHERE UserId = @UserId AND IsActive = 1) BEGIN RAISERROR('User not found or inactive.', 16, 3); RETURN; END
    IF NOT EXISTS (SELECT 1 FROM Cryptocurrencies WHERE Symbol = @Symbol AND IsActive = 1) BEGIN RAISERROR('Cryptocurrency symbol is invalid or inactive.', 16, 4); RETURN; END

    DECLARE @TradeValue DECIMAL(18, 2) = CAST(@Quantity * @ExecutionPrice AS DECIMAL(18, 2));
    IF @TradeValue <= 0.00 BEGIN RAISERROR('Trade value must be greater than zero.', 16, 5); RETURN; END

    DECLARE @OrderId INT;
    DECLARE @OwnedQuantity DECIMAL(28, 8);
    DECLARE @AverageCost DECIMAL(28, 8);
    DECLARE @RealizedPL DECIMAL(18, 2);
    DECLARE @NewQuantity DECIMAL(28, 8);
    DECLARE @ExecutedDate DATETIME2(7) = SYSUTCDATETIME();

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @OwnedQuantity = Quantity, @AverageCost = AverageCost
        FROM Wallets WITH (UPDLOCK, HOLDLOCK)
        WHERE UserId = @UserId AND Currency = @Symbol;

        IF @OwnedQuantity IS NULL OR @OwnedQuantity < @Quantity
        BEGIN
            RAISERROR('Insufficient cryptocurrency holdings to execute this sell order.', 16, 6);
        END

        SET @RealizedPL = CAST((@ExecutionPrice - @AverageCost) * @Quantity AS DECIMAL(18, 2));

        INSERT INTO Orders (UserId, Symbol, OrderType, Side, Quantity, Price, TotalValue, Status, CreatedDate, ExecutedDate)
        VALUES (@UserId, @Symbol, 'Market', 'SELL', @Quantity, @ExecutionPrice, @TradeValue, 'Executed', @ExecutedDate, @ExecutedDate);
        SET @OrderId = SCOPE_IDENTITY();

        INSERT INTO Trades (OrderId, UserId, Symbol, Side, Quantity, ExecutionPrice, TotalValue, RealizedProfitLoss, ExecutedDate)
        VALUES (@OrderId, @UserId, @Symbol, 'SELL', @Quantity, @ExecutionPrice, @TradeValue, @RealizedPL, @ExecutedDate);
        SET @TradeId = SCOPE_IDENTITY();

        SET @NewQuantity = @OwnedQuantity - @Quantity;
        UPDATE Wallets
        SET Quantity = @NewQuantity, AverageCost = CASE WHEN @NewQuantity = 0 THEN 0.00000000 ELSE AverageCost END, UpdatedDate = @ExecutedDate
        WHERE UserId = @UserId AND Currency = @Symbol;

        UPDATE Accounts
        SET AvailableBalance = AvailableBalance + @TradeValue, UpdatedDate = @ExecutedDate
        WHERE UserId = @UserId AND Currency = 'USD';

        INSERT INTO Transactions (UserId, TransactionType, Currency, Amount, ReferenceId, Status, CreatedDate)
        VALUES (@UserId, 'SELL', 'USD', @TradeValue, CAST(@TradeId AS NVARCHAR(100)), 'COMPLETED', @ExecutedDate);

        COMMIT TRANSACTION;

        SELECT t.TradeId, t.OrderId, t.UserId, t.Symbol, t.Side, t.Quantity, t.ExecutionPrice, t.TotalValue, t.RealizedProfitLoss, t.ExecutedDate, a.AvailableBalance AS RemainingBalance, w.Quantity AS RemainingCryptoHolding
        FROM Trades t
        INNER JOIN Accounts a ON t.UserId = a.UserId AND a.Currency = 'USD'
        INNER JOIN Wallets w ON t.UserId = w.UserId AND w.Currency = t.Symbol
        WHERE t.TradeId = @TradeId;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE usp_GetTradesByUser
    @UserId INT,
    @Limit INT = 100
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (@Limit) TradeId, OrderId, UserId, Symbol, Side, Quantity, ExecutionPrice, TotalValue, RealizedProfitLoss, ExecutedDate
    FROM Trades WHERE UserId = @UserId ORDER BY ExecutedDate DESC;
END;
GO

-- Transactions
CREATE OR ALTER PROCEDURE usp_CreateTransaction
    @UserId INT,
    @TransactionType NVARCHAR(20),
    @Currency NVARCHAR(20),
    @Amount DECIMAL(18, 2),
    @ReferenceId NVARCHAR(100) = NULL,
    @Status NVARCHAR(20) = 'COMPLETED',
    @TransactionId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO Transactions (UserId, TransactionType, Currency, Amount, ReferenceId, Status, CreatedDate)
    VALUES (@UserId, @TransactionType, @Currency, @Amount, @ReferenceId, @Status, SYSUTCDATETIME());
    SET @TransactionId = SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE usp_GetTransactionsByUser
    @UserId INT,
    @Limit INT = 100
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (@Limit) TransactionId, UserId, TransactionType, Currency, Amount, ReferenceId, Status, CreatedDate
    FROM Transactions WHERE UserId = @UserId ORDER BY CreatedDate DESC;
END;
GO

CREATE OR ALTER PROCEDURE usp_GetTransactionById
    @TransactionId INT,
    @UserId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TransactionId, UserId, TransactionType, Currency, Amount, ReferenceId, Status, CreatedDate
    FROM Transactions WHERE TransactionId = @TransactionId AND (@UserId IS NULL OR UserId = @UserId);
END;
GO

-- Deposits
CREATE OR ALTER PROCEDURE usp_ProcessDeposit
    @UserId INT,
    @Amount DECIMAL(18, 2),
    @Currency NVARCHAR(10) = 'USD',
    @DepositId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @Amount <= 0 BEGIN RAISERROR('Deposit amount must be greater than zero.', 16, 1); RETURN; END
    IF NOT EXISTS (SELECT 1 FROM Users WHERE UserId = @UserId AND IsActive = 1) BEGIN RAISERROR('User not found or inactive.', 16, 2); RETURN; END

    DECLARE @ProcessedDate DATETIME2(7) = SYSUTCDATETIME();

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO Deposits (UserId, Amount, Currency, Status, CreatedDate, ProcessedDate)
        VALUES (@UserId, @Amount, @Currency, 'COMPLETED', @ProcessedDate, @ProcessedDate);
        SET @DepositId = SCOPE_IDENTITY();

        IF EXISTS (SELECT 1 FROM Accounts WITH (UPDLOCK, HOLDLOCK) WHERE UserId = @UserId AND Currency = @Currency)
        BEGIN
            UPDATE Accounts
            SET AvailableBalance = AvailableBalance + @Amount, UpdatedDate = @ProcessedDate
            WHERE UserId = @UserId AND Currency = @Currency;
        END
        ELSE
        BEGIN
            INSERT INTO Accounts (UserId, Currency, AvailableBalance, CreatedDate, UpdatedDate)
            VALUES (@UserId, @Currency, @Amount, @ProcessedDate, @ProcessedDate);
        END

        INSERT INTO Transactions (UserId, TransactionType, Currency, Amount, ReferenceId, Status, CreatedDate)
        VALUES (@UserId, 'DEPOSIT', @Currency, @Amount, CAST(@DepositId AS NVARCHAR(100)), 'COMPLETED', @ProcessedDate);

        COMMIT TRANSACTION;

        SELECT d.DepositId, d.UserId, d.Amount, d.Currency, d.Status, d.CreatedDate, d.ProcessedDate, a.AvailableBalance AS NewBalance
        FROM Deposits d
        INNER JOIN Accounts a ON d.UserId = a.UserId AND a.Currency = d.Currency
        WHERE d.DepositId = @DepositId;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE usp_GetDepositsByUser
    @UserId INT,
    @Limit INT = 100
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (@Limit) DepositId, UserId, Amount, Currency, Status, CreatedDate, ProcessedDate
    FROM Deposits WHERE UserId = @UserId ORDER BY CreatedDate DESC;
END;
GO

-- Withdrawals
CREATE OR ALTER PROCEDURE usp_ProcessWithdrawal
    @UserId INT,
    @Amount DECIMAL(18, 2),
    @Currency NVARCHAR(10) = 'USD',
    @WithdrawalId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @Amount <= 0 BEGIN RAISERROR('Withdrawal amount must be greater than zero.', 16, 1); RETURN; END
    IF NOT EXISTS (SELECT 1 FROM Users WHERE UserId = @UserId AND IsActive = 1) BEGIN RAISERROR('User not found or inactive.', 16, 2); RETURN; END

    DECLARE @CurrentBalance DECIMAL(18, 2);
    DECLARE @ProcessedDate DATETIME2(7) = SYSUTCDATETIME();

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @CurrentBalance = AvailableBalance
        FROM Accounts WITH (UPDLOCK, HOLDLOCK)
        WHERE UserId = @UserId AND Currency = @Currency;

        IF @CurrentBalance IS NULL BEGIN RAISERROR('Account not found for user.', 16, 3); END
        IF @CurrentBalance < @Amount BEGIN RAISERROR('Insufficient balance for this withdrawal.', 16, 4); END

        INSERT INTO Withdrawals (UserId, Amount, Currency, Status, CreatedDate, ProcessedDate)
        VALUES (@UserId, @Amount, @Currency, 'COMPLETED', @ProcessedDate, @ProcessedDate);
        SET @WithdrawalId = SCOPE_IDENTITY();

        UPDATE Accounts
        SET AvailableBalance = AvailableBalance - @Amount, UpdatedDate = @ProcessedDate
        WHERE UserId = @UserId AND Currency = @Currency;

        INSERT INTO Transactions (UserId, TransactionType, Currency, Amount, ReferenceId, Status, CreatedDate)
        VALUES (@UserId, 'WITHDRAWAL', @Currency, @Amount, CAST(@WithdrawalId AS NVARCHAR(100)), 'COMPLETED', @ProcessedDate);

        COMMIT TRANSACTION;

        SELECT w.WithdrawalId, w.UserId, w.Amount, w.Currency, w.Status, w.CreatedDate, w.ProcessedDate, a.AvailableBalance AS RemainingBalance
        FROM Withdrawals w
        INNER JOIN Accounts a ON w.UserId = a.UserId AND a.Currency = w.Currency
        WHERE w.WithdrawalId = @WithdrawalId;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE usp_GetWithdrawalsByUser
    @UserId INT,
    @Limit INT = 100
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (@Limit) WithdrawalId, UserId, Amount, Currency, Status, CreatedDate, ProcessedDate
    FROM Withdrawals WHERE UserId = @UserId ORDER BY CreatedDate DESC;
END;
GO

PRINT 'Step 6: Applying Demo Seed Data...';
GO

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
    UPDATE SET Name = source.Name, CurrentPrice = source.CurrentPrice, PriceChange24h = source.PriceChange24h, LastUpdated = SYSUTCDATETIME()
WHEN NOT MATCHED THEN 
    INSERT (Symbol, Name, CurrentPrice, PriceChange24h, LastUpdated, IsActive)
    VALUES (source.Symbol, source.Name, source.CurrentPrice, source.PriceChange24h, SYSUTCDATETIME(), source.IsActive);
GO

DECLARE @DemoPasswordHash NVARCHAR(256) = '10000:B5QPbABmmw2wq/DfKFSp1Q==:w0Esu/KZwurDjf6r9GEgTskcbFQLSwwunYI+3dZXRgY=';

IF NOT EXISTS (SELECT 1 FROM Users WHERE Username = 'trader1')
    INSERT INTO Users (Username, Email, PasswordHash, FirstName, LastName, CreatedDate, LastLoginDate, IsActive)
    VALUES ('trader1', 'trader1@cryptotrading.local', @DemoPasswordHash, 'Paritosh', 'Tonk', SYSUTCDATETIME(), SYSUTCDATETIME(), 1);

IF NOT EXISTS (SELECT 1 FROM Users WHERE Username = 'trader2')
    INSERT INTO Users (Username, Email, PasswordHash, FirstName, LastName, CreatedDate, LastLoginDate, IsActive)
    VALUES ('trader2', 'alice@cryptotrading.local', @DemoPasswordHash, 'Alice', 'Smith', SYSUTCDATETIME(), NULL, 1);

IF NOT EXISTS (SELECT 1 FROM Users WHERE Username = 'demo_trader')
    INSERT INTO Users (Username, Email, PasswordHash, FirstName, LastName, CreatedDate, LastLoginDate, IsActive)
    VALUES ('demo_trader', 'bob@cryptotrading.local', @DemoPasswordHash, 'Bob', 'Trader', SYSUTCDATETIME(), NULL, 1);
GO

DECLARE @User1Id INT = (SELECT UserId FROM Users WHERE Username = 'trader1');
DECLARE @User2Id INT = (SELECT UserId FROM Users WHERE Username = 'trader2');
DECLARE @DemoUserId INT = (SELECT UserId FROM Users WHERE Username = 'demo_trader');

IF NOT EXISTS (SELECT 1 FROM Accounts WHERE UserId = @User1Id AND Currency = 'USD')
    INSERT INTO Accounts (UserId, Currency, AvailableBalance, CreatedDate, UpdatedDate) VALUES (@User1Id, 'USD', 15400.00, SYSUTCDATETIME(), SYSUTCDATETIME());

IF NOT EXISTS (SELECT 1 FROM Accounts WHERE UserId = @User2Id AND Currency = 'USD')
    INSERT INTO Accounts (UserId, Currency, AvailableBalance, CreatedDate, UpdatedDate) VALUES (@User2Id, 'USD', 8250.00, SYSUTCDATETIME(), SYSUTCDATETIME());

IF NOT EXISTS (SELECT 1 FROM Accounts WHERE UserId = @DemoUserId AND Currency = 'USD')
    INSERT INTO Accounts (UserId, Currency, AvailableBalance, CreatedDate, UpdatedDate) VALUES (@DemoUserId, 'USD', 10000.00, SYSUTCDATETIME(), SYSUTCDATETIME());

IF NOT EXISTS (SELECT 1 FROM Wallets WHERE UserId = @User1Id AND Currency = 'BTC')
    INSERT INTO Wallets (UserId, Currency, Quantity, AverageCost, CreatedDate, UpdatedDate) VALUES (@User1Id, 'BTC', 0.15000000, 65000.00000000, SYSUTCDATETIME(), SYSUTCDATETIME());

IF NOT EXISTS (SELECT 1 FROM Wallets WHERE UserId = @User1Id AND Currency = 'ETH')
    INSERT INTO Wallets (UserId, Currency, Quantity, AverageCost, CreatedDate, UpdatedDate) VALUES (@User1Id, 'ETH', 2.00000000, 2200.00000000, SYSUTCDATETIME(), SYSUTCDATETIME());

IF NOT EXISTS (SELECT 1 FROM Wallets WHERE UserId = @User1Id AND Currency = 'SOL')
    INSERT INTO Wallets (UserId, Currency, Quantity, AverageCost, CreatedDate, UpdatedDate) VALUES (@User1Id, 'SOL', 25.00000000, 90.00000000, SYSUTCDATETIME(), SYSUTCDATETIME());

IF NOT EXISTS (SELECT 1 FROM Wallets WHERE UserId = @User2Id AND Currency = 'ETH')
    INSERT INTO Wallets (UserId, Currency, Quantity, AverageCost, CreatedDate, UpdatedDate) VALUES (@User2Id, 'ETH', 1.50000000, 2300.00000000, SYSUTCDATETIME(), SYSUTCDATETIME());

IF NOT EXISTS (SELECT 1 FROM Wallets WHERE UserId = @User2Id AND Currency = 'ADA')
    INSERT INTO Wallets (UserId, Currency, Quantity, AverageCost, CreatedDate, UpdatedDate) VALUES (@User2Id, 'ADA', 1000.00000000, 0.32000000, SYSUTCDATETIME(), SYSUTCDATETIME());

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

IF NOT EXISTS (SELECT 1 FROM Orders WHERE UserId = @User1Id)
BEGIN
    INSERT INTO Orders (UserId, Symbol, OrderType, Side, Quantity, Price, TotalValue, Status, CreatedDate, ExecutedDate)
    VALUES (@User1Id, 'BTC', 'Market', 'BUY', 0.20000000, 65000.00000000, 13000.00, 'Executed', DATEADD(DAY, -8, SYSUTCDATETIME()), DATEADD(DAY, -8, SYSUTCDATETIME()));
    DECLARE @Ord1Id INT = SCOPE_IDENTITY();
    INSERT INTO Trades (OrderId, UserId, Symbol, Side, Quantity, ExecutionPrice, TotalValue, RealizedProfitLoss, ExecutedDate)
    VALUES (@Ord1Id, @User1Id, 'BTC', 'BUY', 0.20000000, 65000.00000000, 13000.00, 0.00, DATEADD(DAY, -8, SYSUTCDATETIME()));
    DECLARE @Trd1Id INT = SCOPE_IDENTITY();
    INSERT INTO Transactions (UserId, TransactionType, Currency, Amount, ReferenceId, Status, CreatedDate)
    VALUES (@User1Id, 'BUY', 'USD', 13000.00, CAST(@Trd1Id AS NVARCHAR(100)), 'COMPLETED', DATEADD(DAY, -8, SYSUTCDATETIME()));

    INSERT INTO Orders (UserId, Symbol, OrderType, Side, Quantity, Price, TotalValue, Status, CreatedDate, ExecutedDate)
    VALUES (@User1Id, 'BTC', 'Market', 'SELL', 0.05000000, 72000.00000000, 3600.00, 'Executed', DATEADD(DAY, -4, SYSUTCDATETIME()), DATEADD(DAY, -4, SYSUTCDATETIME()));
    DECLARE @Ord2Id INT = SCOPE_IDENTITY();
    INSERT INTO Trades (OrderId, UserId, Symbol, Side, Quantity, ExecutionPrice, TotalValue, RealizedProfitLoss, ExecutedDate)
    VALUES (@Ord2Id, @User1Id, 'BTC', 'SELL', 0.05000000, 72000.00000000, 3600.00, 350.00, DATEADD(DAY, -4, SYSUTCDATETIME()));
    DECLARE @Trd2Id INT = SCOPE_IDENTITY();
    INSERT INTO Transactions (UserId, TransactionType, Currency, Amount, ReferenceId, Status, CreatedDate)
    VALUES (@User1Id, 'SELL', 'USD', 3600.00, CAST(@Trd2Id AS NVARCHAR(100)), 'COMPLETED', DATEADD(DAY, -4, SYSUTCDATETIME()));
END
GO

PRINT '==============================================';
PRINT 'CryptoTrading Platform Database Setup Complete!';
PRINT '==============================================';
GO
