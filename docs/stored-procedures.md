# Stored Procedures Documentation — Microsoft SQL Server

## 1. Overview & Transactional Architecture

The CryptoTrading platform embeds all core business operations into **28 Stored Procedures**. Every procedure modifying user balances, cryptocurrency wallets, or order states enforces ACID guarantees using explicit transaction handling:

```sql
BEGIN TRY
    BEGIN TRANSACTION;
    -- [UPDLOCK, HOLDLOCK row locking]
    -- [Validation & Mutations]
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
```

---

## 2. User & Authentication Stored Procedures

### 2.1 `dbo.usp_RegisterUser`
- **Purpose:** Atomically creates a new user, provisions their default fiat cash account, and optionally credits an initial demo balance (e.g. $10,000.00).
- **Parameters:**
  - `@Username` (`NVARCHAR(50)`): Desired username.
  - `@Email` (`NVARCHAR(100)`): User email.
  - `@PasswordHash` (`NVARCHAR(256)`): PBKDF2 hash.
  - `@FirstName` (`NVARCHAR(50)`): User's first name.
  - `@LastName` (`NVARCHAR(50)`): User's last name.
  - `@InitialBalance` (`DECIMAL(18,2)` = 10000.00): Seed cash allocation.
- **Outputs:** Single-row resultset containing the created `UserId`, `AccountId`, and initial `Balance`.
- **Error Conditions:** Throws error if `Username` or `Email` already exists.

### 2.2 `dbo.usp_GetUserByUsernameOrEmail`
- **Purpose:** Fetches user credentials and profile for authentication.
- **Parameters:**
  - `@UsernameOrEmail` (`NVARCHAR(100)`): Username or email.
- **Outputs:** User record matching username or email.

### 2.3 `dbo.usp_GetUserById`
- **Purpose:** Retrieves user profile by primary key.
- **Parameters:**
  - `@UserId` (`INT`)
- **Outputs:** User profile columns (excluding sensitive internal hash details).

### 2.4 `dbo.usp_UpdateUserProfile`
- **Purpose:** Updates user contact information (first name, last name, email).
- **Parameters:**
  - `@UserId` (`INT`)
  - `@FirstName` (`NVARCHAR(50)`)
  - `@LastName` (`NVARCHAR(50)`)
  - `@Email` (`NVARCHAR(100)`)
- **Outputs:** Returns updated user row.

---

## 3. Account & Balance Procedures

### 3.1 `dbo.usp_GetAccountByUserId`
- **Purpose:** Retrieves the current cash balance and currency for a specific user.
- **Parameters:**
  - `@UserId` (`INT`)
- **Outputs:** `AccountId`, `UserId`, `Balance`, `Currency`, `LastUpdatedDate`.

### 3.2 `dbo.usp_UpdateAccountBalance`
- **Purpose:** Atomically adjusts a user's cash balance and creates an audit ledger record.
- **Parameters:**
  - `@UserId` (`INT`)
  - `@Amount` (`DECIMAL(18,2)`): Signed amount (positive for credit, negative for debit).
  - `@TransactionType` (`NVARCHAR(20)`): 'DEPOSIT', 'WITHDRAWAL', 'BUY', 'SELL'.
  - `@ReferenceId` (`INT` = NULL)
  - `@Description` (`NVARCHAR(255)` = NULL)
- **Concurrency & Locking:** Uses `WITH (UPDLOCK, HOLDLOCK)` on `dbo.Accounts`.
- **Validation:** Ensures `Balance + @Amount >= 0`. If negative balance would result, throws `RAISERROR('Insufficient funds.', 16, 1)`.

---

## 4. Cryptocurrencies & Price Tracking

### 4.1 `dbo.usp_GetCryptocurrencies`
- **Purpose:** Returns the active cryptocurrency catalog along with cached current prices and 24h change percentages.
- **Parameters:** None.
- **Outputs:** Resultset with all active coins ordered by `CryptocurrencyId`.

### 4.2 `dbo.usp_GetCryptocurrencyBySymbol`
- **Purpose:** Looks up a cryptocurrency by ticker symbol (e.g. 'BTC').
- **Parameters:**
  - `@Symbol` (`NVARCHAR(10)`)
- **Outputs:** Single cryptocurrency record.

### 4.3 `dbo.usp_UpdateCryptoPrice`
- **Purpose:** Updates the current price and 24h percentage change in `dbo.Cryptocurrencies` and appends an entry to `dbo.PriceHistory`.
- **Parameters:**
  - `@CryptocurrencyId` (`INT`)
  - `@Price` (`DECIMAL(18,8)`)
  - `@PriceChange24h` (`DECIMAL(9,4)` = 0.00)
- **Outputs:** Returns affected `CryptocurrencyId` and `LastUpdated`.

### 4.4 `dbo.usp_GetLatestCryptoPrice`
- **Purpose:** Fast lookup of the latest cached price for a given cryptocurrency symbol.
- **Parameters:**
  - `@Symbol` (`NVARCHAR(10)`)
