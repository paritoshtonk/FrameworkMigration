using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Threading.Tasks;
using CryptoTrading.Models.DTOs;

namespace CryptoTrading.Data.Repositories
{
    public interface ITradingRepository
    {
        Task<TradeDto> ExecuteBuyOrderAsync(int userId, string symbol, decimal quantity, decimal executionPrice);
        Task<TradeDto> ExecuteSellOrderAsync(int userId, string symbol, decimal quantity, decimal executionPrice);
        Task<List<TradeDto>> GetTradesByUserAsync(int userId, int limit = 100);
    }

    public class TradingRepository : ITradingRepository
    {
        private readonly IDbConnectionFactory _connectionFactory;

        public TradingRepository(IDbConnectionFactory connectionFactory)
        {
            _connectionFactory = connectionFactory;
        }

        public async Task<TradeDto> ExecuteBuyOrderAsync(int userId, string symbol, decimal quantity, decimal executionPrice)
        {
            using (var conn = (SqlConnection)_connectionFactory.CreateConnection())
            using (var cmd = new SqlCommand("usp_ExecuteBuyOrder", conn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@UserId", userId);
                cmd.Parameters.AddWithValue("@Symbol", symbol);
                cmd.Parameters.AddWithValue("@Quantity", quantity);
                cmd.Parameters.AddWithValue("@ExecutionPrice", executionPrice);

                var outParam = new SqlParameter("@TradeId", SqlDbType.Int)
                {
                    Direction = ParameterDirection.Output
                };
                cmd.Parameters.Add(outParam);

                using (var reader = await cmd.ExecuteReaderAsync())
                {
                    if (await reader.ReadAsync())
                    {
                        return new TradeDto
                        {
                            TradeId = reader.GetInt32(reader.GetOrdinal("TradeId")),
                            OrderId = reader.GetInt32(reader.GetOrdinal("OrderId")),
                            UserId = reader.GetInt32(reader.GetOrdinal("UserId")),
                            Symbol = reader.GetString(reader.GetOrdinal("Symbol")),
                            Side = reader.GetString(reader.GetOrdinal("Side")),
                            Quantity = reader.GetDecimal(reader.GetOrdinal("Quantity")),
                            ExecutionPrice = reader.GetDecimal(reader.GetOrdinal("ExecutionPrice")),
                            TotalValue = reader.GetDecimal(reader.GetOrdinal("TotalValue")),
                            RealizedProfitLoss = reader.GetDecimal(reader.GetOrdinal("RealizedProfitLoss")),
                            ExecutedDate = reader.GetDateTime(reader.GetOrdinal("ExecutedDate")),
                            RemainingBalance = reader.GetDecimal(reader.GetOrdinal("RemainingBalance"))
                        };
                    }
                }
            }
            return null;
        }

        public async Task<TradeDto> ExecuteSellOrderAsync(int userId, string symbol, decimal quantity, decimal executionPrice)
        {
            using (var conn = (SqlConnection)_connectionFactory.CreateConnection())
            using (var cmd = new SqlCommand("usp_ExecuteSellOrder", conn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@UserId", userId);
                cmd.Parameters.AddWithValue("@Symbol", symbol);
                cmd.Parameters.AddWithValue("@Quantity", quantity);
                cmd.Parameters.AddWithValue("@ExecutionPrice", executionPrice);

                var outParam = new SqlParameter("@TradeId", SqlDbType.Int)
                {
                    Direction = ParameterDirection.Output
                };
                cmd.Parameters.Add(outParam);

                using (var reader = await cmd.ExecuteReaderAsync())
                {
                    if (await reader.ReadAsync())
                    {
                        return new TradeDto
                        {
                            TradeId = reader.GetInt32(reader.GetOrdinal("TradeId")),
                            OrderId = reader.GetInt32(reader.GetOrdinal("OrderId")),
                            UserId = reader.GetInt32(reader.GetOrdinal("UserId")),
                            Symbol = reader.GetString(reader.GetOrdinal("Symbol")),
                            Side = reader.GetString(reader.GetOrdinal("Side")),
                            Quantity = reader.GetDecimal(reader.GetOrdinal("Quantity")),
                            ExecutionPrice = reader.GetDecimal(reader.GetOrdinal("ExecutionPrice")),
                            TotalValue = reader.GetDecimal(reader.GetOrdinal("TotalValue")),
                            RealizedProfitLoss = reader.GetDecimal(reader.GetOrdinal("RealizedProfitLoss")),
                            ExecutedDate = reader.GetDateTime(reader.GetOrdinal("ExecutedDate")),
                            RemainingBalance = reader.GetDecimal(reader.GetOrdinal("RemainingBalance")),
                            RemainingCryptoHolding = reader.GetDecimal(reader.GetOrdinal("RemainingCryptoHolding"))
                        };
                    }
                }
            }
            return null;
        }

        public async Task<List<TradeDto>> GetTradesByUserAsync(int userId, int limit = 100)
        {
            var list = new List<TradeDto>();
            using (var conn = (SqlConnection)_connectionFactory.CreateConnection())
            using (var cmd = new SqlCommand("usp_GetTradesByUser", conn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@UserId", userId);
                cmd.Parameters.AddWithValue("@Limit", limit);

                using (var reader = await cmd.ExecuteReaderAsync())
                {
                    while (await reader.ReadAsync())
                    {
                        list.Add(new TradeDto
                        {
                            TradeId = reader.GetInt32(reader.GetOrdinal("TradeId")),
                            OrderId = reader.GetInt32(reader.GetOrdinal("OrderId")),
                            UserId = reader.GetInt32(reader.GetOrdinal("UserId")),
                            Symbol = reader.GetString(reader.GetOrdinal("Symbol")),
                            Side = reader.GetString(reader.GetOrdinal("Side")),
                            Quantity = reader.GetDecimal(reader.GetOrdinal("Quantity")),
                            ExecutionPrice = reader.GetDecimal(reader.GetOrdinal("ExecutionPrice")),
                            TotalValue = reader.GetDecimal(reader.GetOrdinal("TotalValue")),
                            RealizedProfitLoss = reader.GetDecimal(reader.GetOrdinal("RealizedProfitLoss")),
                            ExecutedDate = reader.GetDateTime(reader.GetOrdinal("ExecutedDate"))
                        });
                    }
                }
            }
            return list;
        }
    }
}

