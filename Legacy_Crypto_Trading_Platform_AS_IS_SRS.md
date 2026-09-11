# Software Requirements Specification (SRS)
# Legacy Cryptocurrency Trading Platform — AS-IS

## 1. Document Purpose

This document defines the requirements for a cryptocurrency paper-trading platform implemented as a legacy enterprise application.

The system is intentionally specified as an **AS-IS legacy application**. The requirements in this document describe the system that must be built and operated. No future-state architecture, technology uplift, modernization strategy, or migration approach is part of this specification.

The application must provide realistic cryptocurrency trading, portfolio management, account funding, withdrawals, transaction history, and market-data functionality.

The system is a **paper-trading/demo platform**. It must not execute real cryptocurrency purchases, real cryptocurrency transfers, or real-money payment transactions.

---

# 2. System Scope

The system shall provide:

- User registration and authentication
- User profile management
- Individual user accounts
- Simulated fiat balance
- Cryptocurrency market listings
- Current cryptocurrency market prices
- Cryptocurrency holdings
- Buy orders
- Sell orders
- Order history
- Trade execution
- Portfolio valuation
- Realized profit/loss
- Unrealized profit/loss
- Simulated deposits
- Simulated withdrawals
- Financial transaction history
- External cryptocurrency market-data integration

The application shall support multiple independent users.

Each user shall have their own account, portfolio, holdings, orders, trades, and transactions.

---

# 3. Technology Stack

## 3.1 Backend

The backend shall use:

- C#
- .NET Framework 4.7
- ASP.NET Web API 2
- IIS-compatible application hosting
- ADO.NET
- SQL Server Stored Procedures
- JSON REST APIs

The backend shall be implemented as a traditional monolithic application.

## 3.2 Database

The database shall use:

- Microsoft SQL Server
- SQL Server database transactions
- Tables
- Views where appropriate
- Stored Procedures
- Indexes
- Foreign keys
- Constraints

## 3.3 Frontend

The frontend shall use:

- React
- JavaScript or TypeScript as appropriate
- REST API communication with the backend

The frontend shall not directly access SQL Server.

## 3.4 Infrastructure

SQL Server shall be capable of running in Docker.

A Docker Compose configuration shall be provided for the SQL Server development environment.

The .NET Framework backend may run directly on Windows/IIS or another compatible Windows hosting environment.

---

# 4. AS-IS Architecture

The application shall follow a traditional layered monolithic architecture.

```text
+---------------------------+
|       React Frontend      |
+-------------+-------------+
              |
              | HTTP / REST / JSON
              v
+---------------------------+
| ASP.NET Web API           |
| .NET Framework 4.7        |
+-------------+-------------+
              |
              v
+---------------------------+
| Business Layer            |
+-------------+-------------+
              |
              v
+---------------------------+
| Data Access Layer         |
| ADO.NET / Repositories    |
+-------------+-------------+
              |
              | Stored Procedure Calls
              v
+---------------------------+
| Microsoft SQL Server      |
|                           |
| Tables                    |
| Views                     |
| Stored Procedures         |
+---------------------------+

+---------------------------+
| External Crypto Market API|
+-------------+-------------+
              ^
              |
+-------------+-------------+
| Crypto Market Service     |
| in .NET Framework Backend |
+---------------------------+
```

The system shall be deployed as a monolithic backend application.

---

# 5. Project Structure

A suitable Visual Studio solution shall contain:

```text
CryptoTradingPlatform/
│
├── CryptoTradingPlatform.sln
│
├── src/
│   ├── CryptoTrading.Web/
│   ├── CryptoTrading.Business/
│   ├── CryptoTrading.Data/
│   ├── CryptoTrading.Models/
│   └── CryptoTrading.Infrastructure/
│
├── tests/
│   └── CryptoTrading.Tests/
│
├── database/
│   ├── schema/
│   ├── stored-procedures/
│   │   ├── Users/
│   │   ├── Accounts/
│   │   ├── Cryptocurrencies/
│   │   ├── Portfolios/
│   │   ├── Wallets/
│   │   ├── Orders/
│   │   ├── Trades/
│   │   ├── Transactions/
│   │   ├── Deposits/
│   │   └── Withdrawals/
│   ├── views/
│   ├── seed/
│   └── scripts/
│
├── docker/
│   └── docker-compose.yml
│
└── docs/
    ├── architecture.md
    ├── database.md
    ├── stored-procedures.md
    └── api.md
```

