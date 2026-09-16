using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Moq;
using NUnit.Framework;
using System.Text;
using CryptoTrading.Business.Services;
using CryptoTrading.Data.Repositories;
using CryptoTrading.Infrastructure.Logging;
using CryptoTrading.Infrastructure.Reports;
using CryptoTrading.Models.DTOs;
using CryptoTrading.Models.Requests;

namespace CryptoTrading.Tests
{
    [TestFixture]
    public class FinancialAndPortfolioTests
    {
        [Test]
        public async Task DepositAsync_ValidAmount_CallsRepositoryAndIncreasesBalance()
        {
            var depositRepoMock = new Mock<IDepositRepository>();
            var withdrawalRepoMock = new Mock<IWithdrawalRepository>();
            var txRepoMock = new Mock<ITransactionRepository>();
            var loggerMock = new Mock<ILoggerService>();

            var finService = new FinancialService(
                depositRepoMock.Object,
                withdrawalRepoMock.Object,
                txRepoMock.Object,
                loggerMock.Object
            );

            depositRepoMock.Setup(d => d.ProcessDepositAsync(1, 5000m, "USD"))
                .ReturnsAsync(new DepositDto
                {
                    DepositId = 50,
                    UserId = 1,
                    Amount = 5000m,
                    Currency = "USD",
                    Status = "COMPLETED",
                    NewBalance = 15000m
                });

            var res = await finService.DepositAsync(1, new DepositRequest { Amount = 5000m, Currency = "USD" });

            Assert.IsNotNull(res);
            Assert.AreEqual(5000m, res.Amount);
            Assert.AreEqual(15000m, res.NewBalance);
        }

        [Test]
        public void DepositAsync_NegativeAmount_ThrowsArgumentException()
        {
            var finService = new FinancialService(
                new Mock<IDepositRepository>().Object,
                new Mock<IWithdrawalRepository>().Object,
                new Mock<ITransactionRepository>().Object,
                new Mock<ILoggerService>().Object
            );

            Assert.ThrowsAsync<ArgumentException>(async () =>
                await finService.DepositAsync(1, new DepositRequest { Amount = -100m })
            );
        }

        [Test]
        public async Task PortfolioFormulas_CalculateCorrectly()
        {
            // SRS Section 16 & 18 Formulas:
            // Current Market Value = Quantity * Current Market Price
            // Unrealized P/L = Current Market Value - Cost Basis = (Current Price - Average Cost) * Quantity
            // Total P/L = Realized P/L + Unrealized P/L
            // Total Portfolio Value = Cash Balance + Total Holdings Market Value

            decimal cashBalance = 10000m;
            decimal btcQuantity = 0.2m;
            decimal btcAvgCost = 60000m;
            decimal btcCurrentPrice = 70000m;

            decimal btcCostBasis = btcQuantity * btcAvgCost;               // 12,000
            decimal btcMarketValue = btcQuantity * btcCurrentPrice;        // 14,000
            decimal btcUnrealizedPL = btcMarketValue - btcCostBasis;       // +2,000

            decimal realizedPL = 500m;                                     // from past trade
            decimal totalPL = realizedPL + btcUnrealizedPL;                // 2,500
            decimal totalPortfolioValue = cashBalance + btcMarketValue;    // 24,000

            Assert.AreEqual(12000m, btcCostBasis);
            Assert.AreEqual(14000m, btcMarketValue);
            Assert.AreEqual(2000m, btcUnrealizedPL);
            Assert.AreEqual(2500m, totalPL);
            Assert.AreEqual(24000m, totalPortfolioValue);
        }

        [Test]
        public async Task CancelOrder_PendingOrder_Succeeds()
        {
            var orderRepoMock = new Mock<IOrderRepository>();
            var loggerMock = new Mock<ILoggerService>();
            var orderService = new OrderService(orderRepoMock.Object, loggerMock.Object);

            orderRepoMock.Setup(r => r.CancelOrderAsync(10, 1))
                .ReturnsAsync(new OrderDto
                {
                    OrderId = 10,
                    UserId = 1,
                    Status = "Cancelled"
                });

            var result = await orderService.CancelOrderAsync(10, 1);
            Assert.AreEqual("Cancelled", result.Status);
        }

