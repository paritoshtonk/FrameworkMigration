using System.Threading.Tasks;
using System.Web.Http;
using CryptoTrading.Business.Services;
using CryptoTrading.Web.Security;

namespace CryptoTrading.Web.Controllers
{
    [JwtAuthorize]
    [RoutePrefix("api/transactions")]
    public class TransactionsController : BaseApiController
    {
        private readonly IFinancialService _financialService;

        public TransactionsController() : this(DependencyConfig.FinancialService)
        {
        }

        public TransactionsController(IFinancialService financialService)
        {
            _financialService = financialService;
        }

        [HttpGet]
        [Route("")]
        public async Task<IHttpActionResult> GetTransactions([FromUri] int limit = 100)
        {
            var txs = await _financialService.GetTransactionsAsync(CurrentUserId, limit);
            return OkResponse(txs);
        }

        [HttpGet]
        [Route("{id:int}")]
        public async Task<IHttpActionResult> GetTransactionById(int id)
        {
            var tx = await _financialService.GetTransactionByIdAsync(id, CurrentUserId);
            return OkResponse(tx);
        }
    }
}