The exact project names may be adjusted if required by the implementation, but the resulting solution shall remain a monolithic .NET Framework 4.7 application.

---

# 6. Database Access Requirements

## 6.1 Stored Procedures

SQL Server Stored Procedures shall be the primary mechanism for runtime application/database interaction.

Application runtime code shall not primarily use inline SQL statements such as:

```sql
SELECT ...
INSERT ...
UPDATE ...
DELETE ...
```

embedded directly in C# application code.

The Data Access Layer shall invoke stored procedures using ADO.NET.

Example:

```csharp
using (SqlCommand command = new SqlCommand(
    "usp_GetUserPortfolio",
    connection))
{
    command.CommandType = CommandType.StoredProcedure;
    command.Parameters.AddWithValue("@UserId", userId);
}
```

## 6.2 Database-Centric Business Operations

A substantial amount of business and transactional logic shall reside in SQL Server stored procedures.

Stored procedures shall handle operations including:

- Account balance validation
- Account balance updates
- Wallet updates
- Order creation
- Trade execution
- Trade validation
- Portfolio calculations
- Profit/loss calculations
- Transaction ledger creation
- Deposit processing
- Withdrawal processing
- Financial validations

## 6.3 Raw SQL

Raw SQL shall not be the normal application runtime mechanism.

Inline SQL may be used in database scripts for:

- Database creation
- Table creation
- Index creation
- Stored procedure creation
- Seed scripts
- Administrative/development scripts

Runtime business operations shall use stored procedures.

---

# 7. Stored Procedure Naming

Stored procedures shall follow the naming convention:

```text
usp_<Action><Entity>
```

Examples:

```text
usp_CreateUser
usp_GetUserById
usp_GetUserByEmail
usp_CreateAccount
usp_GetAccountBalance
usp_GetCryptocurrencies
usp_GetCryptocurrencyBySymbol
usp_SaveCryptoPrice
usp_GetPortfolio
usp_GetPortfolioHoldings
usp_CreateOrder
usp_ExecuteBuyOrder
usp_ExecuteSellOrder
usp_GetOrdersByUser
usp_CreateTransaction
usp_ProcessDeposit
usp_ProcessWithdrawal
```

---

# 8. Database Schema

The system shall contain at least the following tables.

## 8.1 Users

```text
UserId
Username
Email
PasswordHash
FirstName
LastName
CreatedDate
LastLoginDate
IsActive
```

Constraints shall ensure that username and email values are appropriately unique.

## 8.2 Accounts

```text
AccountId
UserId
Currency
AvailableBalance
CreatedDate
UpdatedDate
```

A user shall have an account containing the simulated fiat balance.

## 8.3 Cryptocurrencies

```text
CryptocurrencyId
Symbol
Name
CurrentPrice
PriceChange24h
LastUpdated
IsActive
```

## 8.4 Wallets

```text
WalletId
UserId
Currency
Quantity
AverageCost
CreatedDate
UpdatedDate
```

A wallet represents a user's cryptocurrency holding.

## 8.5 Orders

```text
OrderId
UserId
Symbol
OrderType
Side
Quantity
Price
TotalValue
Status
CreatedDate
ExecutedDate
```

Possible order types:

```text
Market
Limit
```

The initial implementation shall support Market orders.

Possible statuses:

```text
Pending
Executed
Cancelled
Rejected
```

## 8.6 Trades

```text
TradeId
OrderId
UserId
Symbol
Side
Quantity
ExecutionPrice
TotalValue
RealizedProfitLoss
ExecutedDate
```

## 8.7 Transactions

```text
TransactionId
UserId
TransactionType
Currency
Amount
ReferenceId
Status
CreatedDate
```

Transaction types shall include:

```text
BUY
SELL
DEPOSIT
WITHDRAWAL
```

## 8.8 Deposits

```text
DepositId
UserId
Amount
Currency
Status
CreatedDate
ProcessedDate
```

## 8.9 Withdrawals

```text
WithdrawalId
UserId
Amount
Currency
Status
CreatedDate
ProcessedDate
```

## 8.10 PriceHistory

```text
PriceHistoryId
CryptocurrencyId
Price
RecordedDate
```

---

# 9. User Management

The system shall support multiple users.

