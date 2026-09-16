using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Threading.Tasks;
using CryptoTrading.Models.DTOs;

namespace CryptoTrading.Data.Repositories
{
    public interface IPortfolioRepository
    {
        Task<PortfolioDto> GetPortfolioAsync(int userId);
        Task<List<HoldingDto>> GetPortfolioHoldingsAsync(int userId);
        Task<PortfolioSummaryDto> GetPortfolioSummaryAsync(int userId);
        Task<PortfolioPerformanceDto> GetPortfolioPerformanceAsync(int userId);
        Task<decimal> GetUnrealizedProfitLossAsync(int userId);
        Task<decimal> GetRealizedProfitLossAsync(int userId);
    }

    public class PortfolioRepository : IPortfolioRepository
    {
        private readonly IDbConnectionFactory _connectionFactory;

        public PortfolioRepository(IDbConnectionFactory connectionFactory)
        {
            _connectionFactory = connectionFactory;
        }

        public async Task<PortfolioDto> GetPortfolioAsync(int userId)
        {
            var portfolio = new PortfolioDto();
            using (var conn = (SqlConnection)_connectionFactory.CreateConnection())
            using (var cmd = new SqlCommand("usp_GetPortfolio", conn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@UserId", userId);

                using (var reader = await cmd.ExecuteReaderAsync())
                {
                    // Result Set 1: Summary
                    if (await reader.ReadAsync())
                    {
                        portfolio.Summary = MapSummary(reader);
                    }

                    // Result Set 2: Holdings
                    if (await reader.NextResultAsync())
                    {
                        while (await reader.ReadAsync())
                        {
                            portfolio.Holdings.Add(MapHolding(reader));
                        }
                    }
                }
            }

            if (portfolio.Summary == null)
            {
                portfolio.Summary = new PortfolioSummaryDto
                {
                    UserId = userId,
                    CashBalance = 0,
                    InvestedValue = 0,
                    HoldingsMarketValue = 0,
                    TotalPortfolioValue = 0,
                    UnrealizedProfitLoss = 0,
                    RealizedProfitLoss = 0,
                    TotalProfitLoss = 0
                };
            }

            return portfolio;
        }

        public async Task<List<HoldingDto>> GetPortfolioHoldingsAsync(int userId)
        {
            var list = new List<HoldingDto>();
            using (var conn = (SqlConnection)_connectionFactory.CreateConnection())
            using (var cmd = new SqlCommand("usp_GetPortfolioHoldings", conn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@UserId", userId);

                using (var reader = await cmd.ExecuteReaderAsync())
                {
                    while (await reader.ReadAsync())
                    {
                        list.Add(MapHolding(reader));
                    }
                }
            }
            return list;
        }

        public async Task<PortfolioSummaryDto> GetPortfolioSummaryAsync(int userId)
        {
            using (var conn = (SqlConnection)_connectionFactory.CreateConnection())
            using (var cmd = new SqlCommand("usp_GetPortfolioSummary", conn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@UserId", userId);

                using (var reader = await cmd.ExecuteReaderAsync())
                {
                    if (await reader.ReadAsync())
                    {
                        return MapSummary(reader);
                    }
                }
            }
            return null;
        }

        public async Task<PortfolioPerformanceDto> GetPortfolioPerformanceAsync(int userId)
        {
            using (var conn = (SqlConnection)_connectionFactory.CreateConnection())
            using (var cmd = new SqlCommand("usp_GetPortfolioPerformance", conn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@UserId", userId);

                using (var reader = await cmd.ExecuteReaderAsync())
                {
                    if (await reader.ReadAsync())
                    {
                        return new PortfolioPerformanceDto
                        {
                            UserId = reader.GetInt32(reader.GetOrdinal("UserId")),
                            Username = reader.GetString(reader.GetOrdinal("Username")),
                            CashBalance = reader.GetDecimal(reader.GetOrdinal("CashBalance")),
                            InvestedValue = reader.GetDecimal(reader.GetOrdinal("InvestedValue")),
                            HoldingsMarketValue = reader.GetDecimal(reader.GetOrdinal("HoldingsMarketValue")),
                            TotalPortfolioValue = reader.GetDecimal(reader.GetOrdinal("TotalPortfolioValue")),
                            UnrealizedProfitLoss = reader.GetDecimal(reader.GetOrdinal("UnrealizedProfitLoss")),
                            RealizedProfitLoss = reader.GetDecimal(reader.GetOrdinal("RealizedProfitLoss")),
                            TotalProfitLoss = reader.GetDecimal(reader.GetOrdinal("TotalProfitLoss")),
                            ReturnPercentage = reader.GetDecimal(reader.GetOrdinal("ReturnPercentage")),
                            TotalDeposited = reader.GetDecimal(reader.GetOrdinal("TotalDeposited")),
                            TotalWithdrawn = reader.GetDecimal(reader.GetOrdinal("TotalWithdrawn")),
                            TotalTradesCount = reader.GetInt32(reader.GetOrdinal("TotalTradesCount"))
                        };
                    }
                }
            }
            return null;
        }

        public async Task<decimal> GetUnrealizedProfitLossAsync(int userId)
        {
            using (var conn = (SqlConnection)_connectionFactory.CreateConnection())
            using (var cmd = new SqlCommand("usp_GetUnrealizedProfitLoss", conn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@UserId", userId);

                using (var reader = await cmd.ExecuteReaderAsync())
                {
                    if (await reader.ReadAsync())
                    {
                        return reader.GetDecimal(reader.GetOrdinal("TotalUnrealizedProfitLoss"));
                    }
                }
            }
            return 0.00m;
        }

        public async Task<decimal> GetRealizedProfitLossAsync(int userId)
        {
            using (var conn = (SqlConnection)_connectionFactory.CreateConnection())
            using (var cmd = new SqlCommand("usp_GetRealizedProfitLoss", conn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@UserId", userId);

                using (var reader = await cmd.ExecuteReaderAsync())
                {
                    if (await reader.ReadAsync())
                    {
                        return reader.GetDecimal(reader.GetOrdinal("TotalRealizedProfitLoss"));
                    }
                }
            }
            return 0.00m;
        }

        private static PortfolioSummaryDto MapSummary(SqlDataReader reader)
        {
            return new PortfolioSummaryDto
            {
                UserId = reader.GetInt32(reader.GetOrdinal("UserId")),
                Username = reader.GetString(reader.GetOrdinal("Username")),
                CashBalance = reader.GetDecimal(reader.GetOrdinal("CashBalance")),
                InvestedValue = reader.GetDecimal(reader.GetOrdinal("InvestedValue")),
                HoldingsMarketValue = reader.GetDecimal(reader.GetOrdinal("HoldingsMarketValue")),
                TotalPortfolioValue = reader.GetDecimal(reader.GetOrdinal("TotalPortfolioValue")),
                UnrealizedProfitLoss = reader.GetDecimal(reader.GetOrdinal("UnrealizedProfitLoss")),
                RealizedProfitLoss = reader.GetDecimal(reader.GetOrdinal("RealizedProfitLoss")),
                TotalProfitLoss = reader.GetDecimal(reader.GetOrdinal("TotalProfitLoss"))
            };
        }

        private static HoldingDto MapHolding(SqlDataReader reader)
        {
            return new HoldingDto
            {
                WalletId = reader.GetInt32(reader.GetOrdinal("WalletId")),
                UserId = reader.GetInt32(reader.GetOrdinal("UserId")),
                Symbol = reader.GetString(reader.GetOrdinal("Symbol")),
                Name = reader.IsDBNull(reader.GetOrdinal("Name")) ? null : reader.GetString(reader.GetOrdinal("Name")),
                Quantity = reader.GetDecimal(reader.GetOrdinal("Quantity")),
                AverageCost = reader.GetDecimal(reader.GetOrdinal("AverageCost")),
                CurrentPrice = reader.GetDecimal(reader.GetOrdinal("CurrentPrice")),
                CurrentValue = reader.GetDecimal(reader.GetOrdinal("CurrentValue")),
                TotalCost = reader.GetDecimal(reader.GetOrdinal("TotalCost")),
                UnrealizedProfitLoss = reader.GetDecimal(reader.GetOrdinal("UnrealizedProfitLoss")),
                UnrealizedProfitLossPercentage = reader.GetDecimal(reader.GetOrdinal("UnrealizedProfitLossPercentage")),
                UpdatedDate = reader.GetDateTime(reader.GetOrdinal("UpdatedDate"))
            };
        }
    }
}

