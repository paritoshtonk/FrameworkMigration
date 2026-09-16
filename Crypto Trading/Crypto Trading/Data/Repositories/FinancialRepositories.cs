using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Threading.Tasks;
using CryptoTrading.Models.DTOs;

namespace CryptoTrading.Data.Repositories
{
    public interface ITransactionRepository
    {
        Task<int> CreateTransactionAsync(int userId, string transactionType, string currency, decimal amount, string referenceId = null, string status = "COMPLETED");
        Task<List<TransactionDto>> GetTransactionsByUserAsync(int userId, int limit = 100);
        Task<TransactionDto> GetTransactionByIdAsync(int transactionId, int? userId = null);
    }

    public class TransactionRepository : ITransactionRepository
    {
        private readonly IDbConnectionFactory _connectionFactory;

        public TransactionRepository(IDbConnectionFactory connectionFactory)
        {
            _connectionFactory = connectionFactory;
        }

        public async Task<int> CreateTransactionAsync(int userId, string transactionType, string currency, decimal amount, string referenceId = null, string status = "COMPLETED")
        {
            using (var conn = (SqlConnection)_connectionFactory.CreateConnection())
            using (var cmd = new SqlCommand("usp_CreateTransaction", conn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@UserId", userId);
                cmd.Parameters.AddWithValue("@TransactionType", transactionType);
                cmd.Parameters.AddWithValue("@Currency", currency);
                cmd.Parameters.AddWithValue("@Amount", amount);
                cmd.Parameters.AddWithValue("@ReferenceId", (object)referenceId ?? DBNull.Value);
                cmd.Parameters.AddWithValue("@Status", status);

                var outParam = new SqlParameter("@TransactionId", SqlDbType.Int)
                {
                    Direction = ParameterDirection.Output
                };
                cmd.Parameters.Add(outParam);

                await cmd.ExecuteNonQueryAsync();
                return (int)outParam.Value;
            }
        }

        public async Task<List<TransactionDto>> GetTransactionsByUserAsync(int userId, int limit = 100)
        {
            var list = new List<TransactionDto>();
            using (var conn = (SqlConnection)_connectionFactory.CreateConnection())
            using (var cmd = new SqlCommand("usp_GetTransactionsByUser", conn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@UserId", userId);
                cmd.Parameters.AddWithValue("@Limit", limit);

                using (var reader = await cmd.ExecuteReaderAsync())
                {
                    while (await reader.ReadAsync())
                    {
                        list.Add(MapTransaction(reader));
                    }
                }
            }
            return list;
        }

        public async Task<TransactionDto> GetTransactionByIdAsync(int transactionId, int? userId = null)
        {
            using (var conn = (SqlConnection)_connectionFactory.CreateConnection())
            using (var cmd = new SqlCommand("usp_GetTransactionById", conn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@TransactionId", transactionId);
                cmd.Parameters.AddWithValue("@UserId", (object)userId ?? DBNull.Value);

                using (var reader = await cmd.ExecuteReaderAsync())
                {
                    if (await reader.ReadAsync())
                    {
                        return MapTransaction(reader);
                    }
                }
            }
            return null;
        }

        private static TransactionDto MapTransaction(SqlDataReader reader)
        {
            return new TransactionDto
            {
                TransactionId = reader.GetInt32(reader.GetOrdinal("TransactionId")),
                UserId = reader.GetInt32(reader.GetOrdinal("UserId")),
                TransactionType = reader.GetString(reader.GetOrdinal("TransactionType")),
                Currency = reader.GetString(reader.GetOrdinal("Currency")),
                Amount = reader.GetDecimal(reader.GetOrdinal("Amount")),
                ReferenceId = reader.IsDBNull(reader.GetOrdinal("ReferenceId")) ? null : reader.GetString(reader.GetOrdinal("ReferenceId")),
                Status = reader.GetString(reader.GetOrdinal("Status")),
                CreatedDate = reader.GetDateTime(reader.GetOrdinal("CreatedDate"))
            };
        }
    }

    public interface IDepositRepository
    {
        Task<DepositDto> ProcessDepositAsync(int userId, decimal amount, string currency = "USD");
        Task<List<DepositDto>> GetDepositsByUserAsync(int userId, int limit = 100);
    }

    public class DepositRepository : IDepositRepository
    {
        private readonly IDbConnectionFactory _connectionFactory;

        public DepositRepository(IDbConnectionFactory connectionFactory)
        {
            _connectionFactory = connectionFactory;
        }

        public async Task<DepositDto> ProcessDepositAsync(int userId, decimal amount, string currency = "USD")
        {
            using (var conn = (SqlConnection)_connectionFactory.CreateConnection())
            using (var cmd = new SqlCommand("usp_ProcessDeposit", conn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@UserId", userId);
                cmd.Parameters.AddWithValue("@Amount", amount);
                cmd.Parameters.AddWithValue("@Currency", currency);

                var outParam = new SqlParameter("@DepositId", SqlDbType.Int)
                {
                    Direction = ParameterDirection.Output
                };
                cmd.Parameters.Add(outParam);

                using (var reader = await cmd.ExecuteReaderAsync())
                {
                    if (await reader.ReadAsync())
                    {
                        return new DepositDto
                        {
                            DepositId = reader.GetInt32(reader.GetOrdinal("DepositId")),
                            UserId = reader.GetInt32(reader.GetOrdinal("UserId")),
                            Amount = reader.GetDecimal(reader.GetOrdinal("Amount")),
                            Currency = reader.GetString(reader.GetOrdinal("Currency")),
                            Status = reader.GetString(reader.GetOrdinal("Status")),
                            CreatedDate = reader.GetDateTime(reader.GetOrdinal("CreatedDate")),
                            ProcessedDate = reader.GetDateTime(reader.GetOrdinal("ProcessedDate")),
                            NewBalance = reader.GetDecimal(reader.GetOrdinal("NewBalance"))
                        };
                    }
                }
            }
            return null;
        }

        public async Task<List<DepositDto>> GetDepositsByUserAsync(int userId, int limit = 100)
        {
            var list = new List<DepositDto>();
            using (var conn = (SqlConnection)_connectionFactory.CreateConnection())
            using (var cmd = new SqlCommand("usp_GetDepositsByUser", conn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@UserId", userId);
                cmd.Parameters.AddWithValue("@Limit", limit);

                using (var reader = await cmd.ExecuteReaderAsync())
                {
                    while (await reader.ReadAsync())
                    {
                        list.Add(new DepositDto
                        {
                            DepositId = reader.GetInt32(reader.GetOrdinal("DepositId")),
                            UserId = reader.GetInt32(reader.GetOrdinal("UserId")),
                            Amount = reader.GetDecimal(reader.GetOrdinal("Amount")),
                            Currency = reader.GetString(reader.GetOrdinal("Currency")),
                            Status = reader.GetString(reader.GetOrdinal("Status")),
                            CreatedDate = reader.GetDateTime(reader.GetOrdinal("CreatedDate")),
                            ProcessedDate = reader.GetDateTime(reader.GetOrdinal("ProcessedDate"))
                        });
                    }
                }
            }
            return list;
        }
    }

    public interface IWithdrawalRepository
    {
        Task<WithdrawalDto> ProcessWithdrawalAsync(int userId, decimal amount, string currency = "USD");
        Task<List<WithdrawalDto>> GetWithdrawalsByUserAsync(int userId, int limit = 100);
    }

    public class WithdrawalRepository : IWithdrawalRepository
    {
        private readonly IDbConnectionFactory _connectionFactory;

        public WithdrawalRepository(IDbConnectionFactory connectionFactory)
        {
            _connectionFactory = connectionFactory;
        }

        public async Task<WithdrawalDto> ProcessWithdrawalAsync(int userId, decimal amount, string currency = "USD")
        {
            using (var conn = (SqlConnection)_connectionFactory.CreateConnection())
            using (var cmd = new SqlCommand("usp_ProcessWithdrawal", conn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@UserId", userId);
                cmd.Parameters.AddWithValue("@Amount", amount);
                cmd.Parameters.AddWithValue("@Currency", currency);

                var outParam = new SqlParameter("@WithdrawalId", SqlDbType.Int)
                {
                    Direction = ParameterDirection.Output
                };
                cmd.Parameters.Add(outParam);

                using (var reader = await cmd.ExecuteReaderAsync())
                {
                    if (await reader.ReadAsync())
                    {
                        return new WithdrawalDto
                        {
                            WithdrawalId = reader.GetInt32(reader.GetOrdinal("WithdrawalId")),
                            UserId = reader.GetInt32(reader.GetOrdinal("UserId")),
                            Amount = reader.GetDecimal(reader.GetOrdinal("Amount")),
                            Currency = reader.GetString(reader.GetOrdinal("Currency")),
                            Status = reader.GetString(reader.GetOrdinal("Status")),
                            CreatedDate = reader.GetDateTime(reader.GetOrdinal("CreatedDate")),
                            ProcessedDate = reader.GetDateTime(reader.GetOrdinal("ProcessedDate")),
                            RemainingBalance = reader.GetDecimal(reader.GetOrdinal("RemainingBalance")),
                            NewBalance = reader.GetDecimal(reader.GetOrdinal("RemainingBalance"))
                        };
                    }
                }
            }
            return null;
        }

        public async Task<List<WithdrawalDto>> GetWithdrawalsByUserAsync(int userId, int limit = 100)
        {
            var list = new List<WithdrawalDto>();
            using (var conn = (SqlConnection)_connectionFactory.CreateConnection())
            using (var cmd = new SqlCommand("usp_GetWithdrawalsByUser", conn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@UserId", userId);
                cmd.Parameters.AddWithValue("@Limit", limit);

                using (var reader = await cmd.ExecuteReaderAsync())
                {
                    while (await reader.ReadAsync())
                    {
                        list.Add(new WithdrawalDto
                        {
                            WithdrawalId = reader.GetInt32(reader.GetOrdinal("WithdrawalId")),
                            UserId = reader.GetInt32(reader.GetOrdinal("UserId")),
                            Amount = reader.GetDecimal(reader.GetOrdinal("Amount")),
                            Currency = reader.GetString(reader.GetOrdinal("Currency")),
                            Status = reader.GetString(reader.GetOrdinal("Status")),
                            CreatedDate = reader.GetDateTime(reader.GetOrdinal("CreatedDate")),
                            ProcessedDate = reader.GetDateTime(reader.GetOrdinal("ProcessedDate"))
                        });
                    }
                }
            }
            return list;
        }
    }
}