Users shall be able to:

- Register
- Log in
- Log out
- View their profile
- Update their profile
- View account information

Users shall only be able to access their own account data.

---

# 10. Registration

The registration page shall collect:

- First name
- Last name
- Email
- Username
- Password

Passwords shall never be stored as plaintext.

The backend shall validate:

- Required fields
- Valid email format
- Username uniqueness
- Email uniqueness
- Password requirements

User creation shall be performed through a stored procedure.

Example:

```text
usp_CreateUser
```

---

# 11. Authentication

The backend shall provide authentication APIs.

```http
POST /api/auth/register
POST /api/auth/login
POST /api/auth/logout
GET  /api/auth/me
```

The implementation shall use an authentication mechanism compatible with ASP.NET Web API 2 and .NET Framework 4.7.

Protected endpoints shall require an authenticated user.

---

# 12. Authorization

The backend shall ensure that users cannot access another user's:

- Account
- Balance
- Portfolio
- Holdings
- Orders
- Trades
- Transactions
- Deposits
- Withdrawals
- Profile information

User identity shall be obtained from the authenticated request rather than trusting a user identifier supplied by the frontend.

---

# 13. Cryptocurrency Market Data

The system shall integrate with a publicly available cryptocurrency market-data API.

Potential providers include:

- CoinGecko
- Binance public market APIs
- Coinbase APIs
- Kraken APIs

The implementation shall select one provider and document the chosen provider and API endpoints.

The external API shall provide, where available:

- Cryptocurrency name
- Symbol
- Current price
- 24-hour price change
- Market information
- Historical price information

The system shall not depend on the external API for historical trade records.

---

# 14. Market Data Service

The backend shall contain a market-data service responsible for communicating with the external cryptocurrency API.

Example:

```text
ICryptoMarketService
CryptoMarketService
```

The service shall:

1. Call the external API.
2. Deserialize the response.
3. Validate the response.
4. Map the provider-specific response into application models.
5. Provide market information to the rest of the application.
6. Persist applicable price information using stored procedures.

The external API provider's response format shall not be exposed directly to the React frontend.

---

# 15. Cryptocurrency Listing

The backend shall expose:

```http
GET /api/cryptocurrencies
GET /api/cryptocurrencies/{symbol}
```

The response shall contain information such as:

```json
[
  {
    "symbol": "BTC",
    "name": "Bitcoin",
    "price": 65000.00,
    "change24h": 2.30
  }
]
```

The frontend shall display the available cryptocurrencies.

---

# 16. Portfolio

Each user shall have an independent portfolio.

The portfolio shall show:

- Total portfolio value
- Available cash
- Invested value
- Cryptocurrency holdings
- Current market value
- Average purchase price
- Unrealized profit/loss
- Realized profit/loss
- Total profit/loss

Example:

```text
Portfolio Value:       $25,000
Cash Balance:           $5,000
Invested Value:        $20,000
Unrealized P/L:         $2,500
Realized P/L:           $1,200
Total P/L:              $3,700
```

---

# 17. Portfolio Stored Procedures

The database shall provide procedures such as:

```text
usp_GetPortfolio
usp_GetPortfolioHoldings
usp_GetPortfolioSummary
usp_GetPortfolioPerformance
usp_GetUnrealizedProfitLoss
usp_GetRealizedProfitLoss
```

Portfolio calculations may be performed within these stored procedures using data from:

- Wallets
- Trades
- Transactions
- Cryptocurrency prices

---

# 18. Profit and Loss

## 18.1 Unrealized P/L

The system shall calculate unrealized P/L using:

```text
Current Market Value - Cost Basis
```

Where:

```text
Current Market Value = Quantity × Current Market Price
```

## 18.2 Realized P/L

Realized P/L shall be calculated when cryptocurrency holdings are sold.

For example:

```text
Purchase:
0.1 BTC @ $60,000

Sale:
0.1 BTC @ $65,000

Realized P/L:
$500
```

The realized P/L associated with the trade shall be persisted.

## 18.3 Total P/L

The system shall provide:

```text
Total P/L =
Realized P/L + Unrealized P/L
```

---

# 19. Buying Cryptocurrency

Users shall be able to place simulated BUY orders.

The request shall contain:

- Cryptocurrency symbol
- Quantity
- Order type

Example:

