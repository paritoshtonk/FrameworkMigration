# REST API Specification — Legacy CryptoTrading Platform

## 1. Overview & Protocol Guidelines

The CryptoTrading API is an ASP.NET Web API 2 RESTful service exposing JSON over HTTP/HTTPS.

### 1.1 Base URL & Interactive Swagger UI
- Local IIS Express: `http://localhost:44341/api`
- **Interactive Swagger UI (Default Start Page):** `http://localhost:44341/swagger` (or root `http://localhost:44341/`)
- Swagger JSON Schema: `http://localhost:44341/swagger/docs/v1`
- Production IIS: `https://<hostname>/api`

### 1.2 Authentication & Headers
Protected endpoints require an `Authorization` header containing a valid Bearer JWT:
```http
Authorization: Bearer <jwt_token>
Content-Type: application/json
Accept: application/json
```

### 1.3 Uniform Response Envelope
All API responses adhere to a consistent JSON envelope:

#### Successful Response (`200 OK`, `201 Created`):
```json
{
  "success": true,
  "message": "Operation completed successfully.",
  "data": { ... }
}
```

#### Error Response (`400 Bad Request`, `401 Unauthorized`, `404 Not Found`, `500 Internal Error`):
```json
{
  "success": false,
  "message": "Human readable error description.",
  "errorCode": "INVALID_ARGUMENT"
}
```

---

## 2. Authentication Endpoints (`/api/auth`)

### 2.1 Register User
- **Method:** `POST`
- **Path:** `/api/auth/register`
- **Auth Required:** No
- **Request Body:**
  ```json
  {
    "username": "newtrader",
    "email": "newtrader@example.com",
    "password": "Password123!",
    "firstName": "John",
    "lastName": "Doe"
  }
  ```
- **Response (`201 Created`):**
  ```json
  {
    "success": true,
    "message": "User registered successfully.",
    "data": {
      "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "tokenType": "Bearer",
      "expiresIn": 86400,
      "user": {
        "userId": 4,
        "username": "newtrader",
        "email": "newtrader@example.com",
        "firstName": "John",
        "lastName": "Doe",
        "createdDate": "2026-09-11T14:30:00Z",
        "lastLoginDate": null
      }
    }
  }
  ```
- **Error Codes:**
  - `400 Bad Request`: `{"errorCode": "VALIDATION_FAILED", "message": "Username already exists."}`

---

### 2.2 Login User
- **Method:** `POST`
- **Path:** `/api/auth/login`
- **Auth Required:** No
- **Request Body:**
  ```json
  {
    "usernameOrEmail": "demo_trader",
    "password": "Password123!"
  }
  ```
- **Response (`200 OK`):**
  ```json
  {
    "success": true,
    "message": "Login successful.",
    "data": {
      "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "tokenType": "Bearer",
      "expiresIn": 86400,
      "user": {
        "userId": 3,
        "username": "demo_trader",
        "email": "bob@cryptotrading.local",
        "firstName": "Bob",
        "lastName": "Trader",
        "createdDate": "2026-09-11T13:21:18Z",
        "lastLoginDate": "2026-09-11T14:28:59Z"
      }
    }
  }
  ```
- **Error Codes:**
  - `401 Unauthorized`: `{"errorCode": "UNAUTHORIZED", "message": "Invalid username or password."}`

---

## 3. Cryptocurrencies Endpoints (`/api/cryptocurrencies`)

### 3.1 Get All Cryptocurrencies
- **Method:** `GET`
- **Path:** `/api/cryptocurrencies`
- **Auth Required:** No
- **Response (`200 OK`):**
  ```json
  {
    "success": true,
    "message": null,
    "data": [
      {
        "cryptocurrencyId": 1,
        "symbol": "BTC",
        "name": "Bitcoin",
        "currentPrice": 78998.00,
        "priceChange24h": 2.1965,
        "lastUpdated": "2026-09-11T14:29:25Z",
        "isActive": true
      },
      {
        "cryptocurrencyId": 2,
        "symbol": "ETH",
        "name": "Ethereum",
        "currentPrice": 2617.26,
        "priceChange24h": 7.1893,
        "lastUpdated": "2026-09-11T14:29:25Z",
        "isActive": true
      }
    ]
  }
  ```

---

