using System;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using System.Web.Http;
using CryptoTrading.Infrastructure.Logging;
using CryptoTrading.Infrastructure.PubSub;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace CryptoTrading.Web.Controllers
{
    /// <summary>
    /// Google Cloud Pub/Sub Push Subscription receiver.
    /// Cloud Run instances can scale to zero; Pub/Sub delivers HTTP POST events directly to these endpoints,
    /// triggering atomic order execution and post-trade notifications without 24/7 consumer polling loops.
    /// </summary>
    [RoutePrefix("api/pubsub")]
    public class PubSubWebhookController : BaseApiController
    {
        private readonly IOrderExecutionProcessor _orderProcessor;
        private readonly PubSubConfig _config;
        private readonly ILoggerService _logger;

        public PubSubWebhookController()
            : this(DependencyConfig.OrderExecutionProcessor, DependencyConfig.PubSubConfig, DependencyConfig.Logger)
        {
        }

        public PubSubWebhookController(
            IOrderExecutionProcessor orderProcessor,
            PubSubConfig config,
            ILoggerService logger)
        {
            _orderProcessor = orderProcessor;
            _config = config;
            _logger = logger;
            Request = new HttpRequestMessage();
            Request.SetConfiguration(new HttpConfiguration());
        }

        /// <summary>
        /// Native Google Cloud Pub/Sub Push endpoint for incoming trade orders.
        /// Automatically decodes Base64 message.data from the Pub/Sub push envelope,
        /// executes the trade atomically, and emits the completion event with OrderingKey=Symbol.
        /// </summary>
        [HttpPost]
        [Route("order-placed")]
        public async Task<IHttpActionResult> ProcessOrderPlacedPush([FromBody] JToken payload)
        {
            if (!ValidatePushSecurity())
            {
                return ErrorResponse("Unauthorized Pub/Sub push request: invalid secret token.", "UNAUTHORIZED_PUBSUB", HttpStatusCode.Unauthorized);
            }

            if (payload == null)
            {
                return ErrorResponse("Pub/Sub message payload cannot be empty.", "INVALID_PAYLOAD", HttpStatusCode.BadRequest);
            }

            try
            {
                var order = ExtractOrderPlaced(payload);
                if (order == null || order.UserId <= 0 || string.IsNullOrWhiteSpace(order.Symbol))
                {
                    return ErrorResponse("Invalid OrderPlacedEvent payload structure.", "MALFORMED_EVENT", HttpStatusCode.BadRequest);
                }

                _logger?.Info($"[PubSub:Webhook] Received OrderPlacedEvent: CorrelationId={order.CorrelationId}, Symbol={order.Symbol}, Side={order.Side}, Quantity={order.Quantity}");

                var result = await _orderProcessor.ProcessOrderAsync(order);

                // Return 200 OK to acknowledge (ACK) the Pub/Sub message
                return OkResponse(result, $"Pub/Sub Order {order.CorrelationId} acknowledged with status: {result.Status}");
            }
            catch (Exception ex)
            {
                _logger?.Error($"[PubSub:Webhook] Order execution failed: {ex.Message}", ex);
                return ErrorResponse($"Order execution failed: {ex.Message}", "ORDER_EXECUTION_FAILED", HttpStatusCode.InternalServerError);
            }
        }

        /// <summary>
        /// Native Google Cloud Pub/Sub Push endpoint for executed order notifications and auditing.
        /// </summary>
        [HttpPost]
        [Route("order-executed")]
        public IHttpActionResult ProcessOrderExecutedPush([FromBody] JToken payload)
        {
            if (!ValidatePushSecurity())
            {
                return ErrorResponse("Unauthorized Pub/Sub push request: invalid secret token.", "UNAUTHORIZED_PUBSUB", HttpStatusCode.Unauthorized);
            }

            if (payload == null)
            {
                return ErrorResponse("Pub/Sub message payload cannot be empty.", "INVALID_PAYLOAD", HttpStatusCode.BadRequest);
            }

            try
            {
                var executed = ExtractOrderExecuted(payload);
                if (executed == null)
                {
                    return ErrorResponse("Invalid OrderExecutedEvent payload.", "MALFORMED_EVENT", HttpStatusCode.BadRequest);
                }

                _logger?.Info($"[PubSub:Audit] Trade Notification: Order {executed.CorrelationId} ({executed.Symbol} {executed.Side}) -> Status={executed.Status}, TradeId={executed.TradeId}, Total=${executed.TotalAmount}");

                return OkResponse(new
                {
                    Acknowledged = true,
                    CorrelationId = executed.CorrelationId,
                    Status = executed.Status,
                    TradeId = executed.TradeId,
                    Timestamp = DateTime.UtcNow
                }, "Order execution audit recorded.");
            }
            catch (Exception ex)
            {
                _logger?.Error($"[PubSub:Webhook] Audit notification failed: {ex.Message}", ex);
                return ErrorResponse($"Audit notification failed: {ex.Message}", "AUDIT_FAILED", HttpStatusCode.InternalServerError);
            }
        }

        private bool ValidatePushSecurity()
        {
            var expectedSecret = _config?.PushEndpointSecret;
            if (string.IsNullOrWhiteSpace(expectedSecret))
            {
                return true; // No secret configured; allow open local dev
            }

            if (Request == null || Request.Headers == null)
            {
                return false;
            }

            // Check custom header
            if (Request.Headers.TryGetValues("X-PubSub-Secret", out var headerValues) &&
                headerValues.Any(v => string.Equals(v, expectedSecret, StringComparison.Ordinal)))
            {
                return true;
            }

            // Check query string ?secret=...
            var query = Request.GetQueryNameValuePairs();
            if (query != null && query.Any(kvp => string.Equals(kvp.Key, "secret", StringComparison.OrdinalIgnoreCase) && string.Equals(kvp.Value, expectedSecret, StringComparison.Ordinal)))
            {
                return true;
            }

            return false;
        }

        private static OrderPlacedEvent ExtractOrderPlaced(JToken token)
        {
            if (token is JObject obj && obj["message"] != null && obj["message"]["data"] != null)
            {
                // Standard Google Cloud Pub/Sub Push envelope
                var base64Data = obj["message"]["data"]?.ToString();
                if (!string.IsNullOrWhiteSpace(base64Data))
                {
                    var jsonBytes = Convert.FromBase64String(base64Data);
                    var jsonStr = Encoding.UTF8.GetString(jsonBytes);
                    return JsonConvert.DeserializeObject<OrderPlacedEvent>(jsonStr);
                }
            }

            return token.ToObject<OrderPlacedEvent>();
        }

        private static OrderExecutedEvent ExtractOrderExecuted(JToken token)
        {
            if (token is JObject obj && obj["message"] != null && obj["message"]["data"] != null)
            {
                // Standard Google Cloud Pub/Sub Push envelope
                var base64Data = obj["message"]["data"]?.ToString();
                if (!string.IsNullOrWhiteSpace(base64Data))
                {
                    var jsonBytes = Convert.FromBase64String(base64Data);
                    var jsonStr = Encoding.UTF8.GetString(jsonBytes);
                    return JsonConvert.DeserializeObject<OrderExecutedEvent>(jsonStr);
                }
            }

            return token.ToObject<OrderExecutedEvent>();
        }
    }
}

