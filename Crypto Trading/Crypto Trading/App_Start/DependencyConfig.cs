using System;
using CryptoTrading.Business.Services;
using CryptoTrading.Data;
using CryptoTrading.Data.Repositories;
using CryptoTrading.Infrastructure.Logging;
using CryptoTrading.Infrastructure.PubSub;
using CryptoTrading.Infrastructure.MarketData;
using CryptoTrading.Infrastructure.Reports;
using CryptoTrading.Infrastructure.Security;

namespace CryptoTrading.Web
{
    public static class DependencyConfig
    {
        private static readonly Lazy<IDbConnectionFactory> _dbFactory = 
            new Lazy<IDbConnectionFactory>(() => new SqlConnectionFactory());

        private static readonly Lazy<ILoggerService> _logger = 
            new Lazy<ILoggerService>(() => new Log4NetLoggerService());

        private static readonly Lazy<IPasswordHasher> _passwordHasher = 
            new Lazy<IPasswordHasher>(() => new Pbkdf2PasswordHasher());

        private static readonly Lazy<ITokenService> _tokenService = 
            new Lazy<ITokenService>(() => new JwtTokenService());

        // Google Cloud Pub/Sub Messaging & Event Streaming
        private static readonly Lazy<PubSubConfig> _pubSubConfig =
            new Lazy<PubSubConfig>(() => PubSubConfig.FromConfiguration());

        private static readonly Lazy<IPubSubPublisher> _pubSubPublisher =
            new Lazy<IPubSubPublisher>(() => new PubSubPublisher(_pubSubConfig.Value, _logger.Value));

        private static readonly Lazy<IPubSubSubscriber> _pubSubSubscriber =
            new Lazy<IPubSubSubscriber>(() => new PubSubSubscriber(_pubSubConfig.Value, _logger.Value));

        private static readonly Lazy<IOrderExecutionProcessor> _orderExecutionProcessor =
            new Lazy<IOrderExecutionProcessor>(() => new OrderExecutionProcessor(
                () => _tradingService.Value,
                _pubSubPublisher.Value,
                _pubSubConfig.Value,
                _logger.Value));

        private static readonly Lazy<PubSubManager> _pubSubManager =
            new Lazy<PubSubManager>(() => new PubSubManager(
                _pubSubConfig.Value, 
                _logger.Value, 
                () => _tradingService.Value, 
                _orderExecutionProcessor.Value));

        // Repositories
        private static readonly Lazy<IUserRepository> _userRepo = 
            new Lazy<IUserRepository>(() => new UserRepository(_dbFactory.Value));

        private static readonly Lazy<IAccountRepository> _accountRepo = 
            new Lazy<IAccountRepository>(() => new AccountRepository(_dbFactory.Value));

        private static readonly Lazy<ICryptocurrencyRepository> _cryptoRepo = 
            new Lazy<ICryptocurrencyRepository>(() => new CryptocurrencyRepository(_dbFactory.Value));

        private static readonly Lazy<IWalletRepository> _walletRepo = 
            new Lazy<IWalletRepository>(() => new WalletRepository(_dbFactory.Value));

        private static readonly Lazy<IPortfolioRepository> _portfolioRepo = 
            new Lazy<IPortfolioRepository>(() => new PortfolioRepository(_dbFactory.Value));

        private static readonly Lazy<IOrderRepository> _orderRepo = 
            new Lazy<IOrderRepository>(() => new OrderRepository(_dbFactory.Value));

        private static readonly Lazy<ITradingRepository> _tradingRepo = 
            new Lazy<ITradingRepository>(() => new TradingRepository(_dbFactory.Value));

        private static readonly Lazy<ITransactionRepository> _txRepo = 
            new Lazy<ITransactionRepository>(() => new TransactionRepository(_dbFactory.Value));

        private static readonly Lazy<IDepositRepository> _depositRepo = 
            new Lazy<IDepositRepository>(() => new DepositRepository(_dbFactory.Value));

        private static readonly Lazy<IWithdrawalRepository> _withdrawalRepo = 
            new Lazy<IWithdrawalRepository>(() => new WithdrawalRepository(_dbFactory.Value));

