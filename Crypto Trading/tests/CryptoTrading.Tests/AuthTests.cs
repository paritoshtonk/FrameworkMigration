using System;
using System.Security.Claims;
using System.Threading.Tasks;
using Moq;
using NUnit.Framework;
using CryptoTrading.Business.Services;
using CryptoTrading.Data.Repositories;
using CryptoTrading.Infrastructure.Logging;
using CryptoTrading.Infrastructure.Security;
using CryptoTrading.Models.Entities;
using CryptoTrading.Models.Requests;

namespace CryptoTrading.Tests
{
    [TestFixture]
    public class AuthTests
    {
        private Mock<IUserRepository> _userRepoMock;
        private Mock<IAccountRepository> _accountRepoMock;
        private IPasswordHasher _passwordHasher;
        private ITokenService _tokenService;
        private Mock<ILoggerService> _loggerMock;
        private AuthService _authService;

        [SetUp]
        public void Setup()
        {
            _userRepoMock = new Mock<IUserRepository>();
            _accountRepoMock = new Mock<IAccountRepository>();
            _passwordHasher = new Pbkdf2PasswordHasher();
            _tokenService = new JwtTokenService("ThisIsASecretKeyForTestingPurposesOnly123456!");
            _loggerMock = new Mock<ILoggerService>();

            _authService = new AuthService(
                _userRepoMock.Object,
                _accountRepoMock.Object,
                _passwordHasher,
                _tokenService,
                _loggerMock.Object
            );
        }

        [Test]
        public async Task RegisterAsync_ValidRequest_CreatesUserAndReturnsToken()
        {
            // Arrange
            var req = new RegisterRequest
            {
                Username = "newtrader",
                Email = "new@trading.com",
                Password = "Password123!",
                FirstName = "New",
                LastName = "Trader"
            };

            _userRepoMock.Setup(r => r.GetUserByUsernameAsync("newtrader")).ReturnsAsync((User)null);
            _userRepoMock.Setup(r => r.GetUserByEmailAsync("new@trading.com")).ReturnsAsync((User)null);
            _userRepoMock.Setup(r => r.CreateUserAsync("newtrader", "new@trading.com", It.IsAny<string>(), "New", "Trader"))
                .ReturnsAsync(new User
                {
                    UserId = 10,
                    Username = "newtrader",
                    Email = "new@trading.com",
                    FirstName = "New",
                    LastName = "Trader",
                    CreatedDate = DateTime.UtcNow,
                    IsActive = true
                });

            // Act
            var res = await _authService.RegisterAsync(req);

            // Assert
            Assert.IsNotNull(res);
            Assert.IsNotNull(res.Token);
            Assert.AreEqual("newtrader", res.User.Username);

            var principal = _tokenService.ValidateToken(res.Token);
            Assert.IsNotNull(principal);
            Assert.AreEqual("10", principal.FindFirst(ClaimTypes.NameIdentifier).Value);
        }

        [Test]
        public void RegisterAsync_DuplicateUsername_ThrowsInvalidOperationException()
        {
            // Arrange
            var req = new RegisterRequest
            {
                Username = "existinguser",
                Email = "unique@trading.com",
                Password = "Password123!",
                FirstName = "Test",
                LastName = "User"
            };

            _userRepoMock.Setup(r => r.GetUserByUsernameAsync("existinguser"))
                .ReturnsAsync(new User { UserId = 1, Username = "existinguser" });

            // Act & Assert
            var ex = Assert.ThrowsAsync<InvalidOperationException>(async () => await _authService.RegisterAsync(req));
            Assert.That(ex.Message, Does.Contain("Username is already taken"));
        }

        [Test]
        public async Task LoginAsync_ValidCredentials_ReturnsJwtToken()
        {
            // Arrange
            var password = "CorrectPassword123!";
            var hash = _passwordHasher.HashPassword(password);

            var user = new User
            {
                UserId = 5,
                Username = "active_user",
                Email = "active@test.com",
                PasswordHash = hash,
                FirstName = "Active",
                LastName = "User",
                IsActive = true
            };

            _userRepoMock.Setup(r => r.GetUserByUsernameAsync("active_user")).ReturnsAsync(user);

            // Act
            var res = await _authService.LoginAsync(new LoginRequest
            {
                UsernameOrEmail = "active_user",
                Password = password
            });

            // Assert
            Assert.IsNotNull(res);
            Assert.IsNotNull(res.Token);
            Assert.AreEqual(5, res.User.UserId);
        }

        [Test]
        public void LoginAsync_InvalidPassword_ThrowsUnauthorizedAccessException()
        {
            // Arrange
            var hash = _passwordHasher.HashPassword("CorrectPassword123!");
            var user = new User
            {
                UserId = 5,
                Username = "active_user",
                PasswordHash = hash,
                IsActive = true
            };

            _userRepoMock.Setup(r => r.GetUserByUsernameAsync("active_user")).ReturnsAsync(user);

            // Act & Assert
            Assert.ThrowsAsync<UnauthorizedAccessException>(async () =>
                await _authService.LoginAsync(new LoginRequest
                {
                    UsernameOrEmail = "active_user",
                    Password = "WrongPassword!"
                })
            );
        }
    }
}

