-- ============================================================================
-- 02_Constraints.sql
-- CryptoTradingPlatform - Foreign Keys and Constraints
-- ============================================================================

-- Unique Constraints
IF NOT EXISTS (SELECT * FROM sys.key_constraints WHERE name = 'UQ_Users_Username')
    ALTER TABLE Users ADD CONSTRAINT UQ_Users_Username UNIQUE (Username);

IF NOT EXISTS (SELECT * FROM sys.key_constraints WHERE name = 'UQ_Users_Email')
    ALTER TABLE Users ADD CONSTRAINT UQ_Users_Email UNIQUE (Email);

IF NOT EXISTS (SELECT * FROM sys.key_constraints WHERE name = 'UQ_Cryptocurrencies_Symbol')
    ALTER TABLE Cryptocurrencies ADD CONSTRAINT UQ_Cryptocurrencies_Symbol UNIQUE (Symbol);

IF NOT EXISTS (SELECT * FROM sys.key_constraints WHERE name = 'UQ_Wallets_User_Currency')
    ALTER TABLE Wallets ADD CONSTRAINT UQ_Wallets_User_Currency UNIQUE (UserId, Currency);

-- Foreign Keys
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Accounts_Users')
    ALTER TABLE Accounts ADD CONSTRAINT FK_Accounts_Users FOREIGN KEY (UserId) REFERENCES Users(UserId);

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Wallets_Users')
    ALTER TABLE Wallets ADD CONSTRAINT FK_Wallets_Users FOREIGN KEY (UserId) REFERENCES Users(UserId);

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Orders_Users')
    ALTER TABLE Orders ADD CONSTRAINT FK_Orders_Users FOREIGN KEY (UserId) REFERENCES Users(UserId);

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Trades_Orders')
    ALTER TABLE Trades ADD CONSTRAINT FK_Trades_Orders FOREIGN KEY (OrderId) REFERENCES Orders(OrderId);

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Trades_Users')
    ALTER TABLE Trades ADD CONSTRAINT FK_Trades_Users FOREIGN KEY (UserId) REFERENCES Users(UserId);

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Transactions_Users')
    ALTER TABLE Transactions ADD CONSTRAINT FK_Transactions_Users FOREIGN KEY (UserId) REFERENCES Users(UserId);

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Deposits_Users')
    ALTER TABLE Deposits ADD CONSTRAINT FK_Deposits_Users FOREIGN KEY (UserId) REFERENCES Users(UserId);

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Withdrawals_Users')
    ALTER TABLE Withdrawals ADD CONSTRAINT FK_Withdrawals_Users FOREIGN KEY (UserId) REFERENCES Users(UserId);

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_PriceHistory_Cryptocurrencies')
    ALTER TABLE PriceHistory ADD CONSTRAINT FK_PriceHistory_Cryptocurrencies FOREIGN KEY (CryptocurrencyId) REFERENCES Cryptocurrencies(CryptocurrencyId);

-- Check Constraints
IF NOT EXISTS (SELECT * FROM sys.check_constraints WHERE name = 'CK_Accounts_AvailableBalance')
    ALTER TABLE Accounts ADD CONSTRAINT CK_Accounts_AvailableBalance CHECK (AvailableBalance >= 0);

IF NOT EXISTS (SELECT * FROM sys.check_constraints WHERE name = 'CK_Wallets_Quantity')
    ALTER TABLE Wallets ADD CONSTRAINT CK_Wallets_Quantity CHECK (Quantity >= 0);

IF NOT EXISTS (SELECT * FROM sys.check_constraints WHERE name = 'CK_Wallets_AverageCost')
    ALTER TABLE Wallets ADD CONSTRAINT CK_Wallets_AverageCost CHECK (AverageCost >= 0);

IF NOT EXISTS (SELECT * FROM sys.check_constraints WHERE name = 'CK_Orders_Quantity')
    ALTER TABLE Orders ADD CONSTRAINT CK_Orders_Quantity CHECK (Quantity > 0);

IF NOT EXISTS (SELECT * FROM sys.check_constraints WHERE name = 'CK_Trades_Quantity')
    ALTER TABLE Trades ADD CONSTRAINT CK_Trades_Quantity CHECK (Quantity > 0);

IF NOT EXISTS (SELECT * FROM sys.check_constraints WHERE name = 'CK_Deposits_Amount')
    ALTER TABLE Deposits ADD CONSTRAINT CK_Deposits_Amount CHECK (Amount > 0);

IF NOT EXISTS (SELECT * FROM sys.check_constraints WHERE name = 'CK_Withdrawals_Amount')
    ALTER TABLE Withdrawals ADD CONSTRAINT CK_Withdrawals_Amount CHECK (Amount > 0);