- **Outputs:** Single-row scalar containing `CurrentPrice`.

---

## 5. Wallets & Crypto Holdings

### 5.1 `dbo.usp_GetUserWallets`
- **Purpose:** Returns all cryptocurrency wallets belonging to a user.
- **Parameters:**
  - `@UserId` (`INT`)
- **Outputs:** `WalletId`, `Symbol`, `Name`, `Quantity`, `AverageBuyPrice`, `LastUpdatedDate`.

### 5.2 `dbo.usp_GetWalletByUserAndCrypto`
- **Purpose:** Retrieves a user's wallet for a specific cryptocurrency.
- **Parameters:**
  - `@UserId` (`INT`)
  - `@CryptocurrencyId` (`INT`)
- **Outputs:** Wallet record or empty resultset if no wallet exists.

### 5.3 `dbo.usp_UpdateWalletBalance`
- **Purpose:** Internal procedure for adjusting cryptocurrency wallet balances and maintaining average cost basis.
- **Parameters:**
  - `@UserId` (`INT`)
  - `@CryptocurrencyId` (`INT`)
  - `@QuantityDelta` (`DECIMAL(18,8)`)
  - `@Price` (`DECIMAL(18,8)`)

---

## 6. Orders & Order Lifecycle

### 6.1 `dbo.usp_CreateOrder`
- **Purpose:** Places a new BUY or SELL order. For MARKET orders, immediately calls the trade execution pipeline. For LIMIT orders, leaves status as 'PENDING'.
- **Parameters:**
  - `@UserId` (`INT`)
  - `@CryptocurrencyId` (`INT`)
  - `@OrderType` (`NVARCHAR(10)`): 'MARKET' or 'LIMIT'
  - `@Side` (`NVARCHAR(4)`): 'BUY' or 'SELL'
  - `@Quantity` (`DECIMAL(18,8)`)
  - `@Price` (`DECIMAL(18,8)` = NULL)
- **Outputs:** Created `OrderId`, `Status`, `CreatedDate`.

### 6.2 `dbo.usp_GetOrderById`
- **Purpose:** Retrieves detailed order status by ID.
- **Parameters:**
  - `@OrderId` (`INT`)
  - `@UserId` (`INT`)
- **Outputs:** Order record joined with cryptocurrency symbol and name.

### 6.3 `dbo.usp_GetUserOrders`
- **Purpose:** Retrieves user order history with optional status filter.
- **Parameters:**
  - `@UserId` (`INT`)
  - `@Status` (`NVARCHAR(20)` = NULL)
- **Outputs:** Chronological list of orders (newest first).

### 6.4 `dbo.usp_CancelOrder`
- **Purpose:** Cancels a 'PENDING' limit order.
- **Parameters:**
  - `@OrderId` (`INT`)
  - `@UserId` (`INT`)
- **Concurrency & Locking:** Uses `WITH (UPDLOCK, HOLDLOCK)`.
- **Validation:** Throws error if order is already filled or cancelled.

---

## 7. Trade Execution (Atomic Trading Core)

### 7.1 `dbo.usp_ExecuteBuyTrade`
- **Purpose:** Core atomic procedure for executing a BUY order.
- **Parameters:**
  - `@OrderId` (`INT`)
  - `@ExecutionPrice` (`DECIMAL(18,8)`)
- **Execution Workflow:**
  1. Acquires `UPDLOCK, HOLDLOCK` on `dbo.Orders` and verifies status is eligible.
  2. Calculates `TotalCost = Quantity * ExecutionPrice`.
  3. Acquires `UPDLOCK, HOLDLOCK` on `dbo.Accounts` for the user.
  4. Verifies `Balance >= TotalCost`. Throws `RAISERROR('Insufficient cash balance to execute BUY order.', 16, 1)` if insufficient.
  5. Deducts `TotalCost` from `dbo.Accounts`.
  6. Upserts `dbo.Wallets` with `UPDLOCK, HOLDLOCK`, recalculating weighted `AverageBuyPrice`:
     $$\text{NewAvg} = \frac{(\text{Qty}_{\text{old}} \times \text{Avg}_{\text{old}}) + (\text{Qty}_{\text{buy}} \times \text{Price})}{\text{Qty}_{\text{old}} + \text{Qty}_{\text{buy}}}$$
  7. Inserts `dbo.Trades` record with `RealizedPnL = 0.00`.
  8. Inserts `dbo.Transactions` ledger entry (`TransactionType = 'BUY'`).
  9. Updates `dbo.Orders` to `Status = 'FILLED'`.
- **Outputs:** Returns trade execution summary (`TradeId`, `OrderId`, `Quantity`, `Price`, `TotalAmount`, `NewCashBalance`).

### 7.2 `dbo.usp_ExecuteSellTrade`
- **Purpose:** Core atomic procedure for executing a SELL order.
- **Parameters:**
  - `@OrderId` (`INT`)
  - `@ExecutionPrice` (`DECIMAL(18,8)`)
