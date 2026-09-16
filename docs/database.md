# Database Design Documentation — Microsoft SQL Server

## 1. Overview & Principles

The database tier for the CryptoTrading platform is hosted on **Microsoft SQL Server** (supporting SQL Server 2017+ through SQL Server 2022 and LocalDB).

The database is an active component of application logic rather than a passive data repository. All financial modifications, order status transitions, balance changes, and ledger entries are executed directly inside stored procedures using explicit ACID transactions.

---

## 2. Table Definitions & Data Dictionary

### 2.1 `dbo.Users`
Stores user profile, credentials, and account registration status.

| Column Name | Data Type | Nullable | Description |
|---|---|---|---|
| `UserId` | `INT IDENTITY(1,1)` | No | Primary Key |
| `Username` | `NVARCHAR(50)` | No | Unique login username |
| `Email` | `NVARCHAR(100)` | No | Unique user email address |
| `PasswordHash` | `NVARCHAR(256)` | No | PBKDF2-SHA256 hashed password string |
| `FirstName` | `NVARCHAR(50)` | No | User's first name |
| `LastName` | `NVARCHAR(50)` | No | User's last name |
| `CreatedDate` | `DATETIME2` | No | Account registration timestamp (UTC) |
| `LastLoginDate` | `DATETIME2` | Yes | Timestamp of most recent authentication (UTC) |
| `IsActive` | `BIT` | No | Account status flag (Default: 1) |

### 2.2 `dbo.Accounts`
Stores the simulated fiat (cash) balance for each user.

| Column Name | Data Type | Nullable | Description |
|---|---|---|---|
| `AccountId` | `INT IDENTITY(1,1)` | No | Primary Key |
| `UserId` | `INT` | No | Foreign Key -> `Users(UserId)` (Unique 1:1) |
| `Balance` | `DECIMAL(18,2)` | No | Available fiat cash balance in USD (Default: 0.00) |
| `Currency` | `NVARCHAR(3)` | No | Account base currency code (Default: 'USD') |
| `CreatedDate` | `DATETIME2` | No | Account creation timestamp (UTC) |
| `LastUpdatedDate` | `DATETIME2` | No | Last balance mutation timestamp (UTC) |

**Constraints:**
- `CK_Accounts_Balance_NonNegative`: `Balance >= 0.00`

### 2.3 `dbo.Cryptocurrencies`
Stores the catalog of tradeable cryptocurrencies and cached market prices.

| Column Name | Data Type | Nullable | Description |
|---|---|---|---|
| `CryptocurrencyId` | `INT IDENTITY(1,1)` | No | Primary Key |
| `Symbol` | `NVARCHAR(10)` | No | Unique ticker symbol (e.g. BTC, ETH, SOL) |
| `Name` | `NVARCHAR(50)` | No | Full cryptocurrency name |
| `CurrentPrice` | `DECIMAL(18,8)` | No | Latest known USD price (Default: 0.00) |
| `PriceChange24h` | `DECIMAL(9,4)` | No | 24-hour price change percentage (Default: 0.00) |
| `LastUpdated` | `DATETIME2` | No | Timestamp of latest price sync (UTC) |
| `IsActive` | `BIT` | No | Active trading flag (Default: 1) |

### 2.4 `dbo.Wallets`
Stores the cryptocurrency balance and cost basis for each user holding.

| Column Name | Data Type | Nullable | Description |
|---|---|---|---|
| `WalletId` | `INT IDENTITY(1,1)` | No | Primary Key |
| `UserId` | `INT` | No | Foreign Key -> `Users(UserId)` |
| `CryptocurrencyId` | `INT` | No | Foreign Key -> `Cryptocurrencies(CryptocurrencyId)` |
| `Quantity` | `DECIMAL(18,8)` | No | Units of cryptocurrency held (Default: 0.00000000) |
| `AverageBuyPrice` | `DECIMAL(18,8)` | No | Weighted average purchase price (Default: 0.00000000) |
| `CreatedDate` | `DATETIME2` | No | Wallet initialization timestamp (UTC) |
| `LastUpdatedDate` | `DATETIME2` | No | Timestamp of last holding update (UTC) |

**Constraints:**
- `UQ_Wallets_User_Crypto`: Unique constraint on `(UserId, CryptocurrencyId)`
- `CK_Wallets_Quantity_NonNegative`: `Quantity >= 0.00000000`
- `CK_Wallets_AverageBuyPrice_NonNegative`: `AverageBuyPrice >= 0.00000000`

### 2.5 `dbo.Orders`
Records all user order submissions (Market, Limit) and their lifecycle states.

