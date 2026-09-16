using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Web.Http.Results;
using CryptoTrading.Business.Services;
using CryptoTrading.Infrastructure.Logging;
using CryptoTrading.Infrastructure.PubSub;
using CryptoTrading.Models.DTOs;
using CryptoTrading.Models.Requests;
using CryptoTrading.Web.Controllers;
using Moq;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using NUnit.Framework;

namespace CryptoTrading.Tests
{
    [TestFixture]
    public class PubSubIntegrationTests
    {
        private Mock<ILoggerService> _mockLogger;

        [SetUp]
        public void Setup()
        {
            _mockLogger = new Mock<ILoggerService>();
            PubSubMessageHub.Instance.Clear();
            MarketTickHotCacheSubscriber.Clear();
        }

        [Test]
        public void PubSubConfig_LoadsCorrectDefaults_WhenNotConfigured()
        {
            var config = PubSubConfig.FromConfiguration();

            Assert.IsNotNull(config);
            Assert.AreEqual("cryptotrading-gcp-dev", config.ProjectId);
            Assert.AreEqual("localhost:8085", config.EmulatorHost);
            Assert.AreEqual("crypto-orders-incoming", config.OrdersIncomingTopic);
            Assert.AreEqual("crypto-orders-executed", config.OrdersExecutedTopic);
            Assert.AreEqual("crypto-market-ticks", config.MarketTicksTopic);
            Assert.AreEqual("crypto-orders-incoming-sub", config.OrderPushSubscription);
            Assert.AreEqual("crypto-market-ticks-sub", config.TickSubscription);
            Assert.IsTrue(config.TickSubscriberEnabled);
        }

        [Test]
        public void PubSubConfig_GcpEnvironmentVariables_OverridesWebConfig()
        {
            try
            {
                Environment.SetEnvironmentVariable("PUBSUB_PROJECT_ID", "my-prod-gcp-project");
                Environment.SetEnvironmentVariable("PUBSUB_ORDERS_INCOMING_TOPIC", "gcp-orders-in");
                Environment.SetEnvironmentVariable("PUBSUB_ORDERS_EXECUTED_TOPIC", "gcp-orders-out");
                Environment.SetEnvironmentVariable("PUBSUB_PUSH_ENDPOINT_SECRET", "TOP_SECRET_123");
                Environment.SetEnvironmentVariable("PUBSUB_TICK_SUBSCRIBER_ENABLED", "false");

                var config = PubSubConfig.FromConfiguration();

                Assert.AreEqual("my-prod-gcp-project", config.ProjectId);
                Assert.AreEqual("gcp-orders-in", config.OrdersIncomingTopic);
                Assert.AreEqual("gcp-orders-out", config.OrdersExecutedTopic);
                Assert.AreEqual("TOP_SECRET_123", config.PushEndpointSecret);
                Assert.IsFalse(config.TickSubscriberEnabled);
            }
            finally
            {
                Environment.SetEnvironmentVariable("PUBSUB_PROJECT_ID", null);
                Environment.SetEnvironmentVariable("PUBSUB_ORDERS_INCOMING_TOPIC", null);
                Environment.SetEnvironmentVariable("PUBSUB_ORDERS_EXECUTED_TOPIC", null);
                Environment.SetEnvironmentVariable("PUBSUB_PUSH_ENDPOINT_SECRET", null);
                Environment.SetEnvironmentVariable("PUBSUB_TICK_SUBSCRIBER_ENABLED", null);
            }
        }

        [Test]
        public void PubSubEvents_SerializationAndDeserialization_MaintainsPrecision()
        {
            var placed = new OrderPlacedEvent
            {
                CorrelationId = Guid.NewGuid(),
                UserId = 42,
                Symbol = "ADA",
                Side = "BUY",
                OrderType = "LIMIT",
                Quantity = 1500.50m,
                Price = 0.5284m
            };

            var json = JsonConvert.SerializeObject(placed);
            var deserialized = JsonConvert.DeserializeObject<OrderPlacedEvent>(json);

            Assert.AreEqual(placed.CorrelationId, deserialized.CorrelationId);
            Assert.AreEqual(42, deserialized.UserId);
            Assert.AreEqual("ADA", deserialized.Symbol);
            Assert.AreEqual(1500.50m, deserialized.Quantity);
            Assert.AreEqual(0.5284m, deserialized.Price);
        }

