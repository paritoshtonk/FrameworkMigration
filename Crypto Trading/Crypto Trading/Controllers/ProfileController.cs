using System.Threading.Tasks;
using System.Web.Http;
using CryptoTrading.Business.Services;
using CryptoTrading.Models.Requests;
using CryptoTrading.Web.Security;

namespace CryptoTrading.Web.Controllers
{
    [JwtAuthorize]
    [RoutePrefix("api/profile")]
    public class ProfileController : BaseApiController
    {
        private readonly IUserService _userService;

        public ProfileController() : this(DependencyConfig.UserService)
        {
        }

        public ProfileController(IUserService userService)
        {
            _userService = userService;
        }

        [HttpGet]
        [Route("")]
        public async Task<IHttpActionResult> GetProfile()
        {
            var profile = await _userService.GetUserProfileAsync(CurrentUserId);
            return OkResponse(profile);
        }

        [HttpPut]
        [Route("")]
        public async Task<IHttpActionResult> UpdateProfile([FromBody] UpdateProfileRequest request)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var updated = await _userService.UpdateUserProfileAsync(CurrentUserId, request);
            return OkResponse(updated, "Profile updated successfully.");
        }
    }
}