| Column Name | Data Type | Nullable | Description |
|---|---|---|---|
| `OrderId` | `INT IDENTITY(1,1)` | No | Primary Key |
| `UserId` | `INT` | No | Foreign Key -> `Users(UserId)` |
| `CryptocurrencyId` | `INT` | No | Foreign Key -> `Cryptocurrencies(CryptocurrencyId)` |
| `OrderType` | `NVARCHAR(10)` | No | 'MARKET' or 'LIMIT' |
| `Side` | `NVARCHAR(4)` | No | 'BUY' or 'SELL' |
| `Quantity` | `DECIMAL(18,8)` | No | Requested order quantity |
| `Price` | `DECIMAL(18,8)` | Yes | Target limit price (NULL for MARKET orders) |
| `Status` | `NVARCHAR(20)` | No | 'PENDING', 'FILLED', 'PARTIALLY_FILLED', 'CANCELLED', 'REJECTED' |
| `CreatedDate` | `DATETIME2` | No | Order placement timestamp (UTC) |
| `ExecutedDate` | `DATETIME2` | Yes | Order execution timestamp (UTC) |

**Constraints:**
- `CK_Orders_OrderType`: `OrderType IN ('MARKET', 'LIMIT')`
- `CK_Orders_Side`: `Side IN ('BUY', 'SELL')`
- `CK_Orders_Quantity_Positive`: `Quantity > 0.00000000`
- `CK_Orders_Status`: `Status IN ('PENDING', 'FILLED', 'PARTIALLY_FILLED', 'CANCELLED', 'REJECTED')`

### 2.6 `dbo.Trades`
Records executed trade transactions resulting from filled orders.

| Column Name | Data Type | Nullable | Description |
|---|---|---|---|
| `TradeId` | `INT IDENTITY(1,1)` | No | Primary Key |
| `OrderId` | `INT` | No | Foreign Key -> `Orders(OrderId)` |
| `UserId` | `INT` | No | Foreign Key -> `Users(UserId)` |
| `CryptocurrencyId` | `INT` | No | Foreign Key -> `Cryptocurrencies(CryptocurrencyId)` |
| `Side` | `NVARCHAR(4)` | No | 'BUY' or 'SELL' |
| `Quantity` | `DECIMAL(18,8)` | No | Units executed |
| `Price` | `DECIMAL(18,8)` | No | Execution price per unit in USD |
| `TotalAmount` | `DECIMAL(18,2)` | No | Total trade fiat value (`Quantity * Price`) |
| `RealizedPnL` | `DECIMAL(18,2)` | Yes | Locked-in profit/loss on SELL (0.00 for BUY) |
| `ExecutedDate` | `DATETIME2` | No | Execution timestamp (UTC) |

### 2.7 `dbo.Transactions`
General financial ledger recording all events impacting the user's cash account.

| Column Name | Data Type | Nullable | Description |
|---|---|---|---|
| `TransactionId` | `INT IDENTITY(1,1)` | No | Primary Key |
| `UserId` | `INT` | No | Foreign Key -> `Users(UserId)` |
| `TransactionType` | `NVARCHAR(20)` | No | 'DEPOSIT', 'WITHDRAWAL', 'BUY', 'SELL' |
| `Amount` | `DECIMAL(18,2)` | No | Absolute transaction value in USD |
| `BalanceAfter` | `DECIMAL(18,2)` | No | Resulting cash balance after transaction applied |
| `ReferenceId` | `INT` | Yes | Linked TradeId, DepositId, or WithdrawalId |
| `Description` | `NVARCHAR(255)` | Yes | Human-readable audit narrative |
| `CreatedDate` | `DATETIME2` | No | Transaction recording timestamp (UTC) |

### 2.8 `dbo.Deposits`
Audit table for user cash deposit requests.

| Column Name | Data Type | Nullable | Description |
|---|---|---|---|
| `DepositId` | `INT IDENTITY(1,1)` | No | Primary Key |
| `UserId` | `INT` | No | Foreign Key -> `Users(UserId)` |
| `Amount` | `DECIMAL(18,2)` | No | Deposit amount in USD |
| `Currency` | `NVARCHAR(3)` | No | Fiat currency code (Default: 'USD') |
| `Status` | `NVARCHAR(20)` | No | 'PENDING', 'COMPLETED', 'FAILED' |
| `CreatedDate` | `DATETIME2` | No | Request timestamp (UTC) |
| `CompletedDate` | `DATETIME2` | Yes | Completion timestamp (UTC) |

### 2.9 `dbo.Withdrawals`
Audit table for user cash withdrawal requests.

| Column Name | Data Type | Nullable | Description |
|---|---|---|---|
| `WithdrawalId` | `INT IDENTITY(1,1)` | No | Primary Key |
| `UserId` | `INT` | No | Foreign Key -> `Users(UserId)` |
| `Amount` | `DECIMAL(18,2)` | No | Withdrawal amount in USD |
| `Currency` | `NVARCHAR(3)` | No | Fiat currency code (Default: 'USD') |
| `Status` | `NVARCHAR(20)` | No | 'PENDING', 'COMPLETED', 'FAILED', 'REJECTED' |
| `CreatedDate` | `DATETIME2` | No | Request timestamp (UTC) |
| `CompletedDate` | `DATETIME2` | Yes | Completion timestamp (UTC) |