        // Market Data (with Google Cloud Pub/Sub price streaming)
        private static readonly Lazy<ICryptoMarketService> _marketService = 
            new Lazy<ICryptoMarketService>(() => new CoinGeckoMarketService(_cryptoRepo.Value, _logger.Value, _pubSubPublisher.Value));

        // Business Services
        private static readonly Lazy<IAuthService> _authService = 
            new Lazy<IAuthService>(() => new AuthService(_userRepo.Value, _accountRepo.Value, _passwordHasher.Value, _tokenService.Value, _logger.Value));

        private static readonly Lazy<ICryptoService> _cryptoService = 
            new Lazy<ICryptoService>(() => new CryptoService(_marketService.Value, _cryptoRepo.Value));

        private static readonly Lazy<ITradingService> _tradingService = 
            new Lazy<ITradingService>(() => new TradingService(_tradingRepo.Value, _marketService.Value, _logger.Value, _walletRepo.Value));

        private static readonly Lazy<IPortfolioService> _portfolioService = 
            new Lazy<IPortfolioService>(() => new PortfolioService(_portfolioRepo.Value));

        private static readonly Lazy<IPdfReportService> _pdfReportService = 
            new Lazy<IPdfReportService>(() => new PdfReportService(_userRepo.Value, _portfolioRepo.Value, _tradingRepo.Value, _txRepo.Value, _logger.Value));

        private static readonly Lazy<IOrderService> _orderService = 
            new Lazy<IOrderService>(() => new OrderService(_orderRepo.Value, _logger.Value));

        private static readonly Lazy<IFinancialService> _financialService = 
            new Lazy<IFinancialService>(() => new FinancialService(_depositRepo.Value, _withdrawalRepo.Value, _txRepo.Value, _logger.Value));

        private static readonly Lazy<IUserService> _userService = 
            new Lazy<IUserService>(() => new UserService(_userRepo.Value, _accountRepo.Value));

        // Properties
        public static IDbConnectionFactory DbConnectionFactory => _dbFactory.Value;
        public static ILoggerService Logger => _logger.Value;
        public static IPasswordHasher PasswordHasher => _passwordHasher.Value;
        public static ITokenService TokenService => _tokenService.Value;
        public static IUserRepository UserRepository => _userRepo.Value;
        public static IAccountRepository AccountRepository => _accountRepo.Value;
        public static ICryptocurrencyRepository CryptocurrencyRepository => _cryptoRepo.Value;
        public static IWalletRepository WalletRepository => _walletRepo.Value;
        public static IPortfolioRepository PortfolioRepository => _portfolioRepo.Value;
        public static IOrderRepository OrderRepository => _orderRepo.Value;
        public static ITradingRepository TradingRepository => _tradingRepo.Value;
        public static ITransactionRepository TransactionRepository => _txRepo.Value;
        public static IDepositRepository DepositRepository => _depositRepo.Value;
        public static IWithdrawalRepository WithdrawalRepository => _withdrawalRepo.Value;
        public static ICryptoMarketService CryptoMarketService => _marketService.Value;

        // Google Cloud Pub/Sub Properties
        public static PubSubConfig PubSubConfig => _pubSubConfig.Value;
        public static IPubSubPublisher PubSubPublisher => _pubSubPublisher.Value;
        public static IPubSubSubscriber PubSubSubscriber => _pubSubSubscriber.Value;
        public static IOrderExecutionProcessor OrderExecutionProcessor => _orderExecutionProcessor.Value;
        public static PubSubManager PubSubManager => _pubSubManager.Value;

        public static IAuthService AuthService => _authService.Value;
        public static ICryptoService CryptoService => _cryptoService.Value;
        public static ITradingService TradingService => _tradingService.Value;
        public static IPortfolioService PortfolioService => _portfolioService.Value;
        public static IPdfReportService PdfReportService => _pdfReportService.Value;
        public static IOrderService OrderService => _orderService.Value;
        public static IFinancialService FinancialService => _financialService.Value;
        public static IUserService UserService => _userService.Value;
    }
}

