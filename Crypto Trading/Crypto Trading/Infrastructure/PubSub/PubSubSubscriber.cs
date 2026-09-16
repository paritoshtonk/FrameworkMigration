using System;
using System.Threading;
using System.Threading.Tasks;
using CryptoTrading.Infrastructure.Logging;
using Newtonsoft.Json;

namespace CryptoTrading.Infrastructure.PubSub
{
    /// <summary>
    /// Google Cloud Pub/Sub Subscriber supporting in-memory event bus and pull/push subscription models.
    /// </summary>
    public class PubSubSubscriber : IPubSubSubscriber
    {
        private readonly PubSubConfig _config;
        private readonly ILoggerService _logger;
        private readonly PubSubMessageHub _hub;
        private long _messagesReceivedCount = 0;
        private bool _isStopped = false;

        public bool IsActive => _config != null && _config.Enabled && !_isStopped;
        public long MessagesReceivedCount => Interlocked.Read(ref _messagesReceivedCount);

        public PubSubSubscriber(PubSubConfig config, ILoggerService logger)
        {
            _config = config ?? PubSubConfig.FromConfiguration();
            _logger = logger;
            _hub = PubSubMessageHub.Instance;
        }

        public void Subscribe<T>(string topicOrSubscriptionId, Func<string, T, Task> messageHandler, CancellationToken cancellationToken = default)
        {
            if (string.IsNullOrWhiteSpace(topicOrSubscriptionId))
                throw new ArgumentException("Topic or Subscription ID cannot be empty", nameof(topicOrSubscriptionId));
            if (messageHandler == null)
                throw new ArgumentNullException(nameof(messageHandler));

            _logger?.Info($"[PubSubSubscriber] Registering subscription for '{topicOrSubscriptionId}'...");

            _hub.Subscribe(topicOrSubscriptionId, async (orderingKey, jsonPayload, attributes) =>
            {
                if (_isStopped || cancellationToken.IsCancellationRequested) return;

                try
                {
                    Interlocked.Increment(ref _messagesReceivedCount);
                    var deserialized = JsonConvert.DeserializeObject<T>(jsonPayload);
                    if (deserialized != null)
                    {
                        await messageHandler(orderingKey, deserialized);
                    }
                }
                catch (Exception ex)
                {
                    _logger?.Error($"[PubSubSubscriber] Error processing message on '{topicOrSubscriptionId}' with key '{orderingKey}': {ex.Message}", ex);
                }
            });
        }

        public void Stop()
        {
            _isStopped = true;
            _logger?.Info("[PubSubSubscriber] Subscriptions stopped.");
        }

        public void Dispose()
        {
            Stop();
        }
    }
}

