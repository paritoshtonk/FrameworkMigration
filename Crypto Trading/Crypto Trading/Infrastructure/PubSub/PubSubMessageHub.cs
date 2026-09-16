using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace CryptoTrading.Infrastructure.PubSub
{
    /// <summary>
    /// In-memory pub/sub message hub for lightning-fast local development,
    /// automated unit/integration testing, and offline fallback.
    /// </summary>
    public class PubSubMessageHub
    {
        private static readonly Lazy<PubSubMessageHub> _instance = 
            new Lazy<PubSubMessageHub>(() => new PubSubMessageHub());

        public static PubSubMessageHub Instance => _instance.Value;

        private readonly ConcurrentDictionary<string, List<Func<string, string, IDictionary<string, string>, Task>>> _subscriptions =
            new ConcurrentDictionary<string, List<Func<string, string, IDictionary<string, string>, Task>>>(StringComparer.OrdinalIgnoreCase);

        private PubSubMessageHub() { }

        public async Task PublishAsync(string topicId, string orderingKey, string jsonPayload, IDictionary<string, string> attributes = null)
        {
            if (string.IsNullOrWhiteSpace(topicId)) return;

            if (_subscriptions.TryGetValue(topicId, out var handlers))
            {
                List<Func<string, string, IDictionary<string, string>, Task>> snapshot;
                lock (handlers)
                {
                    snapshot = new List<Func<string, string, IDictionary<string, string>, Task>>(handlers);
                }

                foreach (var handler in snapshot)
                {
                    try
                    {
                        await handler(orderingKey, jsonPayload, attributes ?? new Dictionary<string, string>());
                    }
                    catch
                    {
                        // Prevent subscriber failure from breaking the hub
                    }
                }
            }
        }

        public void Subscribe(string topicId, Func<string, string, IDictionary<string, string>, Task> handler)
        {
            if (string.IsNullOrWhiteSpace(topicId) || handler == null) return;

            _subscriptions.AddOrUpdate(
                topicId,
                key => new List<Func<string, string, IDictionary<string, string>, Task>> { handler },
                (key, existing) =>
                {
                    lock (existing)
                    {
                        existing.Add(handler);
                    }
                    return existing;
                });
        }

        public void Clear()
        {
            _subscriptions.Clear();
        }
    }
}

