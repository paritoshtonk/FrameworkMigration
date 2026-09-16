using System;
using System.Threading.Tasks;
using Moq;
using NUnit.Framework;
using CryptoTrading.Business.Services;
using CryptoTrading.Data.Repositories;
using CryptoTrading.Infrastructure.Logging;
using CryptoTrading.Infrastructure.MarketData;
using CryptoTrading.Models.DTOs;
using CryptoTrading.Models.Entities;
using CryptoTrading.Models.Requests;

namespace CryptoTrading.Tests
{
    [TestFixture]
    public class TradingTests
    {
        private Mock<ITradingRepository> _tradingRepoMock;
        private Mock<ICryptoMarketService> _marketServiceMock;
        private Mock<ILoggerService> _loggerMock;
        private Mock<IWalletRepository> _walletRepoMock;
        private TradingService _tradingService;

        [SetUp]
        public void Setup()
        {
            _tradingRepoMock = new Mock<ITradingRepository>();
            _marketServiceMock = new Mock<ICryptoMarketService>();
            _loggerMock = new Mock<ILoggerService>();
            _walletRepoMock = new Mock<IWalletRepository>();

            _tradingService = new TradingService(
                _tradingRepoMock.Object,
                _marketServiceMock.Object,
                _loggerMock.Object,
                _walletRepoMock.Object
            );
        }

        [Test]
        public async Task BuyAsync_ValidRequest_ExecutesTradeUsingCurrentPrice()
        {
            // Arrange
            int userId = 1;
            var req = new BuyTradeRequest { Symbol = "BTC", Quantity = 0.5m };

            _marketServiceMock.Setup(m => m.GetCryptocurrencyPriceAsync("BTC", false))
                .ReturnsAsync(new CryptocurrencyDto { Symbol = "BTC", CurrentPrice = 70000m });

            _tradingRepoMock.Setup(r => r.ExecuteBuyOrderAsync(userId, "BTC", 0.5m, 70000m))
                .ReturnsAsync(new TradeDto
                {
                    TradeId = 100,
                    OrderId = 200,
                    UserId = userId,
                    Symbol = "BTC",
                    Side = "BUY",
                    Quantity = 0.5m,
                    ExecutionPrice = 70000m,
                    TotalValue = 35000m,
                    RealizedProfitLoss = 0m,
                    RemainingBalance = 5000m
                });

            // Act
            var trade = await _tradingService.BuyAsync(userId, req);

            // Assert
            Assert.IsNotNull(trade);
            Assert.AreEqual(100, trade.TradeId);
            Assert.AreEqual(35000m, trade.TotalValue);
            _tradingRepoMock.Verify(r => r.ExecuteBuyOrderAsync(userId, "BTC", 0.5m, 70000m), Times.Once);
        }

        [Test]
        public void BuyAsync_PriceUnavailable_RejectsTrade()
        {
            // Arrange
            int userId = 1;
            var req = new BuyTradeRequest { Symbol = "BTC", Quantity = 0.5m };

            _marketServiceMock.Setup(m => m.GetCryptocurrencyPriceAsync("BTC", false))
                .ReturnsAsync((CryptocurrencyDto)null);

            // Act & Assert (SRS Section 50: New trades requiring a current price shall be rejected if valid execution price cannot be obtained)
            var ex = Assert.ThrowsAsync<InvalidOperationException>(async () => await _tradingService.BuyAsync(userId, req));
            Assert.That(ex.Message, Does.Contain("unavailable"));
        }

        [Test]
        public void BuyAsync_InvalidQuantity_ThrowsArgumentException()
        {
            var req = new BuyTradeRequest { Symbol = "BTC", Quantity = -1m };
            Assert.ThrowsAsync<ArgumentException>(async () => await _tradingService.BuyAsync(1, req));
        }