### 3.2 Get Cryptocurrency by Symbol
- **Method:** `GET`
- **Path:** `/api/cryptocurrencies/{symbol}`
- **Auth Required:** No
- **URL Parameter:** `symbol` (e.g. `BTC`)
- **Response (`200 OK`):**
  ```json
  {
    "success": true,
    "message": null,
    "data": {
      "cryptocurrencyId": 1,
      "symbol": "BTC",
      "name": "Bitcoin",
      "currentPrice": 78998.00,
      "priceChange24h": 2.1965,
      "lastUpdated": "2026-09-11T14:29:25Z",
      "isActive": true
    }
  }
  ```

---

## 4. Portfolio Endpoints (`/api/portfolio`)

### 4.1 Get User Portfolio Summary
- **Method:** `GET`
- **Path:** `/api/portfolio`
- **Auth Required:** Yes (Bearer JWT)
- **Response (`200 OK`):**
  ```json
  {
    "success": true,
    "message": null,
    "data": {
      "userId": 3,
      "cashBalance": 10354.99,
      "cryptoHoldingsValue": 394.99,
      "totalPortfolioValue": 10749.98,
      "totalUnrealizedPnL": 0.00,
      "totalRealizedPnL": 0.00,
      "holdings": [
        {
          "symbol": "BTC",
          "name": "Bitcoin",
          "quantity": 0.00500000,
          "averageBuyPrice": 78998.00,
          "currentPrice": 78998.00,
          "currentValue": 394.99,
          "unrealizedPnL": 0.00,
          "unrealizedPnLPercentage": 0.00
        }
      ]
    }
  }
  ```

---

## 5. Orders & Trading Endpoints (`/api/orders`, `/api/trades`)

### 5.1 Create Order
- **Method:** `POST`
- **Path:** `/api/orders`
- **Auth Required:** Yes (Bearer JWT)
- **Request Body (MARKET BUY):**
  ```json
  {
    "symbol": "BTC",
    "orderType": "MARKET",
    "side": "BUY",
    "quantity": 0.01
  }
  ```
- **Request Body (LIMIT SELL):**
  ```json
  {
    "symbol": "ETH",
    "orderType": "LIMIT",
    "side": "SELL",
    "quantity": 0.5,
    "price": 2800.00
  }
  ```
- **Response (`201 Created`):**
  ```json
  {
    "success": true,
    "message": "Order created and executed successfully.",
    "data": {
      "orderId": 12,
      "symbol": "BTC",
      "orderType": "MARKET",
      "side": "BUY",
      "quantity": 0.01000000,
      "price": 78998.00,
      "status": "FILLED",
      "executedPrice": 78998.00,
      "totalCost": 789.98,
      "createdDate": "2026-09-11T14:32:00Z",
      "executedDate": "2026-09-11T14:32:00Z"
    }
  }
  ```
- **Error Codes:**
  - `400 Bad Request`: `{"errorCode": "INSUFFICIENT_FUNDS", "message": "Insufficient cash balance to execute BUY order."}`

---

### 5.2 Get User Orders
- **Method:** `GET`
- **Path:** `/api/orders`
- **Auth Required:** Yes (Bearer JWT)
- **Query Parameter:** `status` (optional: `PENDING`, `FILLED`, `CANCELLED`)
- **Response (`200 OK`):**
  ```json
  {
    "success": true,
    "message": null,
    "data": [
      {
        "orderId": 12,
        "symbol": "BTC",
        "orderType": "MARKET",
        "side": "BUY",
        "quantity": 0.01000000,
        "price": 78998.00,
        "status": "FILLED",
        "createdDate": "2026-09-11T14:32:00Z"
      }
    ]
  }
  ```

---

### 5.3 Cancel Order
- **Method:** `DELETE`
- **Path:** `/api/orders/{id}`
- **Auth Required:** Yes (Bearer JWT)
- **Response (`200 OK`):**
  ```json
  {
    "success": true,
    "message": "Order cancelled successfully.",
    "data": true
  }
  ```

---

### 5.4 Get User Trades
- **Method:** `GET`
- **Path:** `/api/trades`
- **Auth Required:** Yes (Bearer JWT)
- **Response (`200 OK`):**
  ```json
  {
    "success": true,
    "message": null,
    "data": [
      {
        "tradeId": 8,
        "orderId": 12,
        "symbol": "BTC",
        "side": "BUY",
        "quantity": 0.01000000,
        "price": 78998.00,
        "totalAmount": 789.98,
        "realizedPnL": 0.00,
        "executedDate": "2026-09-11T14:32:00Z"
      }
    ]
  }
  ```

