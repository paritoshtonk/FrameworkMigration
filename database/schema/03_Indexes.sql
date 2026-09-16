-- ============================================================================
-- 03_Indexes.sql
-- CryptoTradingPlatform - Indexes for Query Optimization
-- ============================================================================

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Orders_UserId_Status')
    CREATE NONCLUSTERED INDEX IX_Orders_UserId_Status ON Orders (UserId, Status) INCLUDE (Symbol, Side, Quantity, Price, TotalValue, CreatedDate);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Trades_UserId_ExecutedDate')
    CREATE NONCLUSTERED INDEX IX_Trades_UserId_ExecutedDate ON Trades (UserId, ExecutedDate DESC) INCLUDE (Symbol, Side, Quantity, ExecutionPrice, TotalValue, RealizedProfitLoss);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Transactions_UserId_CreatedDate')
    CREATE NONCLUSTERED INDEX IX_Transactions_UserId_CreatedDate ON Transactions (UserId, CreatedDate DESC) INCLUDE (TransactionType, Currency, Amount, ReferenceId, Status);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Wallets_UserId')
    CREATE NONCLUSTERED INDEX IX_Wallets_UserId ON Wallets (UserId) INCLUDE (Currency, Quantity, AverageCost);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Deposits_UserId_CreatedDate')
    CREATE NONCLUSTERED INDEX IX_Deposits_UserId_CreatedDate ON Deposits (UserId, CreatedDate DESC);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Withdrawals_UserId_CreatedDate')
    CREATE NONCLUSTERED INDEX IX_Withdrawals_UserId_CreatedDate ON Withdrawals (UserId, CreatedDate DESC);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_PriceHistory_CryptocurrencyId_RecordedDate')
    CREATE NONCLUSTERED INDEX IX_PriceHistory_CryptocurrencyId_RecordedDate ON PriceHistory (CryptocurrencyId, RecordedDate DESC);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Cryptocurrencies_Symbol')
    CREATE NONCLUSTERED INDEX IX_Cryptocurrencies_Symbol ON Cryptocurrencies (Symbol) INCLUDE (Name, CurrentPrice, PriceChange24h, LastUpdated, IsActive);
