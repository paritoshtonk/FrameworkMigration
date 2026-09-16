using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Threading.Tasks;
using CryptoTrading.Models.DTOs;

namespace CryptoTrading.Data.Repositories
{
    public interface IOrderRepository
    {
        Task<int> CreateOrderAsync(int userId, string symbol, string orderType, string side, decimal quantity, decimal price, string status = "Pending");
        Task<OrderDto> GetOrderAsync(int orderId, int? userId = null);
        Task<List<OrderDto>> GetOrdersByUserAsync(int userId, int limit = 100);
        Task<List<OrderDto>> GetOpenOrdersAsync(int userId);
        Task<List<OrderDto>> GetCompletedOrdersAsync(int userId, int limit = 100);
        Task UpdateOrderStatusAsync(int orderId, string status, DateTime? executedDate = null);
        Task<OrderDto> CancelOrderAsync(int orderId, int userId);
    }

    public class OrderRepository : IOrderRepository
    {
        private readonly IDbConnectionFactory _connectionFactory;

        public OrderRepository(IDbConnectionFactory connectionFactory)
        {
            _connectionFactory = connectionFactory;
        }

        public async Task<int> CreateOrderAsync(int userId, string symbol, string orderType, string side, decimal quantity, decimal price, string status = "Pending")
        {
            using (var conn = (SqlConnection)_connectionFactory.CreateConnection())
            using (var cmd = new SqlCommand("usp_CreateOrder", conn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@UserId", userId);
                cmd.Parameters.AddWithValue("@Symbol", symbol);
                cmd.Parameters.AddWithValue("@OrderType", orderType);
                cmd.Parameters.AddWithValue("@Side", side);
                cmd.Parameters.AddWithValue("@Quantity", quantity);
                cmd.Parameters.AddWithValue("@Price", price);
                cmd.Parameters.AddWithValue("@Status", status);

                var outParam = new SqlParameter("@OrderId", SqlDbType.Int)
                {
                    Direction = ParameterDirection.Output
                };
                cmd.Parameters.Add(outParam);

                await cmd.ExecuteNonQueryAsync();
                return (int)outParam.Value;
            }
        }

        public async Task<OrderDto> GetOrderAsync(int orderId, int? userId = null)
        {
            using (var conn = (SqlConnection)_connectionFactory.CreateConnection())
            using (var cmd = new SqlCommand("usp_GetOrder", conn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@OrderId", orderId);
                cmd.Parameters.AddWithValue("@UserId", (object)userId ?? DBNull.Value);

                using (var reader = await cmd.ExecuteReaderAsync())
                {
                    if (await reader.ReadAsync())
                    {
                        return MapOrder(reader);
                    }
                }
            }
            return null;
        }

        public async Task<List<OrderDto>> GetOrdersByUserAsync(int userId, int limit = 100)
        {
            var list = new List<OrderDto>();
            using (var conn = (SqlConnection)_connectionFactory.CreateConnection())
            using (var cmd = new SqlCommand("usp_GetOrdersByUser", conn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@UserId", userId);
                cmd.Parameters.AddWithValue("@Limit", limit);

                using (var reader = await cmd.ExecuteReaderAsync())
                {
                    while (await reader.ReadAsync())
                    {
                        list.Add(MapOrder(reader));
                    }
                }
            }
            return list;
        }

        public async Task<List<OrderDto>> GetOpenOrdersAsync(int userId)
        {
            var list = new List<OrderDto>();
            using (var conn = (SqlConnection)_connectionFactory.CreateConnection())
            using (var cmd = new SqlCommand("usp_GetOpenOrders", conn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@UserId", userId);

                using (var reader = await cmd.ExecuteReaderAsync())
                {
                    while (await reader.ReadAsync())
                    {
                        list.Add(MapOrder(reader));
                    }
                }
            }
            return list;
        }

        public async Task<List<OrderDto>> GetCompletedOrdersAsync(int userId, int limit = 100)
        {
            var list = new List<OrderDto>();
            using (var conn = (SqlConnection)_connectionFactory.CreateConnection())
            using (var cmd = new SqlCommand("usp_GetCompletedOrders", conn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@UserId", userId);
                cmd.Parameters.AddWithValue("@Limit", limit);

                using (var reader = await cmd.ExecuteReaderAsync())
                {
                    while (await reader.ReadAsync())
                    {
                        list.Add(MapOrder(reader));
                    }
                }
            }
            return list;
        }

        public async Task UpdateOrderStatusAsync(int orderId, string status, DateTime? executedDate = null)
        {
            using (var conn = (SqlConnection)_connectionFactory.CreateConnection())
            using (var cmd = new SqlCommand("usp_UpdateOrderStatus", conn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@OrderId", orderId);
                cmd.Parameters.AddWithValue("@Status", status);
                cmd.Parameters.AddWithValue("@ExecutedDate", (object)executedDate ?? DBNull.Value);

                await cmd.ExecuteNonQueryAsync();
            }
        }

        public async Task<OrderDto> CancelOrderAsync(int orderId, int userId)
        {
            using (var conn = (SqlConnection)_connectionFactory.CreateConnection())
            using (var cmd = new SqlCommand("usp_CancelOrder", conn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@OrderId", orderId);
                cmd.Parameters.AddWithValue("@UserId", userId);

                using (var reader = await cmd.ExecuteReaderAsync())
                {
                    if (await reader.ReadAsync())
                    {
                        return MapOrder(reader);
                    }
                }
            }
            return null;
        }

        private static OrderDto MapOrder(SqlDataReader reader)
        {
            return new OrderDto
            {
                OrderId = reader.GetInt32(reader.GetOrdinal("OrderId")),
                UserId = reader.GetInt32(reader.GetOrdinal("UserId")),
                Symbol = reader.GetString(reader.GetOrdinal("Symbol")),
                OrderType = reader.GetString(reader.GetOrdinal("OrderType")),
                Side = reader.GetString(reader.GetOrdinal("Side")),
                Quantity = reader.GetDecimal(reader.GetOrdinal("Quantity")),
                Price = reader.GetDecimal(reader.GetOrdinal("Price")),
                TotalValue = reader.GetDecimal(reader.GetOrdinal("TotalValue")),
                Status = reader.GetString(reader.GetOrdinal("Status")),
                CreatedDate = reader.GetDateTime(reader.GetOrdinal("CreatedDate")),
                ExecutedDate = reader.IsDBNull(reader.GetOrdinal("ExecutedDate")) ? (DateTime?)null : reader.GetDateTime(reader.GetOrdinal("ExecutedDate"))
            };
        }
    }
}

