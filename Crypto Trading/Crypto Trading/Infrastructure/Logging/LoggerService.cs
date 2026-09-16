using System;
using log4net;

namespace CryptoTrading.Infrastructure.Logging
{
    public interface ILoggerService
    {
        void Debug(string message);
        void Info(string message);
        void Warn(string message);
        void Error(string message, Exception ex = null);
        void Fatal(string message, Exception ex = null);
    }

    public class Log4NetLoggerService : ILoggerService
    {
        private readonly ILog _log;

        public Log4NetLoggerService(string loggerName = "CryptoTradingLogger")
        {
            _log = LogManager.GetLogger(loggerName);
        }

        public void Debug(string message)
        {
            if (_log.IsDebugEnabled)
                _log.Debug(message);
        }

        public void Info(string message)
        {
            if (_log.IsInfoEnabled)
                _log.Info(message);
        }

        public void Warn(string message)
        {
            if (_log.IsWarnEnabled)
                _log.Warn(message);
        }

        public void Error(string message, Exception ex = null)
        {
            if (ex != null)
                _log.Error(message, ex);
            else
                _log.Error(message);
        }

        public void Fatal(string message, Exception ex = null)
        {
            if (ex != null)
                _log.Fatal(message, ex);
            else
                _log.Fatal(message);
        }
    }
}

