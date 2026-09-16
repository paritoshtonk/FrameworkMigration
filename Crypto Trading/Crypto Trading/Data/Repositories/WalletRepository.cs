using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Threading.Tasks;
using CryptoTrading.Models.Entities;

namespace CryptoTrading.Data.Repositories
{
    public interface IWalletRepository
    {
        Task<List<Wallet>> GetWalletsAsync(int userId);
        Task<Wallet> GetWalletHoldingAsync(int userId, string currency);
        Task<int> CreateWalletAsync(int userId, string currency, decimal initialQuantity = 0, decimal averageCost = 0);
        Task UpdateWalletHoldingAsync(int userId, string currency, decimal quantity, decimal averageCost);
    }

    public class WalletRepository : IWalletRepository
    {
        private readonly IDbConnectionFactory _connectionFactory;

        public WalletRepository(IDbConnectionFactory connectionFactory)
        {
            _connectionFactory = connectionFactory;
        }

        public async Task<List<Wallet>> GetWalletsAsync(int userId)
        {
            var list = new List<Wallet>();
            using (var conn = (SqlConnection)_connectionFactory.CreateConnection())
            using (var cmd = new SqlCommand("usp_GetWallets", conn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@UserId", userId);

                using (var reader = await cmd.ExecuteReaderAsync())
                {
                    while (await reader.ReadAsync())
                    {
                        list.Add(MapWallet(reader));
                    }
                }
            }
            return list;
        }

        public async Task<Wallet> GetWalletHoldingAsync(int userId, string currency)
        {
            using (var conn = (SqlConnection)_connectionFactory.CreateConnection())
            using (var cmd = new SqlCommand("usp_GetWalletHolding", conn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@UserId", userId);
                cmd.Parameters.AddWithValue("@Currency", currency);

                using (var reader = await cmd.ExecuteReaderAsync())
                {
                    if (await reader.ReadAsync())
                    {
                        return MapWallet(reader);
                    }
                }
            }
            return null;
        }

        public async Task<int> CreateWalletAsync(int userId, string currency, decimal initialQuantity = 0, decimal averageCost = 0)
        {
            using (var conn = (SqlConnection)_connectionFactory.CreateConnection())
            using (var cmd = new SqlCommand("usp_CreateWallet", conn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@UserId", userId);
                cmd.Parameters.AddWithValue("@Currency", currency);
                cmd.Parameters.AddWithValue("@InitialQuantity", initialQuantity);
                cmd.Parameters.AddWithValue("@AverageCost", averageCost);

                var outParam = new SqlParameter("@WalletId", SqlDbType.Int)
                {
                    Direction = ParameterDirection.Output
                };
                cmd.Parameters.Add(outParam);

                await cmd.ExecuteNonQueryAsync();
                return (int)outParam.Value;
            }
        }

        public async Task UpdateWalletHoldingAsync(int userId, string currency, decimal quantity, decimal averageCost)
        {
            using (var conn = (SqlConnection)_connectionFactory.CreateConnection())
            using (var cmd = new SqlCommand("usp_UpdateWalletHolding", conn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@UserId", userId);
                cmd.Parameters.AddWithValue("@Currency", currency);
                cmd.Parameters.AddWithValue("@Quantity", quantity);
                cmd.Parameters.AddWithValue("@AverageCost", averageCost);

                await cmd.ExecuteNonQueryAsync();
            }
        }

        private static Wallet MapWallet(SqlDataReader reader)
        {
            return new Wallet
            {
                WalletId = reader.GetInt32(reader.GetOrdinal("WalletId")),
                UserId = reader.GetInt32(reader.GetOrdinal("UserId")),
                Currency = reader.GetString(reader.GetOrdinal("Currency")),
                CurrencyName = reader.IsDBNull(reader.GetOrdinal("CurrencyName")) ? null : reader.GetString(reader.GetOrdinal("CurrencyName")),
                Quantity = reader.GetDecimal(reader.GetOrdinal("Quantity")),
                AverageCost = reader.GetDecimal(reader.GetOrdinal("AverageCost")),
                CreatedDate = reader.GetDateTime(reader.GetOrdinal("CreatedDate")),
                UpdatedDate = reader.GetDateTime(reader.GetOrdinal("UpdatedDate"))
            };
        }
    }
}