```json
{
  "symbol": "BTC",
  "quantity": 0.05,
  "orderType": "MARKET"
}
```

The backend shall determine the applicable market price.

---

# 20. BUY Transaction Processing

The BUY operation shall be implemented primarily through a SQL Server stored procedure.

Example:

```text
usp_ExecuteBuyOrder
```

The procedure shall:

1. Validate the user.
2. Validate the cryptocurrency.
3. Validate the quantity.
4. Validate the supplied/current execution price.
5. Calculate trade value.
6. Validate available cash.
7. Create the order.
8. Create the trade.
9. Deduct cash from the account.
10. Create or update the wallet holding.
11. Update average cost.
12. Create a transaction ledger entry.
13. Mark the order as executed.
14. Commit the database transaction.

All related database changes shall occur atomically.

---

# 21. Selling Cryptocurrency

Users shall be able to place simulated SELL orders.

Example:

```json
{
  "symbol": "BTC",
  "quantity": 0.02,
  "orderType": "MARKET"
}
```

The backend shall determine the applicable execution price.

---

# 22. SELL Transaction Processing

The SELL operation shall use:

```text
usp_ExecuteSellOrder
```

The procedure shall:

1. Validate the user.
2. Validate the cryptocurrency.
3. Validate the quantity.
4. Validate ownership.
5. Validate available cryptocurrency quantity.
6. Calculate trade value.
7. Calculate realized P/L.
8. Create the order.
9. Create the trade.
10. Reduce the wallet holding.
11. Increase the account cash balance.
12. Create a transaction ledger entry.
13. Mark the order as executed.
14. Commit the database transaction.

---

# 23. SQL Server Transaction Handling

BUY, SELL, DEPOSIT, and WITHDRAWAL operations shall use SQL Server transactions.

Example:

```sql
BEGIN TRY

    BEGIN TRANSACTION;

    -- Validate
    -- Create order
    -- Create trade
    -- Update balance
    -- Update wallet
    -- Create ledger entry

    COMMIT TRANSACTION;

END TRY
BEGIN CATCH

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    THROW;

END CATCH;
```

The exact implementation shall be compatible with the SQL Server version used by the project.

---

# 24. Balance Validation

The database shall prevent financial inconsistencies.

A BUY operation shall only succeed when:

```text
TradeValue <= AvailableBalance
```

A SELL operation shall only succeed when:

```text
QuantityToSell <= OwnedQuantity
```

A withdrawal shall only succeed when:

```text
WithdrawalAmount <= AvailableBalance
```

The validation shall occur on the server/database side.

---

# 25. Concurrency

The system shall account for concurrent financial operations.

Examples:

- Two simultaneous withdrawals must not spend the same balance.
- Two simultaneous BUY orders must not both consume unavailable funds.
- Two simultaneous SELL orders must not sell the same cryptocurrency twice.
- Account balances must not become negative due to concurrent requests.

Appropriate SQL Server transaction and locking behavior shall be used.

---

# 26. Orders

The system shall provide order history.

Users shall be able to view:

- Order ID
- Cryptocurrency
- BUY/SELL
- Quantity
- Price
- Total value
- Order type
- Status
- Created time
- Executed time

APIs:

```http
GET /api/orders
GET /api/orders/{id}
POST /api/orders
POST /api/orders/{id}/cancel
```

---

# 27. Order Cancellation

The system shall support cancellation of eligible orders.

An executed order shall not be cancellable.

A cancelled order shall retain its history.

The cancellation operation shall use a stored procedure such as:

```text
usp_CancelOrder
```

---

# 28. Deposits

The system shall provide simulated deposits.

API:

```http
POST /api/deposits
GET  /api/deposits
```

Example:

```json
{
  "amount": 5000,
  "currency": "USD"
}
```

The deposit operation shall:

1. Validate the user.
2. Validate the amount.
3. Create a deposit record.
4. Update the account balance.
5. Create a transaction ledger entry.
6. Commit the database transaction.

Stored procedure:

```text
usp_ProcessDeposit
```

---

# 29. Withdrawals

The system shall provide simulated withdrawals.

API:

```http
POST /api/withdrawals
GET  /api/withdrawals
```

Example:

```json
{
  "amount": 1500,
  "currency": "USD"
}
```

The withdrawal operation shall:

1. Validate the user.
2. Validate the amount.
3. Validate available balance.
4. Create a withdrawal record.
5. Deduct the account balance.
6. Create a transaction ledger entry.
7. Commit the database transaction.

