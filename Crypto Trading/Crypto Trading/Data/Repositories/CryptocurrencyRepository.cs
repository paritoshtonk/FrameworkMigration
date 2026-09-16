using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Threading.Tasks;
using CryptoTrading.Models.Entities;

namespace CryptoTrading.Data.Repositories
{
    public interface ICryptocurrencyRepository
    {
        Task<List<Cryptocurrency>> GetCryptocurrenciesAsync();
        Task<Cryptocurrency> GetCryptocurrencyBySymbolAsync(string symbol);
        Task SaveCryptoPriceAsync(string symbol, decimal price, decimal priceChange24h);
        Task<Cryptocurrency> GetLatestCryptoPriceAsync(string symbol);
        Task<List<PriceHistory>> GetCryptoPriceHistoryAsync(string symbol, int limit = 100);
    }

    public class CryptocurrencyRepository : ICryptocurrencyRepository
    {
        private readonly IDbConnectionFactory _connectionFactory;

        public CryptocurrencyRepository(IDbConnectionFactory connectionFactory)
        {
            _connectionFactory = connectionFactory;
        }

        public async Task<List<Cryptocurrency>> GetCryptocurrenciesAsync()
        {
            var list = new List<Cryptocurrency>();
            using (var conn = (SqlConnection)_connectionFactory.CreateConnection())
            using (var cmd = new SqlCommand("usp_GetCryptocurrencies", conn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                using (var reader = await cmd.ExecuteReaderAsync())
                {
                    while (await reader.ReadAsync())
                    {
                        list.Add(MapCrypto(reader));
                    }
                }
            }
            return list;
        }

        public async Task<Cryptocurrency> GetCryptocurrencyBySymbolAsync(string symbol)
        {
            using (var conn = (SqlConnection)_connectionFactory.CreateConnection())
            using (var cmd = new SqlCommand("usp_GetCryptocurrencyBySymbol", conn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@Symbol", symbol);

                using (var reader = await cmd.ExecuteReaderAsync())
                {
                    if (await reader.ReadAsync())
                    {
                        return MapCrypto(reader);
                    }
                }
            }
            return null;
        }

        public async Task SaveCryptoPriceAsync(string symbol, decimal price, decimal priceChange24h)
        {
            using (var conn = (SqlConnection)_connectionFactory.CreateConnection())
            using (var cmd = new SqlCommand("usp_SaveCryptoPrice", conn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@Symbol", symbol);
                cmd.Parameters.AddWithValue("@Price", price);
                cmd.Parameters.AddWithValue("@PriceChange24h", priceChange24h);
                await cmd.ExecuteNonQueryAsync();
            }
        }

        public async Task<Cryptocurrency> GetLatestCryptoPriceAsync(string symbol)
        {
            using (var conn = (SqlConnection)_connectionFactory.CreateConnection())
            using (var cmd = new SqlCommand("usp_GetLatestCryptoPrice", conn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@Symbol", symbol);

                using (var reader = await cmd.ExecuteReaderAsync())
                {
                    if (await reader.ReadAsync())
                    {
                        return new Cryptocurrency
                        {
                            Symbol = reader.GetString(reader.GetOrdinal("Symbol")),
                            CurrentPrice = reader.GetDecimal(reader.GetOrdinal("CurrentPrice")),
                            PriceChange24h = reader.GetDecimal(reader.GetOrdinal("PriceChange24h")),
                            LastUpdated = reader.GetDateTime(reader.GetOrdinal("LastUpdated")),
                            IsActive = true
                        };
                    }
                }
            }
            return null;
        }

        public async Task<List<PriceHistory>> GetCryptoPriceHistoryAsync(string symbol, int limit = 100)
        {
            var list = new List<PriceHistory>();
            using (var conn = (SqlConnection)_connectionFactory.CreateConnection())
            using (var cmd = new SqlCommand("usp_GetCryptoPriceHistory", conn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@Symbol", symbol);
                cmd.Parameters.AddWithValue("@Limit", limit);

                using (var reader = await cmd.ExecuteReaderAsync())
                {
                    while (await reader.ReadAsync())
                    {
                        list.Add(new PriceHistory
                        {
                            PriceHistoryId = reader.GetInt32(reader.GetOrdinal("PriceHistoryId")),
                            Symbol = reader.GetString(reader.GetOrdinal("Symbol")),
                            Price = reader.GetDecimal(reader.GetOrdinal("Price")),
                            RecordedDate = reader.GetDateTime(reader.GetOrdinal("RecordedDate"))
                        });
                    }
                }
            }
            return list;
        }

        private static Cryptocurrency MapCrypto(SqlDataReader reader)
        {
            return new Cryptocurrency
            {
                CryptocurrencyId = reader.GetInt32(reader.GetOrdinal("CryptocurrencyId")),
                Symbol = reader.GetString(reader.GetOrdinal("Symbol")),
                Name = reader.GetString(reader.GetOrdinal("Name")),
                CurrentPrice = reader.GetDecimal(reader.GetOrdinal("CurrentPrice")),
                PriceChange24h = reader.GetDecimal(reader.GetOrdinal("PriceChange24h")),
                LastUpdated = reader.GetDateTime(reader.GetOrdinal("LastUpdated")),
                IsActive = reader.GetBoolean(reader.GetOrdinal("IsActive"))
            };
        }
    }
}