        [Test]
        public async Task SellAsync_ValidRequest_ExecutesTradeAndComputesRealizedPL()
        {
            // Arrange
            int userId = 1;
            var req = new SellTradeRequest { Symbol = "ETH", Quantity = 2.0m };

            _marketServiceMock.Setup(m => m.GetCryptocurrencyPriceAsync("ETH", false))
                .ReturnsAsync(new CryptocurrencyDto { Symbol = "ETH", CurrentPrice = 3000m });

            _tradingRepoMock.Setup(r => r.ExecuteSellOrderAsync(userId, "ETH", 2.0m, 3000m))
                .ReturnsAsync(new TradeDto
                {
                    TradeId = 101,
                    OrderId = 201,
                    UserId = userId,
                    Symbol = "ETH",
                    Side = "SELL",
                    Quantity = 2.0m,
                    ExecutionPrice = 3000m,
                    TotalValue = 6000m,
                    RealizedProfitLoss = 1000m, // sold at 3000, bought at 2500 -> (3000-2500)*2 = 1000
                    RemainingBalance = 16000m
                });

            // Act
            var trade = await _tradingService.SellAsync(userId, req);

            // Assert
            Assert.IsNotNull(trade);
            Assert.AreEqual(101, trade.TradeId);
            Assert.AreEqual(1000m, trade.RealizedProfitLoss);
            _tradingRepoMock.Verify(r => r.ExecuteSellOrderAsync(userId, "ETH", 2.0m, 3000m), Times.Once);
        }

        [Test]
        public async Task ClosePositionAsync_ValidHolding_LiquidatesEntireQuantityViaSell()
        {
            // Arrange
            int userId = 1;
            string symbol = "SOL";
            decimal holdingQuantity = 15.5m;
            decimal currentPrice = 140m;

            _walletRepoMock.Setup(w => w.GetWalletHoldingAsync(userId, "SOL"))
                .ReturnsAsync(new Wallet
                {
                    WalletId = 10,
                    UserId = userId,
                    Currency = "SOL",
                    Quantity = holdingQuantity,
                    AverageCost = 120m
                });

            _marketServiceMock.Setup(m => m.GetCryptocurrencyPriceAsync("SOL", false))
                .ReturnsAsync(new CryptocurrencyDto { Symbol = "SOL", CurrentPrice = currentPrice });

            _tradingRepoMock.Setup(r => r.ExecuteSellOrderAsync(userId, "SOL", holdingQuantity, currentPrice))
                .ReturnsAsync(new TradeDto
                {
                    TradeId = 205,
                    UserId = userId,
                    Symbol = "SOL",
                    Side = "SELL",
                    Quantity = holdingQuantity,
                    ExecutionPrice = currentPrice,
                    TotalValue = holdingQuantity * currentPrice,
                    RealizedProfitLoss = (currentPrice - 120m) * holdingQuantity,
                    RemainingBalance = 25000m
                });

            // Act
            var trade = await _tradingService.ClosePositionAsync(userId, symbol);

            // Assert
            Assert.IsNotNull(trade);
            Assert.AreEqual(205, trade.TradeId);
            Assert.AreEqual(holdingQuantity, trade.Quantity);
            Assert.AreEqual(310m, trade.RealizedProfitLoss); // (140 - 120) * 15.5 = 310
            _tradingRepoMock.Verify(r => r.ExecuteSellOrderAsync(userId, "SOL", holdingQuantity, currentPrice), Times.Once);
        }

        [Test]
        public void ClosePositionAsync_NoHolding_ThrowsInvalidOperationException()
        {
            // Arrange
            int userId = 1;
            string symbol = "ADA";

            _walletRepoMock.Setup(w => w.GetWalletHoldingAsync(userId, "ADA"))
                .ReturnsAsync((Wallet)null);

            // Act & Assert
            var ex = Assert.ThrowsAsync<InvalidOperationException>(async () => await _tradingService.ClosePositionAsync(userId, symbol));
            Assert.That(ex.Message, Does.Contain("No open position"));
        }
    }
}

