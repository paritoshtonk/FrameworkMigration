using System;
using System.Configuration;

namespace CryptoTrading.Infrastructure.PubSub
{
    /// <summary>
    /// Configuration for Google Cloud Pub/Sub messaging.
    /// Follows the 12-Factor App pattern: environment variables override Web.config settings.
    /// </summary>
    public class PubSubConfig
    {
        public bool Enabled { get; set; }
        public string ProjectId { get; set; }
        public string EmulatorHost { get; set; }
        public string OrdersIncomingTopic { get; set; }
        public string OrdersExecutedTopic { get; set; }
        public string MarketTicksTopic { get; set; }
        public string OrderPushSubscription { get; set; }
        public string TickSubscription { get; set; }
        public string PushEndpointSecret { get; set; }
        public bool TickSubscriberEnabled { get; set; }

        public static PubSubConfig FromConfiguration()
        {
            var config = new PubSubConfig();

            var enabledEnv = Environment.GetEnvironmentVariable("PUBSUB_ENABLED");
            var enabledApp = ConfigurationManager.AppSettings["PubSub:Enabled"];
            config.Enabled = !string.IsNullOrEmpty(enabledEnv)
                ? (bool.TryParse(enabledEnv, out var b) ? b : true)
                : (!string.IsNullOrEmpty(enabledApp) && (bool.TryParse(enabledApp, out var b2) ? b2 : true));

            config.ProjectId = Environment.GetEnvironmentVariable("PUBSUB_PROJECT_ID")
                ?? Environment.GetEnvironmentVariable("GOOGLE_CLOUD_PROJECT")
                ?? ConfigurationManager.AppSettings["PubSub:ProjectId"]
                ?? "cryptotrading-gcp-dev";

            config.EmulatorHost = Environment.GetEnvironmentVariable("PUBSUB_EMULATOR_HOST")
                ?? ConfigurationManager.AppSettings["PubSub:EmulatorHost"]
                ?? "localhost:8085";

            config.OrdersIncomingTopic = Environment.GetEnvironmentVariable("PUBSUB_ORDERS_INCOMING_TOPIC")
                ?? ConfigurationManager.AppSettings["PubSub:OrdersIncomingTopic"]
                ?? "crypto-orders-incoming";

            config.OrdersExecutedTopic = Environment.GetEnvironmentVariable("PUBSUB_ORDERS_EXECUTED_TOPIC")
                ?? ConfigurationManager.AppSettings["PubSub:OrdersExecutedTopic"]
                ?? "crypto-orders-executed";

            config.MarketTicksTopic = Environment.GetEnvironmentVariable("PUBSUB_MARKET_TICKS_TOPIC")
                ?? ConfigurationManager.AppSettings["PubSub:MarketTicksTopic"]
                ?? "crypto-market-ticks";

            config.OrderPushSubscription = Environment.GetEnvironmentVariable("PUBSUB_ORDER_PUSH_SUBSCRIPTION")
                ?? ConfigurationManager.AppSettings["PubSub:OrderPushSubscription"]
                ?? "crypto-orders-incoming-sub";

            config.TickSubscription = Environment.GetEnvironmentVariable("PUBSUB_TICK_SUBSCRIPTION")
                ?? ConfigurationManager.AppSettings["PubSub:TickSubscription"]
                ?? "crypto-market-ticks-sub";

            config.PushEndpointSecret = Environment.GetEnvironmentVariable("PUBSUB_PUSH_ENDPOINT_SECRET")
                ?? ConfigurationManager.AppSettings["PubSub:PushEndpointSecret"];

            var tickSubEnv = Environment.GetEnvironmentVariable("PUBSUB_TICK_SUBSCRIBER_ENABLED");
            var tickSubApp = ConfigurationManager.AppSettings["PubSub:TickSubscriberEnabled"];
            config.TickSubscriberEnabled = !string.IsNullOrEmpty(tickSubEnv)
                ? (bool.TryParse(tickSubEnv, out var ts) ? ts : true)
                : (!string.IsNullOrEmpty(tickSubApp) ? (bool.TryParse(tickSubApp, out var ts2) ? ts2 : true) : true);

            return config;
        }
    }
}

