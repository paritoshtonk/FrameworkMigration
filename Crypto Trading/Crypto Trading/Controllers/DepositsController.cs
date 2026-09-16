using System.Threading.Tasks;
using System.Web.Http;
using CryptoTrading.Business.Services;
using CryptoTrading.Models.Requests;
using CryptoTrading.Web.Security;

namespace CryptoTrading.Web.Controllers
{
    [JwtAuthorize]
    [RoutePrefix("api/deposits")]
    public class DepositsController : BaseApiController
    {
        private readonly IFinancialService _financialService;

        public DepositsController() : this(DependencyConfig.FinancialService)
        {
        }

        public DepositsController(IFinancialService financialService)
        {
            _financialService = financialService;
        }

        [HttpPost]
        [Route("")]
        public async Task<IHttpActionResult> Deposit([FromBody] DepositRequest request)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var deposit = await _financialService.DepositAsync(CurrentUserId, request);
            return CreatedResponse(deposit, "Deposit completed successfully.");
        }

        [HttpGet]
        [Route("")]
        public async Task<IHttpActionResult> GetDeposits([FromUri] int limit = 100)
        {
            var deposits = await _financialService.GetDepositsAsync(CurrentUserId, limit);
            return OkResponse(deposits);
        }
    }
}

