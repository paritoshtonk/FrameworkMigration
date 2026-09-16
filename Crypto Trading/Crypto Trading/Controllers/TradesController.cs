using System.Threading.Tasks;
using System.Web.Http;
using CryptoTrading.Business.Services;
using CryptoTrading.Models.Requests;
using CryptoTrading.Web.Security;

namespace CryptoTrading.Web.Controllers
{
    [JwtAuthorize]
    [RoutePrefix("api/trades")]
    public class TradesController : BaseApiController
    {
        private readonly ITradingService _tradingService;

        public TradesController() : this(DependencyConfig.TradingService)
        {
        }

        public TradesController(ITradingService tradingService)
        {
            _tradingService = tradingService;
        }

        [HttpPost]
        [Route("buy")]
        public async Task<IHttpActionResult> Buy([FromBody] BuyTradeRequest request)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var trade = await _tradingService.BuyAsync(CurrentUserId, request);
            return CreatedResponse(trade, "Cryptocurrency purchase executed successfully.");
        }

        [HttpPost]
        [Route("sell")]
        public async Task<IHttpActionResult> Sell([FromBody] SellTradeRequest request)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var trade = await _tradingService.SellAsync(CurrentUserId, request);
            return CreatedResponse(trade, "Cryptocurrency sale executed successfully.");
        }

        [HttpGet]
        [Route("")]
        public async Task<IHttpActionResult> GetTrades([FromUri] int limit = 100)
        {
            var trades = await _tradingService.GetUserTradesAsync(CurrentUserId, limit);
            return OkResponse(trades);
        }
    }
}