        [Test]
        public async Task PubSubPublisher_PublishesMessage_WithOrderingKey_AndSubscriberReceives()
        {
            var config = new PubSubConfig { Enabled = true, MarketTicksTopic = "test.ticks" };
            var publisher = new PubSubPublisher(config, _mockLogger.Object);
            var subscriber = new PubSubSubscriber(config, _mockLogger.Object);

            string receivedKey = null;
            MarketTickEvent receivedTick = null;
            var tcs = new TaskCompletionSource<bool>();

            subscriber.Subscribe<MarketTickEvent>("test.ticks", (key, tick) =>
            {
                receivedKey = key;
                receivedTick = tick;
                tcs.TrySetResult(true);
                return Task.CompletedTask;
            });

            var tickEvent = new MarketTickEvent
            {
                CryptoId = 1,
                Symbol = "BTC",
                Name = "Bitcoin",
                CurrentPrice = 64500.75m,
                PriceChange24h = 2.45m
            };

            await publisher.PublishAsync("test.ticks", "BTC", tickEvent);

            var completed = await Task.WhenAny(tcs.Task, Task.Delay(1000));
            Assert.AreEqual(tcs.Task, completed, "Subscriber should receive the published message within 1 second.");
            Assert.AreEqual("BTC", receivedKey);
            Assert.IsNotNull(receivedTick);
            Assert.AreEqual(64500.75m, receivedTick.CurrentPrice);
            Assert.AreEqual("Bitcoin", receivedTick.Name);
        }

        [Test]
        public async Task PubSubPublisher_HandlesDisabledOrOffline_GracefullyWithoutThrowing()
        {
            var config = new PubSubConfig { Enabled = false };
            var publisher = new PubSubPublisher(config, _mockLogger.Object);

            Assert.IsFalse(publisher.IsActive);

            var success = await publisher.PublishAsync("test.topic", "KEY", new { Hello = "World" });
            Assert.IsTrue(success, "Publisher in fallback mode should complete without unhandled exceptions.");
        }

        [Test]
        public async Task OrderExecutionProcessor_ExecutesOrder_AndEmitsExecutionResult()
        {
            var config = new PubSubConfig
            {
                Enabled = true,
                OrdersExecutedTopic = "test.orders.out"
            };

            var mockTradingService = new Mock<ITradingService>();
            mockTradingService
                .Setup(s => s.SellAsync(It.IsAny<int>(), It.IsAny<SellTradeRequest>()))
                .ReturnsAsync(new TradeDto
                {
                    TradeId = 777,
                    Symbol = "BTC",
                    ExecutionPrice = 65000.00m,
                    TotalValue = 130000.00m
                });

            var publisher = new PubSubPublisher(config, _mockLogger.Object);
            var processor = new OrderExecutionProcessor(() => mockTradingService.Object, publisher, config, _mockLogger.Object);

            var correlationId = Guid.NewGuid();
            var placed = new OrderPlacedEvent
            {
                CorrelationId = correlationId,
                UserId = 12,
                Symbol = "BTC",
                Side = "SELL",
                OrderType = "MARKET",
                Quantity = 2.0m
            };

            var result = await processor.ProcessOrderAsync(placed);

            Assert.IsNotNull(result);
            Assert.AreEqual("FILLED", result.Status);
            Assert.AreEqual(777, result.TradeId);
            Assert.AreEqual(65000.00m, result.ExecutedPrice);
            Assert.AreEqual(130000.00m, result.TotalAmount);
            Assert.AreEqual(correlationId, result.CorrelationId);
        }

        [Test]
        public async Task MarketTickHotCacheSubscriber_IngestsTick_AndProvidesSubMillisecondLookup()
        {
            var config = new PubSubConfig
            {
                Enabled = true,
                MarketTicksTopic = "crypto-market-ticks"
            };

            var publisher = new PubSubPublisher(config, _mockLogger.Object);
            var subscriber = new PubSubSubscriber(config, _mockLogger.Object);
            var hotCache = new MarketTickHotCacheSubscriber(subscriber, config, _mockLogger.Object);

            hotCache.Start();

            var tick = new MarketTickEvent
            {
                CryptoId = 3,
                Symbol = "SOL",
                Name = "Solana",
                CurrentPrice = 145.20m,
                PriceChange24h = 5.12m
            };

            await publisher.PublishAsync("crypto-market-ticks", "SOL", tick);

            await Task.Delay(50); // Allow in-process dispatch

            var cached = MarketTickHotCacheSubscriber.GetLatestPrice("SOL");
            Assert.IsNotNull(cached, "Price should be available in hot cache immediately after tick ingestion.");
            Assert.AreEqual("SOL", cached.Symbol);
            Assert.AreEqual(145.20m, cached.CurrentPrice);
            Assert.AreEqual(5.12m, cached.PriceChange24h);
        }