Stored procedure:

```text
usp_ProcessWithdrawal
```

---

# 30. Transaction Ledger

Every financial operation shall create an appropriate transaction record.

Supported transaction types:

```text
DEPOSIT
WITHDRAWAL
BUY
SELL
```

The transaction ledger shall provide an auditable history of account activity.

API:

```http
GET /api/transactions
GET /api/transactions/{id}
```

Stored procedures:

```text
usp_CreateTransaction
usp_GetTransactionsByUser
usp_GetTransactionById
```

---

# 31. Account Balance

The account shall maintain a simulated fiat balance.

Initially use:

```text
USD
```

The system shall use an appropriate SQL Server decimal type for monetary values.

Floating-point types shall not be used for monetary database values.

---

# 32. Wallet Holdings

A user may hold multiple cryptocurrencies.

Example:

```text
BTC    0.25000000
ETH    2.50000000
SOL    10.00000000
```

The wallet shall maintain:

- Currency
- Quantity
- Average cost
- Created timestamp
- Updated timestamp

Wallet updates associated with BUY and SELL operations shall occur within the same database transaction as the corresponding trade.

---

# 33. API Specification

## Authentication

```http
POST /api/auth/register
POST /api/auth/login
POST /api/auth/logout
GET  /api/auth/me
```

## Cryptocurrency

```http
GET /api/cryptocurrencies
GET /api/cryptocurrencies/{symbol}
```

## Portfolio

```http
GET /api/portfolio
GET /api/portfolio/holdings
GET /api/portfolio/performance
```

## Orders

```http
GET  /api/orders
GET  /api/orders/{id}
POST /api/orders
POST /api/orders/{id}/cancel
```

## Trading

```http
POST /api/trades/buy
POST /api/trades/sell
```

## Transactions

```http
GET /api/transactions
GET /api/transactions/{id}
```

## Deposits

```http
POST /api/deposits
GET  /api/deposits
```

## Withdrawals

```http
POST /api/withdrawals
GET  /api/withdrawals
```

## Profile

```http
GET /api/profile
PUT /api/profile
```

---

# 34. API Response Format

The API shall use JSON.

Successful responses may contain:

```json
{
  "success": true,
  "data": {}
}
```

Errors shall use a consistent structure:

```json
{
  "success": false,
  "message": "Insufficient balance",
  "errorCode": "INSUFFICIENT_FUNDS"
}
```

Appropriate HTTP status codes shall be returned.

Examples:

```text
200 OK
201 Created
400 Bad Request
401 Unauthorized
403 Forbidden
404 Not Found
409 Conflict
500 Internal Server Error
```

---

# 35. React Frontend

The React frontend shall communicate exclusively with the REST API.

It shall not connect directly to SQL Server.

The frontend shall contain the following screens.

## 35.1 Login

Fields:

- Username/email
- Password

Actions:

- Login
- Register

## 35.2 Registration

Fields:

- First name
- Last name
- Email
- Username
- Password

## 35.3 Dashboard

Display:

- Portfolio value
- Cash balance
- Total P/L
- Unrealized P/L
- Realized P/L
- Major holdings
- Market overview

## 35.4 Trading

Display:

- Cryptocurrency selector
- Current price
- BUY/SELL selector
- Quantity
- Estimated trade value
- Order type
- Submit order

## 35.5 Portfolio

Display:

- Cryptocurrency
- Quantity
- Average cost
- Current price
- Current value
- P/L

## 35.6 Orders

Display:

- Order history
- Order status
- Side
- Quantity
- Price
- Total
- Timestamp

## 35.7 Transactions

Display:

- Transaction type
- Amount
- Currency
- Status
- Date
- Reference

## 35.8 Funds

Provide:

- Current balance
- Deposit
- Withdrawal
- Deposit history
- Withdrawal history

## 35.9 Profile

Display and allow editing of:

- First name
- Last name
- Email
- Username

---

# 36. Frontend Financial Logic

The React application shall not be authoritative for financial operations.

The frontend may display calculations for presentation purposes, but the backend/database shall determine:

- Available balance
- Holdings
- Trade eligibility
- Execution price
- Trade value
- Realized P/L
- Unrealized P/L
- Withdrawal eligibility

