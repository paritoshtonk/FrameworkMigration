using System;
using System.Threading;
using CryptoTrading.Business.Services;
using CryptoTrading.Infrastructure.Logging;

namespace CryptoTrading.Infrastructure.PubSub
{
    /// <summary>
    /// Lifecycle coordinator for Google Cloud Pub/Sub publisher, subscribers, and background hot cache workers.
    /// </summary>
    public class PubSubManager : IDisposable
    {
        private readonly PubSubConfig _config;
        private readonly ILoggerService _logger;
        private readonly IPubSubPublisher _publisher;
        private readonly IPubSubSubscriber _subscriber;
        private readonly MarketTickHotCacheSubscriber _tickSubscriber;
        private readonly IOrderExecutionProcessor _orderProcessor;
        private readonly CancellationTokenSource _cts = new CancellationTokenSource();
        private bool _isRunning = false;

        public IPubSubPublisher Publisher => _publisher;
        public IPubSubSubscriber Subscriber => _subscriber;
        public MarketTickHotCacheSubscriber TickSubscriber => _tickSubscriber;
        public IOrderExecutionProcessor OrderProcessor => _orderProcessor;
        public bool IsRunning => _isRunning;

        public PubSubManager(
            PubSubConfig config,
            ILoggerService logger,
            Func<ITradingService> tradingServiceFactory,
            IOrderExecutionProcessor orderProcessor = null)
        {
            _config = config ?? PubSubConfig.FromConfiguration();
            _logger = logger;

            _publisher = new PubSubPublisher(_config, _logger);
            _subscriber = new PubSubSubscriber(_config, _logger);
            _orderProcessor = orderProcessor ?? new OrderExecutionProcessor(tradingServiceFactory, _publisher, _config, _logger);
            _tickSubscriber = new MarketTickHotCacheSubscriber(_subscriber, _config, _logger);
        }

        public void Start()
        {
            if (_isRunning) return;

            _logger?.Info("[PubSubManager] Initializing Google Cloud Pub/Sub streaming services...");

            if (_config.Enabled && _config.TickSubscriberEnabled)
            {
                _tickSubscriber.Start(_cts.Token);
                _logger?.Info("[PubSubManager] MarketTickHotCacheSubscriber started (real-time price streaming).");
            }
            else
            {
                _logger?.Info("[PubSubManager] MarketTickHotCacheSubscriber disabled.");
            }

            _isRunning = true;
            _logger?.Info("[PubSubManager] Google Cloud Pub/Sub event messaging is active.");
        }

        public void Stop()
        {
            if (!_isRunning) return;

            _logger?.Info("[PubSubManager] Stopping Google Cloud Pub/Sub services...");
            _cts.Cancel();
            _subscriber?.Stop();
            _isRunning = false;
        }

        public void Dispose()
        {
            Stop();
            _publisher?.Dispose();
            _subscriber?.Dispose();
            _tickSubscriber?.Dispose();
            _cts?.Dispose();
        }
    }
}