        [Test]
        public async Task PubSubWebhookController_ProcessesRawOrderPlaced_ReturnsOk()
        {
            var mockProcessor = new Mock<IOrderExecutionProcessor>();
            mockProcessor
                .Setup(p => p.ProcessOrderAsync(It.IsAny<OrderPlacedEvent>()))
                .ReturnsAsync(new OrderExecutedEvent
                {
                    CorrelationId = Guid.NewGuid(),
                    UserId = 5,
                    Symbol = "SOL",
                    Side = "BUY",
                    Status = "FILLED",
                    TradeId = 888,
                    ExecutedPrice = 145.50m
                });

            var config = new PubSubConfig();
            var controller = new PubSubWebhookController(mockProcessor.Object, config, _mockLogger.Object);

            var rawOrder = JToken.FromObject(new OrderPlacedEvent
            {
                CorrelationId = Guid.NewGuid(),
                UserId = 5,
                Symbol = "SOL",
                Side = "BUY",
                Quantity = 10.0m
            });

            var actionResult = await controller.ProcessOrderPlacedPush(rawOrder);

            Assert.IsInstanceOf<OkNegotiatedContentResult<ApiResponse<OrderExecutedEvent>>>(actionResult);
            var okResult = (OkNegotiatedContentResult<ApiResponse<OrderExecutedEvent>>)actionResult;
            Assert.IsTrue(okResult.Content.Success);
            Assert.AreEqual("FILLED", okResult.Content.Data.Status);
            Assert.AreEqual(888, okResult.Content.Data.TradeId);
        }

        [Test]
        public async Task PubSubWebhookController_ProcessesNativePubSubPushEnvelope_DecodesBase64_ReturnsOk()
        {
            var mockProcessor = new Mock<IOrderExecutionProcessor>();
            mockProcessor
                .Setup(p => p.ProcessOrderAsync(It.IsAny<OrderPlacedEvent>()))
                .ReturnsAsync(new OrderExecutedEvent
                {
                    CorrelationId = Guid.NewGuid(),
                    UserId = 10,
                    Symbol = "AVAX",
                    Side = "BUY",
                    Status = "FILLED"
                });

            var config = new PubSubConfig();
            var controller = new PubSubWebhookController(mockProcessor.Object, config, _mockLogger.Object);

            var order = new OrderPlacedEvent
            {
                CorrelationId = Guid.NewGuid(),
                UserId = 10,
                Symbol = "AVAX",
                Side = "BUY",
                Quantity = 25.0m
            };

            var orderJson = JsonConvert.SerializeObject(order);
            var base64Data = Convert.ToBase64String(Encoding.UTF8.GetBytes(orderJson));

            // Standard Google Cloud Pub/Sub Push envelope
            var pubsubPushEnvelope = new JObject
            {
                ["message"] = new JObject
                {
                    ["data"] = base64Data,
                    ["messageId"] = "2070443601872934",
                    ["orderingKey"] = "AVAX",
                    ["publishTime"] = DateTime.UtcNow.ToString("o")
                },
                ["subscription"] = "projects/my-gcp-project/subscriptions/crypto-orders-incoming-sub"
            };

            var actionResult = await controller.ProcessOrderPlacedPush(pubsubPushEnvelope);

            Assert.IsInstanceOf<OkNegotiatedContentResult<ApiResponse<OrderExecutedEvent>>>(actionResult);
            var okResult = (OkNegotiatedContentResult<ApiResponse<OrderExecutedEvent>>)actionResult;
            Assert.IsTrue(okResult.Content.Success);
            Assert.AreEqual("FILLED", okResult.Content.Data.Status);
        }

        [Test]
        public async Task PubSubWebhookController_RejectsInvalidSecret_WhenConfigured()
        {
            var mockProcessor = new Mock<IOrderExecutionProcessor>();
            var config = new PubSubConfig
            {
                PushEndpointSecret = "SECRET_GCP_999"
            };

            var controller = new PubSubWebhookController(mockProcessor.Object, config, _mockLogger.Object);

            var rawOrder = JToken.FromObject(new OrderPlacedEvent
            {
                CorrelationId = Guid.NewGuid(),
                UserId = 1,
                Symbol = "BTC",
                Quantity = 1.0m
            });

            var actionResult = await controller.ProcessOrderPlacedPush(rawOrder);

            Assert.IsInstanceOf<ResponseMessageResult>(actionResult);
            var responseResult = (ResponseMessageResult)actionResult;
            Assert.AreEqual(System.Net.HttpStatusCode.Unauthorized, responseResult.Response.StatusCode);
        }

        [Test]
        public void PubSubManager_StartsAndStops_Successfully()
        {
            var config = new PubSubConfig
            {
                Enabled = true,
                TickSubscriberEnabled = true,
                MarketTicksTopic = "crypto-market-ticks",
                OrdersIncomingTopic = "crypto-orders-incoming",
                OrdersExecutedTopic = "crypto-orders-executed"
            };

            var mockTradingService = new Mock<ITradingService>();
            var manager = new PubSubManager(config, _mockLogger.Object, () => mockTradingService.Object);

            Assert.DoesNotThrow(() => manager.Start());
            Assert.IsTrue(manager.IsRunning);

            Assert.DoesNotThrow(() => manager.Stop());
            Assert.IsFalse(manager.IsRunning);
        }
    }
}