- **Execution Workflow:**
  1. Acquires `UPDLOCK, HOLDLOCK` on `dbo.Orders`.
  2. Acquires `UPDLOCK, HOLDLOCK` on `dbo.Wallets` for the user and cryptocurrency.
  3. Verifies `Quantity >= SellQuantity`. Throws `RAISERROR('Insufficient cryptocurrency balance to execute SELL order.', 16, 1)` if insufficient.
  4. Calculates `TotalProceeds = SellQuantity * ExecutionPrice`.
  5. Calculates `RealizedPnL = (ExecutionPrice - AverageBuyPrice) * SellQuantity`.
  6. Decrements `dbo.Wallets.Quantity`.
  7. Acquires `UPDLOCK, HOLDLOCK` on `dbo.Accounts` and adds `TotalProceeds`.
  8. Inserts `dbo.Trades` record including calculated `RealizedPnL`.
  9. Inserts `dbo.Transactions` ledger entry (`TransactionType = 'SELL'`).
  10. Updates `dbo.Orders` to `Status = 'FILLED'`.
- **Outputs:** Returns trade execution summary including `RealizedPnL` and `NewCashBalance`.

### 7.3 `dbo.usp_GetUserTrades`
- **Purpose:** Retrieves all trades executed by a user.
- **Parameters:**
  - `@UserId` (`INT`)
- **Outputs:** List of trades with symbol, price, quantity, total amount, and realized P/L.

### 7.4 `dbo.usp_GetTradeById`
- **Purpose:** Fetches a single trade by ID.
- **Parameters:**
  - `@TradeId` (`INT`)
  - `@UserId` (`INT`)
- **Outputs:** Detailed trade record.

---

## 8. Portfolio Valuation Procedures

### 8.1 `dbo.usp_GetUserPortfolioSummary`
- **Purpose:** High-performance summary of a user's total financial position.
- **Parameters:**
  - `@UserId` (`INT`)
- **Outputs:** `CashBalance`, `CryptoHoldingsValue`, `TotalPortfolioValue`, `TotalUnrealizedPnL`, `TotalRealizedPnL`.

### 8.2 `dbo.usp_GetUserActiveHoldings`
- **Purpose:** Returns all non-zero cryptocurrency holdings with cost basis, current market price, and unrealized profit/loss.
- **Parameters:**
  - `@UserId` (`INT`)
- **Outputs:** Collection of active holdings (`Symbol`, `Name`, `Quantity`, `AverageBuyPrice`, `CurrentPrice`, `CurrentValue`, `UnrealizedPnL`, `UnrealizedPnLPercentage`).

---

## 9. Deposits, Withdrawals & Ledger

### 9.1 `dbo.usp_CreateDeposit`
- **Purpose:** Records a simulated fiat deposit and immediately credits the user's cash balance.
- **Parameters:**
  - `@UserId` (`INT`)
  - `@Amount` (`DECIMAL(18,2)`)
  - `@Currency` (`NVARCHAR(3)` = 'USD')
- **Outputs:** Created `DepositId`, `Status`, `NewBalance`.

### 9.2 `dbo.usp_GetUserDeposits`
- **Purpose:** Returns chronological deposit history for a user.
- **Parameters:**
  - `@UserId` (`INT`)

### 9.3 `dbo.usp_CreateWithdrawal`
- **Purpose:** Validates available cash balance, records withdrawal, and deducts funds atomically.
- **Parameters:**
  - `@UserId` (`INT`)
  - `@Amount` (`DECIMAL(18,2)`)
  - `@Currency` (`NVARCHAR(3)` = 'USD')
- **Concurrency & Locking:** Locks `dbo.Accounts` with `UPDLOCK, HOLDLOCK`. If `Balance < Amount`, rejects with `RAISERROR('Insufficient funds for withdrawal.', 16, 1)`.
- **Outputs:** Created `WithdrawalId`, `Status`, `NewBalance`.

### 9.4 `dbo.usp_GetUserWithdrawals`
- **Purpose:** Returns chronological withdrawal history for a user.
- **Parameters:**
  - `@UserId` (`INT`)

### 9.5 `dbo.usp_RecordTransaction`
- **Purpose:** Internal audit ledger insertion procedure.
- **Parameters:**
  - `@UserId` (`INT`)
  - `@TransactionType` (`NVARCHAR(20)`)
  - `@Amount` (`DECIMAL(18,2)`)
  - `@BalanceAfter` (`DECIMAL(18,2)`)
  - `@ReferenceId` (`INT` = NULL)
  - `@Description` (`NVARCHAR(255)` = NULL)

### 9.6 `dbo.usp_GetUserTransactions`
- **Purpose:** Fetches the complete financial statement / ledger of cash balance events for the user.
- **Parameters:**
  - `@UserId` (`INT`)
- **Outputs:** All cash movements (`DEPOSIT`, `WITHDRAWAL`, `BUY`, `SELL`) sorted newest first.