A malicious or modified frontend request shall not be capable of bypassing server-side validation.

---

# 37. Configuration

Configuration shall use traditional .NET Framework configuration mechanisms.

Use:

```text
Web.config
Web.Debug.config
Web.Release.config
```

where appropriate.

Configuration shall include:

- SQL Server connection string
- External crypto API configuration
- Authentication configuration
- Application settings
- Logging configuration
- CORS configuration

Secrets shall not be hard-coded into source code.

---

# 38. SQL Server Docker Configuration

Provide:

```text
docker/docker-compose.yml
```

The SQL Server container shall provide:

- Persistent database storage
- SQL Server configuration
- Credentials through environment variables
- Database initialization support

Example architecture:

```text
Windows Development Machine
|
+-- Visual Studio
|    |
|    +-- .NET Framework 4.7 Backend
|
+-- React Frontend
|
+-- Docker
     |
     +-- SQL Server
```

---

# 39. Database Initialization

Provide scripts for:

1. Database creation
2. Table creation
3. Constraints
4. Indexes
5. Views
6. Stored Procedures
7. Seed data

Scripts shall be executable in a predictable order.

---

# 40. Seed Data

Provide demo data.

At minimum create:

- Several users
- Cryptocurrency records
- Sample account balances
- Sample cryptocurrency holdings
- Sample orders
- Sample trades
- Sample deposits
- Sample withdrawals
- Sample transaction history

The seed data shall allow the application to display meaningful portfolio information immediately after setup.

Use fictitious demo credentials.

Do not use real financial credentials.

---

# 41. Logging

The backend shall provide application logging.

A legacy-compatible logging framework such as log4net may be used.

Log:

- Application errors
- Authentication events
- External API errors
- Trade execution failures
- Deposits
- Withdrawals
- Unexpected exceptions
- Important application events

Logs shall not contain plaintext passwords or sensitive authentication credentials.

---

# 42. Error Handling

The backend shall provide centralized exception handling appropriate for ASP.NET Web API 2.

Exceptions shall be logged.

Clients shall receive consistent JSON error responses.

Database exceptions shall not expose raw SQL Server implementation details to the frontend.

---

# 43. Security Requirements

The application shall implement basic application security.

Requirements include:

- Password hashing
- Authentication
- Authorization
- Input validation
- SQL injection protection
- Parameterized stored procedure calls
- CORS configuration
- Server-side financial validation
- User-resource authorization
- No plaintext passwords
- No credentials committed to source control

Stored procedure parameters shall be passed using parameterized `SqlCommand` objects.

---

# 44. Data Types

Financial values shall use SQL Server decimal/numeric types.

Examples:

```text
decimal(18,2)
decimal(28,8)
```

The selected precision shall be documented.

Cryptocurrency quantities may require greater precision than fiat currency amounts.

The application shall use compatible C# decimal types when handling monetary values.

---

# 45. Testing

Provide a test project compatible with .NET Framework 4.7.

Tests shall cover at least:

- User registration
- Login
- Authorization
- Deposit
- Withdrawal
- Insufficient balance
- BUY
- SELL
- Insufficient holdings
- Portfolio calculation
- Realized P/L
- Unrealized P/L
- Order cancellation
- Transaction creation
- Stored procedure execution
- Transaction rollback

Database integration tests shall verify important stored-procedure-driven operations.

---

# 46. Stored Procedure Inventory

At minimum, provide procedures in the following areas.

## Users

```text
usp_CreateUser
usp_GetUserById
usp_GetUserByUsername
usp_GetUserByEmail
usp_UpdateUser
usp_UpdateLastLogin
```

## Accounts

```text
usp_CreateAccount
usp_GetAccount
usp_GetAccountBalance
```

## Cryptocurrencies

```text
usp_GetCryptocurrencies
usp_GetCryptocurrencyBySymbol
usp_SaveCryptoPrice
usp_GetLatestCryptoPrice
usp_GetCryptoPriceHistory
```

## Wallets

```text
usp_GetWallets
usp_GetWalletHolding
usp_CreateWallet
usp_UpdateWalletHolding
```

## Portfolio

```text
usp_GetPortfolio
usp_GetPortfolioHoldings
usp_GetPortfolioSummary
usp_GetPortfolioPerformance
```

## Orders

