using System.IO;
using System.Web.Http;
using Swashbuckle.Application;

namespace CryptoTrading.Web
{
    public static class SwaggerConfig
    {
        public static void Register(HttpConfiguration config)
        {
            config.EnableSwagger(c =>
            {
                c.SingleApiVersion("v1", "CryptoTrading Legacy REST API")
                 .Description("ASP.NET Web API 2 backend for Cryptocurrency Paper Trading platform. Authenticate via Bearer JWT token.")
                 .Contact(cc => cc.Name("CryptoTrading Team"));

                // Define Bearer Token security scheme in Swagger
                c.ApiKey("Bearer")
                 .Description("Enter JWT Bearer token: Bearer {token}")
                 .Name("Authorization")
                 .In("header");

                // Include XML comments if present
                var baseDirectory = System.AppDomain.CurrentDomain.BaseDirectory;
                var xmlCommentsPath = Path.Combine(baseDirectory, "bin", "CryptoTrading.Web.xml");
                if (File.Exists(xmlCommentsPath))
                {
                    c.IncludeXmlComments(xmlCommentsPath);
                }
            })
            .EnableSwaggerUi(c =>
            {
                c.DocumentTitle("CryptoTrading API Documentation");
                c.EnableApiKeySupport("Authorization", "header");
            });
        }
    }
}

