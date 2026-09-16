using System;
using System.Threading.Tasks;
using System.Web.Http;
using CryptoTrading.Business.Services;
using CryptoTrading.Models.DTOs;
using CryptoTrading.Models.Requests;
using CryptoTrading.Web.Security;

namespace CryptoTrading.Web.Controllers
{
    [RoutePrefix("api/auth")]
    public class AuthController : BaseApiController
    {
        private readonly IAuthService _authService;

        public AuthController() : this(DependencyConfig.AuthService)
        {
        }

        public AuthController(IAuthService authService)
        {
            _authService = authService;
        }

        [HttpPost]
        [Route("register")]
        [AllowAnonymous]
        public async Task<IHttpActionResult> Register([FromBody] RegisterRequest request)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var result = await _authService.RegisterAsync(request);
            return CreatedResponse(result, "User registered successfully.");
        }

        [HttpPost]
        [Route("login")]
        [AllowAnonymous]
        public async Task<IHttpActionResult> Login([FromBody] LoginRequest request)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var result = await _authService.LoginAsync(request);
            return OkResponse(result, "Login successful.");
        }

        [HttpPost]
        [Route("logout")]
        [JwtAuthorize]
        public IHttpActionResult Logout()
        {
            // Stateless JWT logout
            return OkResponse(true, "Logged out successfully.");
        }

        [HttpGet]
        [Route("me")]
        [JwtAuthorize]
        public async Task<IHttpActionResult> Me()
        {
            var user = await _authService.GetCurrentUserAsync(CurrentUserId);
            if (user == null)
                return NotFound();

            return OkResponse(user);
        }
    }
}