### 2.10 `dbo.PriceHistory`
Historical time-series log of cryptocurrency market price points.

| Column Name | Data Type | Nullable | Description |
|---|---|---|---|
| `PriceHistoryId` | `BIGINT IDENTITY(1,1)` | No | Primary Key |
| `CryptocurrencyId` | `INT` | No | Foreign Key -> `Cryptocurrencies(CryptocurrencyId)` |
| `Price` | `DECIMAL(18,8)` | No | Recorded market price in USD |
| `RecordedDate` | `DATETIME2` | No | Timestamp of recorded sample (UTC) |

### 2.11 `dbo.__SchemaMigrations`
System migration tracker for native SQL Server version management.

| Column Name | Data Type | Nullable | Description |
|---|---|---|---|
| `MigrationId` | `INT IDENTITY(1,1)` | No | Primary Key |
| `ScriptVersion` | `NVARCHAR(50)` | No | Script release identifier (e.g. '1.0.0') |
| `ScriptName` | `NVARCHAR(255)` | No | Script filename |
| `AppliedDate` | `DATETIME2` | No | Execution timestamp (UTC) |
| `AppliedBy` | `NVARCHAR(100)` | No | System user/account executing the migration |

---

## 3. Database Views

### 3.1 `dbo.vw_UserActiveHoldings`
Calculates real-time holdings, current market value, and unrealized profit/loss per asset:
```sql
SELECT 
    w.UserId,
    w.CryptocurrencyId,
    c.Symbol,
    c.Name,
    w.Quantity,
    w.AverageBuyPrice,
    c.CurrentPrice,
    CAST((w.Quantity * c.CurrentPrice) AS DECIMAL(18,2)) AS CurrentValue,
    CAST((w.Quantity * (c.CurrentPrice - w.AverageBuyPrice)) AS DECIMAL(18,2)) AS UnrealizedPnL,
    CASE 
        WHEN w.AverageBuyPrice > 0 
        THEN CAST(((c.CurrentPrice - w.AverageBuyPrice) / w.AverageBuyPrice * 100.0) AS DECIMAL(9,2))
        ELSE 0.00 
    END AS UnrealizedPnLPercentage,
    w.LastUpdatedDate
FROM dbo.Wallets w
INNER JOIN dbo.Cryptocurrencies c ON w.CryptocurrencyId = c.CryptocurrencyId
WHERE w.Quantity > 0;
```

### 3.2 `dbo.vw_UserPortfolioSummary`
Aggregates overall financial health per user:
```sql
SELECT 
    u.UserId,
    u.Username,
    a.Balance AS CashBalance,
    ISNULL(SUM(w.Quantity * c.CurrentPrice), 0.00) AS CryptoHoldingsValue,
    a.Balance + ISNULL(SUM(w.Quantity * c.CurrentPrice), 0.00) AS TotalPortfolioValue,
    ISNULL(SUM(w.Quantity * (c.CurrentPrice - w.AverageBuyPrice)), 0.00) AS TotalUnrealizedPnL,
    (SELECT ISNULL(SUM(RealizedPnL), 0.00) FROM dbo.Trades WHERE UserId = u.UserId) AS TotalRealizedPnL
FROM dbo.Users u
INNER JOIN dbo.Accounts a ON u.UserId = a.UserId
LEFT JOIN dbo.Wallets w ON u.UserId = w.UserId AND w.Quantity > 0
LEFT JOIN dbo.Cryptocurrencies c ON w.CryptocurrencyId = c.CryptocurrencyId
GROUP BY u.UserId, u.Username, a.Balance;
```

---

## 4. Performance Indexes

- `IX_Accounts_UserId` on `dbo.Accounts(UserId)`
- `IX_Cryptocurrencies_Symbol` on `dbo.Cryptocurrencies(Symbol)`
- `IX_Wallets_UserId` on `dbo.Wallets(UserId)`
- `IX_Orders_UserId_CreatedDate` on `dbo.Orders(UserId, CreatedDate DESC)`
- `IX_Orders_Status` on `dbo.Orders(Status)`
- `IX_Trades_UserId_ExecutedDate` on `dbo.Trades(UserId, ExecutedDate DESC)`
- `IX_Transactions_UserId_CreatedDate` on `dbo.Transactions(UserId, CreatedDate DESC)`
- `IX_PriceHistory_Crypto_Date` on `dbo.PriceHistory(CryptocurrencyId, RecordedDate DESC)`

---

## 5. Migration Execution Strategy

To eliminate reliance on external third-party migration binaries (such as `gomigrate`), the platform utilizes native, idempotent SQL Server migration scripts:

- **Runner Script:** `database/scripts/RunAll.sql` combines all schema DDL, constraints, views, stored procedures, and seed datasets into an idempotent migration execution block.
- **PowerShell Orchestration:** `database/scripts/init-db.ps1` accepts server and database parameters, creates databases if not present, and executes the migration pipeline with full logging and error diagnostics.

