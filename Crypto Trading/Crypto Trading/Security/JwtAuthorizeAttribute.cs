using System;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Security.Claims;
using System.Threading;
using System.Threading.Tasks;
using System.Web;
using System.Web.Http.Controllers;
using System.Web.Http.Filters;
using CryptoTrading.Infrastructure.Security;
using CryptoTrading.Models.Requests;

namespace CryptoTrading.Web.Security
{
    [AttributeUsage(AttributeTargets.Class | AttributeTargets.Method, Inherited = true, AllowMultiple = false)]
    public class JwtAuthorizeAttribute : AuthorizationFilterAttribute
    {
        private static readonly ITokenService _tokenService = new JwtTokenService();

        public override Task OnAuthorizationAsync(HttpActionContext actionContext, CancellationToken cancellationToken)
        {
            // Allow anonymous access if [AllowAnonymous] is present
            if (actionContext.ActionDescriptor.GetCustomAttributes<System.Web.Http.AllowAnonymousAttribute>().Any() ||
                actionContext.ControllerContext.ControllerDescriptor.GetCustomAttributes<System.Web.Http.AllowAnonymousAttribute>().Any())
            {
                return Task.CompletedTask;
            }

            var authHeader = actionContext.Request.Headers.Authorization;
            if (authHeader == null || !string.Equals(authHeader.Scheme, "Bearer", StringComparison.OrdinalIgnoreCase) || string.IsNullOrWhiteSpace(authHeader.Parameter))
            {
                actionContext.Response = actionContext.Request.CreateResponse(
                    HttpStatusCode.Unauthorized,
                    ApiErrorResponse.Fail("Authorization header with Bearer token is required.", "UNAUTHORIZED")
                );
                return Task.CompletedTask;
            }

            var token = authHeader.Parameter.Trim();
            var principal = _tokenService.ValidateToken(token);

            if (principal == null || !principal.Identity.IsAuthenticated)
            {
                actionContext.Response = actionContext.Request.CreateResponse(
                    HttpStatusCode.Unauthorized,
                    ApiErrorResponse.Fail("Invalid or expired authentication token.", "INVALID_TOKEN")
                );
                return Task.CompletedTask;
            }

            // Set current principal for request and thread
            actionContext.RequestContext.Principal = principal;
            Thread.CurrentPrincipal = principal;
            if (HttpContext.Current != null)
            {
                HttpContext.Current.User = principal;
            }

            return Task.CompletedTask;
        }
    }

    public static class SecurityExtensions
    {
        public static int GetAuthenticatedUserId(this HttpRequestMessage request)
        {
            var user = request.GetRequestContext()?.Principal as ClaimsPrincipal;
            if (user == null)
                throw new UnauthorizedAccessException("Request is not authenticated.");

            var claim = user.FindFirst(ClaimTypes.NameIdentifier);
            if (claim == null || !int.TryParse(claim.Value, out int userId))
                throw new UnauthorizedAccessException("User identifier claim is missing or invalid.");

            return userId;
        }

        public static string GetAuthenticatedUsername(this HttpRequestMessage request)
        {
            var user = request.GetRequestContext()?.Principal as ClaimsPrincipal;
            return user?.FindFirst(ClaimTypes.Name)?.Value;
        }
    }
}

