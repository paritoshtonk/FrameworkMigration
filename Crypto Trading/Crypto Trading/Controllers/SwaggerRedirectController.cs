using System;
using System.Net;
using System.Net.Http;
using System.Web.Http;

namespace CryptoTrading.Web.Controllers
{
    /// <summary>
    /// Redirects root requests directly to the Swagger UI documentation page by default.
    /// </summary>
    [AllowAnonymous]
    public class SwaggerRedirectController : ApiController
    {
        [HttpGet]
        [Route("")]
        public HttpResponseMessage Index()
        {
            var response = Request.CreateResponse(HttpStatusCode.MovedPermanently);
            response.Headers.Location = new Uri(Request.RequestUri, "swagger");
            return response;
        }
    }
}