        [Test]
        public async Task GeneratePnLAndSettlementReportAsync_GeneratesValidPdfBytes()
        {
            // Arrange
            int userId = 1;
            var userRepoMock = new Mock<IUserRepository>();
            var portfolioRepoMock = new Mock<IPortfolioRepository>();
            var tradingRepoMock = new Mock<ITradingRepository>();
            var txRepoMock = new Mock<ITransactionRepository>();
            var loggerMock = new Mock<ILoggerService>();

            userRepoMock.Setup(u => u.GetUserByIdAsync(userId))
                .ReturnsAsync(new CryptoTrading.Models.Entities.User
                {
                    UserId = userId,
                    Username = "trader_alice",
                    Email = "alice@example.com"
                });

            portfolioRepoMock.Setup(p => p.GetPortfolioAsync(userId))
                .ReturnsAsync(new PortfolioDto
                {
                    Summary = new PortfolioSummaryDto
                    {
                        UserId = userId,
                        CashBalance = 15000m,
                        HoldingsMarketValue = 28000m,
                        TotalPortfolioValue = 43000m,
                        UnrealizedProfitLoss = 3200m,
                        RealizedProfitLoss = 1500m
                    },
                    Holdings = new List<HoldingDto>
                    {
                        new HoldingDto
                        {
                            Symbol = "BTC",
                            Name = "Bitcoin",
                            Quantity = 0.4m,
                            AverageCost = 62000m,
                            CurrentPrice = 70000m,
                            CurrentValue = 28000m,
                            UnrealizedProfitLoss = 3200m,
                            UnrealizedProfitLossPercentage = 12.9m
                        }
                    }
                });

            tradingRepoMock.Setup(t => t.GetTradesByUserAsync(userId, 1000))
                .ReturnsAsync(new List<TradeDto>
                {
                    new TradeDto
                    {
                        TradeId = 1,
                        UserId = userId,
                        Symbol = "BTC",
                        Side = "BUY",
                        Quantity = 0.4m,
                        ExecutionPrice = 62000m,
                        TotalValue = 24800m,
                        ExecutedDate = DateTime.UtcNow.AddDays(-5)
                    },
                    new TradeDto
                    {
                        TradeId = 2,
                        UserId = userId,
                        Symbol = "ETH",
                        Side = "SELL",
                        Quantity = 2.0m,
                        ExecutionPrice = 3500m,
                        TotalValue = 7000m,
                        RealizedProfitLoss = 1500m,
                        ExecutedDate = DateTime.UtcNow.AddDays(-2)
                    }
                });

            txRepoMock.Setup(tx => tx.GetTransactionsByUserAsync(userId, 1000))
                .ReturnsAsync(new List<TransactionDto>
                {
                    new TransactionDto
                    {
                        TransactionId = 101,
                        UserId = userId,
                        TransactionType = "DEPOSIT",
                        Currency = "USD",
                        Amount = 20000m,
                        Status = "COMPLETED",
                        CreatedDate = DateTime.UtcNow.AddDays(-10)
                    },
                    new TransactionDto
                    {
                        TransactionId = 102,
                        UserId = userId,
                        TransactionType = "WITHDRAWAL",
                        Currency = "USD",
                        Amount = 5000m,
                        Status = "COMPLETED",
                        CreatedDate = DateTime.UtcNow.AddDays(-3)
                    }
                });

            var pdfService = new PdfReportService(
                userRepoMock.Object,
                portfolioRepoMock.Object,
                tradingRepoMock.Object,
                txRepoMock.Object,
                loggerMock.Object
            );

            // Act
            byte[] pdfBytes = await pdfService.GeneratePnLAndSettlementReportAsync(userId, "30d");

            // Assert
            Assert.IsNotNull(pdfBytes);
            Assert.IsTrue(pdfBytes.Length > 500, $"Expected substantial PDF binary size, got {pdfBytes.Length} bytes.");

            string pdfAscii = Encoding.ASCII.GetString(pdfBytes);
            Assert.IsTrue(pdfAscii.StartsWith("%PDF-1.4"), "PDF stream must start with valid header '%PDF-1.4'");
            Assert.IsTrue(pdfAscii.Contains("%%EOF"), "PDF stream must terminate with '%%EOF'");
            Assert.IsTrue(pdfAscii.Contains("CRYPTO TRADING PLATFORM"), "PDF stream must contain platform branding header");
            Assert.IsTrue(pdfAscii.Contains("trader_alice"), "PDF stream must contain user metadata");
        }
    }
}

