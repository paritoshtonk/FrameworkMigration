using System.Threading.Tasks;
using System.Web.Http;
using CryptoTrading.Business.Services;

namespace CryptoTrading.Web.Controllers
{
    [RoutePrefix("api/cryptocurrencies")]
    public class CryptocurrenciesController : BaseApiController
    {
        private readonly ICryptoService _cryptoService;

        public CryptocurrenciesController() : this(DependencyConfig.CryptoService)
        {
        }

        public CryptocurrenciesController(ICryptoService cryptoService)
        {
            _cryptoService = cryptoService;
        }

        [HttpGet]
        [Route("")]
        [AllowAnonymous]
        public async Task<IHttpActionResult> GetAll([FromUri] bool force = false)
        {
            var cryptos = await _cryptoService.GetCryptocurrenciesAsync(force);
            return NoCacheOkResponse(cryptos);
        }

        [HttpGet]
        [Route("{symbol}")]
        [AllowAnonymous]
        public async Task<IHttpActionResult> GetBySymbol(string symbol)
        {
            var crypto = await _cryptoService.GetCryptocurrencyBySymbolAsync(symbol);
            if (crypto == null)
                return NotFound();

            return NoCacheOkResponse(crypto);
        }

        [HttpGet]
        [Route("{symbol}/history")]
        [AllowAnonymous]
        public async Task<IHttpActionResult> GetPriceHistory(string symbol, [FromUri] int limit = 100)
        {
            var history = await _cryptoService.GetPriceHistoryAsync(symbol, limit);
            return OkResponse(history);
        }

        [HttpGet]
        [Route("{symbol}/chart")]
        [AllowAnonymous]
        public async Task<IHttpActionResult> GetChart(string symbol, [FromUri] string timeframe = "24h")
        {
            var chart = await _cryptoService.GetMarketChartAsync(symbol, timeframe);
            return NoCacheOkResponse(chart);
        }
    }
}

