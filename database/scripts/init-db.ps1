# ============================================================================
# init-db.ps1
# Automated database migration and verification runner for SQL Server
# ============================================================================
param(
    [string]$Server = "(localdb)\CryptoTradingDB",
    [string]$Database = "CryptoTradingDB"
)

$ErrorActionPreference = "Stop"

Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host " Running CryptoTrading SQL Server Database Migration " -ForegroundColor Cyan
Write-Host " Server:   $Server" -ForegroundColor Cyan
Write-Host " Database: $Database" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$runAllSql = Join-Path $scriptDir "RunAll.sql"

if (-not (Test-Path $runAllSql)) {
    Write-Error "RunAll.sql not found at $runAllSql"
}

Write-Host "Executing RunAll.sql via SQLCMD..." -ForegroundColor Yellow
$sqlcmdOutput = & sqlcmd -S $Server -i $runAllSql -b
Write-Host $sqlcmdOutput

if ($LASTEXITCODE -ne 0) {
    Write-Error "SQLCMD migration execution failed with exit code $LASTEXITCODE"
}

Write-Host "`nVerifying Database Objects..." -ForegroundColor Green
$verificationSql = @"
USE $Database;
SELECT 
    (SELECT COUNT(*) FROM Users) AS UsersCount,
    (SELECT COUNT(*) FROM Accounts) AS AccountsCount,
    (SELECT COUNT(*) FROM Cryptocurrencies) AS CryptosCount,
    (SELECT COUNT(*) FROM Wallets) AS WalletsCount,
    (SELECT COUNT(*) FROM Orders) AS OrdersCount,
    (SELECT COUNT(*) FROM Trades) AS TradesCount,
    (SELECT COUNT(*) FROM Transactions) AS TransactionsCount;
"@

$verifyOutput = & sqlcmd -S $Server -Q $verificationSql -W
Write-Host $verifyOutput

Write-Host "Database migration and initialization completed successfully!" -ForegroundColor Green