```text
usp_CreateOrder
usp_GetOrder
usp_GetOrdersByUser
usp_GetOpenOrders
usp_GetCompletedOrders
usp_UpdateOrderStatus
usp_CancelOrder
```

## Trades

```text
usp_ExecuteBuyOrder
usp_ExecuteSellOrder
usp_GetTradesByUser
```

## Transactions

```text
usp_CreateTransaction
usp_GetTransactionsByUser
usp_GetTransactionById
```

## Deposits

```text
usp_ProcessDeposit
usp_GetDepositsByUser
```

## Withdrawals

```text
usp_ProcessWithdrawal
usp_GetWithdrawalsByUser
```

The implementation may add additional procedures as required.

---

# 47. Stored Procedure Documentation

Every stored procedure shall document:

- Purpose
- Input parameters
- Output/result set
- Tables accessed
- Tables modified
- Transaction behavior
- Validation performed
- Error behavior

Example:

```text
Procedure:
usp_ExecuteBuyOrder

Purpose:
Execute a simulated cryptocurrency BUY transaction.

Inputs:
@UserId
@Symbol
@Quantity
@ExecutionPrice

Operations:
- Validate account
- Validate balance
- Create order
- Create trade
- Update account
- Update wallet
- Create transaction
- Update order status

Transaction:
SQL Server transaction required.

Failure:
All changes rolled back.
```

---

# 48. Application Layer Responsibilities

## Controllers

Controllers shall:

- Receive HTTP requests
- Validate request structure
- Identify the authenticated user
- Call business services
- Return HTTP responses

Controllers shall not contain large amounts of database code.

## Business Layer

The business layer shall:

- Coordinate application operations
- Validate application-level rules
- Call repositories/data-access components
- Call external market-data services
- Map application models

## Data Access Layer

The Data Access Layer shall:

- Open SQL connections
- Create `SqlCommand` objects
- Set `CommandType.StoredProcedure`
- Pass parameters
- Execute stored procedures
- Read result sets
- Map database results into models
- Handle database-related exceptions

---

# 49. Database Business Logic

The following operations shall be database-centric:

```text
Account balance updates
Wallet quantity updates
Average-cost updates
Trade execution
Order state updates
Transaction ledger creation
Deposit processing
Withdrawal processing
Realized P/L calculation
Portfolio aggregation
Balance validation
Holding validation
Financial transaction atomicity
```

The database shall therefore contain substantial stored-procedure logic.

---

# 50. External API Failure Behavior

If the external cryptocurrency API is unavailable:

- The application shall not fabricate a market price.
- Existing persisted market data may be displayed where appropriate.
- New trades requiring a current price shall be rejected if a valid execution price cannot be obtained.
- The error shall be logged.
- The API shall return a meaningful error response.

---

# 51. Demo/Paper Trading Rules

This application shall operate entirely as a paper-trading environment.

It shall not:

- Transfer real cryptocurrency
- Purchase real cryptocurrency
- Connect to a user's bank account
- Process real credit-card payments
- Transfer real fiat currency
- Execute real withdrawals

Deposits and withdrawals are simulated account operations.

Market prices may be obtained from live public market-data APIs.

---

# 52. Demo User Workflow

The complete application shall support the following flow:

```text
Register
   ↓
Login
   ↓
Deposit $10,000
   ↓
View Cryptocurrency Market
   ↓
Buy BTC
   ↓
View Portfolio
   ↓
Observe Unrealized P/L
   ↓
Sell BTC
   ↓
Observe Realized P/L
   ↓
Withdraw Funds
   ↓
View Transaction History
```

The complete flow shall be persisted in SQL Server.

---

# 53. Example BUY Flow

```text
React
  |
  | POST /api/trades/buy
  v
TradeController
  |
  v
TradingService
  |
  v
TradingRepository
  |
  | Execute Stored Procedure
  v
usp_ExecuteBuyOrder
  |
  +-- Validate Balance
  +-- Create Order
  +-- Create Trade
  +-- Update Account
  +-- Update Wallet
  +-- Create Transaction
  +-- Commit
  |
  v
SQL Server
```

---

# 54. Example SELL Flow

```text
React
  |
  | POST /api/trades/sell
  v
TradeController
  |
  v
TradingService
  |
  v
TradingRepository
  |
  | Execute Stored Procedure
  v
usp_ExecuteSellOrder
  |
  +-- Validate Holdings
  +-- Create Order
  +-- Create Trade
  +-- Update Wallet
  +-- Update Account
  +-- Calculate Realized P/L
  +-- Create Transaction
  +-- Commit
  |
  v
SQL Server
```

