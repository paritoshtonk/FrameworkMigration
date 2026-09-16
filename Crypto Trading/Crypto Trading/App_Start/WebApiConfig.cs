using System.Net.Http.Formatting;
using System.Web.Http;
using System.Web.Http.Cors;
using Newtonsoft.Json;
using Newtonsoft.Json.Serialization;
using CryptoTrading.Web.Filters;

namespace CryptoTrading.Web
{
    public static class WebApiConfig
    {
        public static void Register(HttpConfiguration config)
        {
            // 1. Enable CORS for all origins (or configurable via Web.config)
            var cors = new EnableCorsAttribute("*", "*", "*");
            config.EnableCors(cors);

            // 2. Global Exception Filter
            config.Filters.Add(new ApiExceptionFilterAttribute());

            // 3. Web API attribute routing
            config.MapHttpAttributeRoutes();

            // 4. Default Convention Routing: api/{controller}/{id}
            config.Routes.MapHttpRoute(
                name: "DefaultApi",
                routeTemplate: "api/{controller}/{id}",
                defaults: new { id = RouteParameter.Optional }
            );

            // 5. JSON Formatter Settings (camelCase naming, ISO dates, ignore null values optional)
            config.Formatters.Clear();
            var jsonFormatter = new JsonMediaTypeFormatter();
            jsonFormatter.SerializerSettings.ContractResolver = new CamelCasePropertyNamesContractResolver();
            jsonFormatter.SerializerSettings.DateTimeZoneHandling = DateTimeZoneHandling.Utc;
            jsonFormatter.SerializerSettings.DateFormatString = "yyyy'-'MM'-'dd'T'HH':'mm':'ss.fffK";
            jsonFormatter.SerializerSettings.ReferenceLoopHandling = ReferenceLoopHandling.Ignore;
            config.Formatters.Add(jsonFormatter);

            // 6. Swagger API Documentation & Swagger UI
            SwaggerConfig.Register(config);
        }
    }
}

