using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Net;
using System.Net.Http;
using System.Web.Http.Filters;
using CryptoTrading.Infrastructure.Logging;
using CryptoTrading.Models.Requests;

namespace CryptoTrading.Web.Filters
{
    public class ApiExceptionFilterAttribute : ExceptionFilterAttribute
    {
        private static readonly ILoggerService _logger = new Log4NetLoggerService("ApiExceptionFilter");

        public override void OnException(HttpActionExecutedContext actionContext)
        {
            var exception = actionContext.Exception;
            _logger.Error($"Unhandled API exception on {actionContext.Request.RequestUri}: {exception.Message}", exception);

            HttpStatusCode statusCode = HttpStatusCode.InternalServerError;
            string errorCode = "INTERNAL_SERVER_ERROR";
            string message = "An unexpected error occurred. Please try again later.";

            if (exception is UnauthorizedAccessException)
            {
                statusCode = HttpStatusCode.Unauthorized;
                errorCode = "UNAUTHORIZED";
                message = exception.Message;
            }
            else if (exception is KeyNotFoundException)
            {
                statusCode = HttpStatusCode.NotFound;
                errorCode = "NOT_FOUND";
                message = exception.Message;
            }
            else if (exception is ArgumentException || exception is ArgumentNullException)
            {
                statusCode = HttpStatusCode.BadRequest;
                errorCode = "INVALID_ARGUMENT";
                message = exception.Message;
            }
            else if (exception is InvalidOperationException)
            {
                statusCode = HttpStatusCode.BadRequest;
                errorCode = "INVALID_OPERATION";
                message = exception.Message;
            }
            else if (exception is SqlException sqlEx)
            {
                // Business rule errors raised by stored procedures (e.g. RAISERROR / THROW)
                statusCode = HttpStatusCode.BadRequest;
                errorCode = "DATABASE_ERROR";
                message = sqlEx.Message;
            }

            var response = actionContext.Request.CreateResponse(
                statusCode,
                ApiErrorResponse.Fail(message, errorCode)
            );

            actionContext.Response = response;
        }
    }
}

