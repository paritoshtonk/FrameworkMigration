using System.Net;
using System.Net.Http;
using System.Web.Http;
using CryptoTrading.Models.Requests;
using CryptoTrading.Web.Security;

namespace CryptoTrading.Web.Controllers
{
    public abstract class BaseApiController : ApiController
    {
        protected int CurrentUserId => Request.GetAuthenticatedUserId();
        protected string CurrentUsername => Request.GetAuthenticatedUsername();

        protected IHttpActionResult OkResponse<T>(T data, string message = null)
        {
            return Ok(ApiResponse<T>.Ok(data, message));
        }

        protected IHttpActionResult NoCacheOkResponse<T>(T data, string message = null)
        {
            var response = Request.CreateResponse(HttpStatusCode.OK, ApiResponse<T>.Ok(data, message));
            response.Headers.CacheControl = new System.Net.Http.Headers.CacheControlHeaderValue
            {
                NoCache = true,
                NoStore = true,
                MustRevalidate = true
            };
            response.Headers.Pragma.ParseAdd("no-cache");
            return ResponseMessage(response);
        }

        protected IHttpActionResult CreatedResponse<T>(T data, string message = null)
        {
            var response = Request.CreateResponse(HttpStatusCode.Created, ApiResponse<T>.Ok(data, message));
            return ResponseMessage(response);
        }

        protected IHttpActionResult ErrorResponse(string message, string errorCode = "ERROR", HttpStatusCode status = HttpStatusCode.BadRequest)
        {
            var response = Request.CreateResponse(status, ApiErrorResponse.Fail(message, errorCode));
            return ResponseMessage(response);
        }
    }
}

