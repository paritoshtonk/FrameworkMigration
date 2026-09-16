using System;
using System.Web;
using System.Web.Http;
using log4net.Config;

namespace CryptoTrading.Web
{
    public class WebApiApplication : HttpApplication
    {
        protected void Application_Start()
        {
            XmlConfigurator.Configure();
            GlobalConfiguration.Configure(WebApiConfig.Register);

            // Initialize and start Google Cloud Pub/Sub streaming workers
            try
            {
                DependencyConfig.PubSubManager.Start();
            }
            catch (Exception ex)
            {
                DependencyConfig.Logger?.Error($"Failed to start Google Cloud Pub/Sub services: {ex.Message}", ex);
            }
        }

        protected void Application_End()
        {
            try
            {
                DependencyConfig.PubSubManager.Stop();
            }
            catch (Exception ex)
            {
                DependencyConfig.Logger?.Error($"Failed to stop Google Cloud Pub/Sub services: {ex.Message}", ex);
            }
        }
    }
}

