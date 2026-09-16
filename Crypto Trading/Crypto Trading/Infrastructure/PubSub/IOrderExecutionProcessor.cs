using System.Threading.Tasks;

namespace CryptoTrading.Infrastructure.PubSub
{
    public interface IOrderExecutionProcessor
    {
        Task<OrderExecutedEvent> ProcessOrderAsync(OrderPlacedEvent order);
    }
}