---

# 55. API Authentication and Authorization Rules

Protected API calls shall derive the current user from the authentication context.

The API shall not accept a request such as:

```http
GET /api/portfolio?userId=123
```

and blindly trust `userId`.

The authenticated user's identity shall determine which portfolio is returned.

---

# 56. Documentation Requirements

Provide:

```text
README.md
docs/architecture.md
docs/database.md
docs/stored-procedures.md
docs/api.md
```

The README shall explain:

- Prerequisites
- .NET Framework requirements
- Visual Studio setup
- Docker setup
- SQL Server startup
- Database initialization
- Configuration
- Backend startup
- React startup
- Demo credentials
- API usage

---

# 57. API Documentation

Document each API endpoint with:

- HTTP method
- URL
- Authentication requirement
- Request parameters
- Request body
- Response body
- HTTP status codes
- Error responses

Swagger/OpenAPI may be used if compatible with the ASP.NET Web API 2 implementation.

---

# 58. Non-Functional Requirements

## Performance

The application should provide acceptable response times for normal demo workloads.

## Reliability

Financial operations must be atomic and must not leave partial database changes.

## Data Integrity

Foreign keys, constraints, transactions, and validation shall be used to maintain data integrity.

## Security

Authentication, authorization, parameterized database access, password hashing, and server-side validation are mandatory.

## Maintainability

The application shall be organized into recognizable application, business, data-access, model, and infrastructure components.

---

# 59. Development Instructions

The implementation shall be produced incrementally.

## Phase 1 — Database

Create:

- Database
- Tables
- Constraints
- Indexes
- Stored procedures
- Seed data

## Phase 2 — Backend Foundation

Create:

- .NET Framework 4.7 solution
- Web API
- Models
- Business layer
- Data Access Layer
- Configuration
- Authentication

## Phase 3 — Market Data

Implement:

- External cryptocurrency API
- Market-data service
- Cryptocurrency listing
- Price persistence

## Phase 4 — Trading

Implement:

- Wallets
- Orders
- Trades
- BUY
- SELL
- Transaction ledger

## Phase 5 — Funds

Implement:

- Accounts
- Deposits
- Withdrawals
- Balance management

## Phase 6 — Portfolio

Implement:

- Holdings
- Portfolio valuation
- Realized P/L
- Unrealized P/L
- Total P/L

## Phase 7 — React

Implement:

- Login
- Registration
- Dashboard
- Trading
- Portfolio
- Orders
- Transactions
- Funds
- Profile

## Phase 8 — Validation

Verify:

- Database transactions
- Stored procedure behavior
- Authorization
- Financial validation
- Error handling
- External API failure behavior
- Demo workflow

---

# 60. Final AS-IS Acceptance Criteria

The application shall be considered complete when:

1. Multiple users can register and authenticate.
2. Each user has an independent account.
3. Users can make simulated deposits.
4. Users can view cryptocurrency market information.
5. Users can execute simulated BUY orders.
6. Users can execute simulated SELL orders.
7. BUY operations update account balance and cryptocurrency holdings.
8. SELL operations update cryptocurrency holdings and account balance.
9. Orders and trades are persisted.
10. Financial transactions are persisted.
11. Portfolio value is calculated.
12. Realized P/L is calculated.
13. Unrealized P/L is calculated.
14. Users can perform simulated withdrawals.
15. Users can view transaction history.
16. Users cannot access another user's financial information.
17. Financial operations are atomic.
18. Important runtime database operations use stored procedures.
19. SQL Server is available through Docker for development.
20. The React frontend communicates with the backend through REST APIs.
21. The .NET Framework 4.7 backend can be built and run in the documented environment.
22. The complete demo workflow can be executed using seeded/demo data.

---

# 61. AS-IS System Principle

The implementation shall follow this principle throughout:

```text
React Frontend
      ↓
ASP.NET Web API
      ↓
Business Layer
      ↓
Data Access Layer
      ↓
SQL Server Stored Procedures
      ↓
SQL Server Tables
```

The database is an active part of the application and contains substantial operational and business logic through stored procedures.

The application shall be implemented according to the requirements in this document as an **AS-IS legacy system**.
