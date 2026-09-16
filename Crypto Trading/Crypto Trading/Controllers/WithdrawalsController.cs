using System.Threading.Tasks;
using System.Web.Http;
using CryptoTrading.Business.Services;
using CryptoTrading.Models.Requests;
using CryptoTrading.Web.Security;

namespace CryptoTrading.Web.Controllers
{
    [JwtAuthorize]
    [RoutePrefix("api/withdrawals")]
    public class WithdrawalsController : BaseApiController
    {
        private readonly IFinancialService _financialService;

        public WithdrawalsController() : this(DependencyConfig.FinancialService)
        {
        }

        public WithdrawalsController(IFinancialService financialService)
        {
            _financialService = financialService;
        }

        [HttpPost]
        [Route("")]
        public async Task<IHttpActionResult> Withdraw([FromBody] WithdrawalRequest request)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var withdrawal = await _financialService.WithdrawAsync(CurrentUserId, request);
            return CreatedResponse(withdrawal, "Withdrawal completed successfully.");
        }

        [HttpGet]
        [Route("")]
        public async Task<IHttpActionResult> GetWithdrawals([FromUri] int limit = 100)
        {
            var withdrawals = await _financialService.GetWithdrawalsAsync(CurrentUserId, limit);
            return OkResponse(withdrawals);
        }
    }
}

