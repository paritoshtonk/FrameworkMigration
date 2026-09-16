using System;
using System.Data;
using System.Data.SqlClient;
using System.Threading.Tasks;
using CryptoTrading.Models.Entities;

namespace CryptoTrading.Data.Repositories
{
    public interface IAccountRepository
    {
        Task<int> CreateAccountAsync(int userId, string currency = "USD", decimal initialBalance = 0.00m);
        Task<Account> GetAccountAsync(int userId, string currency = "USD");
        Task<decimal> GetAccountBalanceAsync(int userId, string currency = "USD");
    }

    public class AccountRepository : IAccountRepository
    {
        private readonly IDbConnectionFactory _connectionFactory;

        public AccountRepository(IDbConnectionFactory connectionFactory)
        {
            _connectionFactory = connectionFactory;
        }

        public async Task<int> CreateAccountAsync(int userId, string currency = "USD", decimal initialBalance = 0.00m)
        {
            using (var conn = (SqlConnection)_connectionFactory.CreateConnection())
            using (var cmd = new SqlCommand("usp_CreateAccount", conn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@UserId", userId);
                cmd.Parameters.AddWithValue("@Currency", currency);
                cmd.Parameters.AddWithValue("@InitialBalance", initialBalance);

                var outParam = new SqlParameter("@AccountId", SqlDbType.Int)
                {
                    Direction = ParameterDirection.Output
                };
                cmd.Parameters.Add(outParam);

                await cmd.ExecuteNonQueryAsync();
                return (int)outParam.Value;
            }
        }

        public async Task<Account> GetAccountAsync(int userId, string currency = "USD")
        {
            using (var conn = (SqlConnection)_connectionFactory.CreateConnection())
            using (var cmd = new SqlCommand("usp_GetAccount", conn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@UserId", userId);
                cmd.Parameters.AddWithValue("@Currency", currency);

                using (var reader = await cmd.ExecuteReaderAsync())
                {
                    if (await reader.ReadAsync())
                    {
                        return new Account
                        {
                            AccountId = reader.GetInt32(reader.GetOrdinal("AccountId")),
                            UserId = reader.GetInt32(reader.GetOrdinal("UserId")),
                            Currency = reader.GetString(reader.GetOrdinal("Currency")),
                            AvailableBalance = reader.GetDecimal(reader.GetOrdinal("AvailableBalance")),
                            CreatedDate = reader.GetDateTime(reader.GetOrdinal("CreatedDate")),
                            UpdatedDate = reader.GetDateTime(reader.GetOrdinal("UpdatedDate"))
                        };
                    }
                }
            }
            return null;
        }

        public async Task<decimal> GetAccountBalanceAsync(int userId, string currency = "USD")
        {
            using (var conn = (SqlConnection)_connectionFactory.CreateConnection())
            using (var cmd = new SqlCommand("usp_GetAccountBalance", conn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@UserId", userId);
                cmd.Parameters.AddWithValue("@Currency", currency);

                using (var reader = await cmd.ExecuteReaderAsync())
                {
                    if (await reader.ReadAsync())
                    {
                        return reader.GetDecimal(reader.GetOrdinal("AvailableBalance"));
                    }
                }
            }
            return 0.00m;
        }
    }
}