---

## 6. Cash Management Endpoints (`/api/deposits`, `/api/withdrawals`, `/api/transactions`)

### 6.1 Deposit Cash
- **Method:** `POST`
- **Path:** `/api/deposits`
- **Auth Required:** Yes (Bearer JWT)
- **Request Body:**
  ```json
  {
    "amount": 1000.00,
    "currency": "USD"
  }
  ```
- **Response (`200 OK`):**
  ```json
  {
    "success": true,
    "message": "Deposit processed successfully.",
    "data": {
      "depositId": 7,
      "amount": 1000.00,
      "currency": "USD",
      "status": "COMPLETED",
      "newBalance": 11000.00,
      "createdDate": "2026-09-11T14:31:00Z"
    }
  }
  ```

---

### 6.2 Withdraw Cash
- **Method:** `POST`
- **Path:** `/api/withdrawals`
- **Auth Required:** Yes (Bearer JWT)
- **Request Body:**
  ```json
  {
    "amount": 250.00,
    "currency": "USD"
  }
  ```
- **Response (`200 OK`):**
  ```json
  {
    "success": true,
    "message": "Withdrawal processed successfully.",
    "data": {
      "withdrawalId": 5,
      "amount": 250.00,
      "currency": "USD",
      "status": "COMPLETED",
      "newBalance": 10750.00,
      "createdDate": "2026-09-11T14:33:00Z"
    }
  }
  ```
- **Error Codes:**
  - `400 Bad Request`: `{"errorCode": "INSUFFICIENT_FUNDS", "message": "Insufficient funds for withdrawal."}`

---

### 6.3 Financial Transaction History (Audit Ledger)
- **Method:** `GET`
- **Path:** `/api/transactions`
- **Auth Required:** Yes (Bearer JWT)
- **Response (`200 OK`):**
  ```json
  {
    "success": true,
    "message": null,
    "data": [
      {
        "transactionId": 15,
        "transactionType": "WITHDRAWAL",
        "amount": 250.00,
        "balanceAfter": 10750.00,
        "referenceId": 5,
        "description": "Withdrawal of $250.00",
        "createdDate": "2026-09-11T14:33:00Z"
      },
      {
        "transactionId": 14,
        "transactionType": "BUY",
        "amount": 789.98,
        "balanceAfter": 11000.00,
        "referenceId": 8,
        "description": "Bought 0.01 BTC at $78998.00",
        "createdDate": "2026-09-11T14:32:00Z"
      },
      {
        "transactionId": 13,
        "transactionType": "DEPOSIT",
        "amount": 1000.00,
        "balanceAfter": 11789.98,
        "referenceId": 7,
        "description": "Deposit of $1000.00",
        "createdDate": "2026-09-11T14:31:00Z"
      }
    ]
  }
  ```

---

## 7. Profile Endpoints (`/api/profile`)

### 7.1 Get Profile
- **Method:** `GET`
- **Path:** `/api/profile`
- **Auth Required:** Yes (Bearer JWT)
- **Response (`200 OK`):**
  ```json
  {
    "success": true,
    "message": null,
    "data": {
      "user": {
        "userId": 3,
        "username": "demo_trader",
        "email": "bob@cryptotrading.local",
        "firstName": "Bob",
        "lastName": "Trader",
        "createdDate": "2026-09-11T13:21:18Z",
        "lastLoginDate": "2026-09-11T14:28:59Z"
      },
      "account": {
        "accountId": 3,
        "userId": 3,
        "balance": 10750.00,
        "currency": "USD"
      }
    }
  }
  ```

---

### 7.2 Update Profile
- **Method:** `PUT`
- **Path:** `/api/profile`
- **Auth Required:** Yes (Bearer JWT)
- **Request Body:**
  ```json
  {
    "firstName": "Robert",
    "lastName": "Trader",
    "email": "robert@cryptotrading.local"
  }
  ```
- **Response (`200 OK`):**
  ```json
  {
    "success": true,
    "message": "Profile updated successfully.",
    "data": {
      "userId": 3,
      "username": "demo_trader",
      "email": "robert@cryptotrading.local",
      "firstName": "Robert",
      "lastName": "Trader"
    }
  }
  ```

