using System;
using System.Threading;
using System.Threading.Tasks;

namespace CryptoTrading.Infrastructure.PubSub
{
    public interface IPubSubSubscriber : IDisposable
    {
        bool IsActive { get; }
        long MessagesReceivedCount { get; }
        void Subscribe<T>(string topicOrSubscriptionId, Func<string, T, Task> messageHandler, CancellationToken cancellationToken = default);
        void Stop();
    }
}

