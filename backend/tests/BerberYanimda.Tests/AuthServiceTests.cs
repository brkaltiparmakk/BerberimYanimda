using BerberYanimda.Application.Common;
using BerberYanimda.Application.DTOs;
using BerberYanimda.Application.Interfaces;
using BerberYanimda.Application.Services;
using BerberYanimda.Domain;
using BerberYanimda.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace BerberYanimda.Tests;

public sealed class AuthServiceTests
{
    [Fact]
    public async Task RegisterAsync_creates_user_with_correct_data()
    {
        await using var db = CreateDb();
        var service = CreateAuthService(db);

        await service.RegisterAsync(new RegisterRequest(" Burak Yılmaz ", "+90 555 111 22 33", null, "Test1234!"), CancellationToken.None);

        var user = await db.Users.FirstOrDefaultAsync(x => x.PhoneNumber == "+905551112233");
        Assert.NotNull(user);
        Assert.Equal("Burak Yılmaz", user.FullName);
        Assert.Equal("+905551112233", user.PhoneNumber);
        Assert.Null(user.Email);
        Assert.Equal(UserRole.Customer, user.Role);
        Assert.False(user.IsPhoneVerified);
        Assert.NotNull(user.PasswordHash);
        Assert.Equal("HASHED:Test1234!", user.PasswordHash);
    }

    [Fact]
    public async Task RegisterAsync_rejects_short_password()
    {
        await using var db = CreateDb();
        var service = CreateAuthService(db);

        var ex = await Assert.ThrowsAsync<AppException>(() =>
            service.RegisterAsync(new RegisterRequest("Test User", "+905551112233", null, "Abc1"), CancellationToken.None));

        Assert.Equal(422, ex.StatusCode);
    }

    [Fact]
    public async Task RegisterAsync_rejects_password_without_upper()
    {
        await using var db = CreateDb();
        var service = CreateAuthService(db);

        var ex = await Assert.ThrowsAsync<AppException>(() =>
            service.RegisterAsync(new RegisterRequest("Test User", "+905551112233", null, "test1234!"), CancellationToken.None));

        Assert.Equal(422, ex.StatusCode);
    }

    [Fact]
    public async Task RegisterAsync_rejects_password_without_digit()
    {
        await using var db = CreateDb();
        var service = CreateAuthService(db);

        var ex = await Assert.ThrowsAsync<AppException>(() =>
            service.RegisterAsync(new RegisterRequest("Test User", "+905551112233", null, "TestTest!"), CancellationToken.None));

        Assert.Equal(422, ex.StatusCode);
    }

    [Fact]
    public async Task RegisterAsync_rejects_duplicate_phone()
    {
        await using var db = CreateDb();
        var service = CreateAuthService(db);

        await service.RegisterAsync(new RegisterRequest("First User", "+905551112233", null, "Test1234!"), CancellationToken.None);

        var ex = await Assert.ThrowsAsync<AppException>(() =>
            service.RegisterAsync(new RegisterRequest("Second User", "+905551112233", null, "Test1234!"), CancellationToken.None));

        Assert.Equal(409, ex.StatusCode);
    }

    [Fact]
    public async Task LoginAsync_returns_tokens_and_user()
    {
        await using var db = CreateDb();
        await SeedUserAsync(db, isPhoneVerified: true);
        var service = CreateAuthService(db);

        var result = await service.LoginAsync(new LoginRequest("+905551112233", FixedPasswordService.KnownPassword), null, null, CancellationToken.None);

        Assert.False(result.MfaRequired);
        Assert.NotNull(result.Tokens);
        Assert.NotNull(result.Tokens.AccessToken);
        Assert.NotNull(result.Tokens.RefreshToken);
        Assert.NotNull(result.Tokens.User);
        Assert.Equal("+905551112233", result.Tokens.User.PhoneNumber);
    }

    [Fact]
    public async Task LoginAsync_rejects_wrong_password()
    {
        await using var db = CreateDb();
        await SeedUserAsync(db, isPhoneVerified: true);
        var service = CreateAuthService(db);

        var ex = await Assert.ThrowsAsync<AppException>(() =>
            service.LoginAsync(new LoginRequest("+905551112233", "WrongPass!"), null, null, CancellationToken.None));

        Assert.Equal(401, ex.StatusCode);
    }

    [Fact]
    public async Task LoginAsync_rejects_unverified_phone()
    {
        await using var db = CreateDb();
        await SeedUserAsync(db, isPhoneVerified: false);
        var service = CreateAuthService(db);

        var ex = await Assert.ThrowsAsync<AppException>(() =>
            service.LoginAsync(new LoginRequest("+905551112233", FixedPasswordService.KnownPassword), null, null, CancellationToken.None));

        Assert.Equal(403, ex.StatusCode);
    }

    [Fact]
    public async Task LoginAsync_creates_otp_for_unverified_user()
    {
        await using var db = CreateDb();
        var service = CreateAuthService(db);

        await service.RegisterAsync(new RegisterRequest("Test User", "+905551112233", null, "Test1234!"), CancellationToken.None);

        var otp = await db.OtpCodes.FirstOrDefaultAsync(x => x.PhoneNumber == "+905551112233");
        Assert.NotNull(otp);
        Assert.NotNull(otp.CodeHash);
        Assert.False(otp.VerifiedAt.HasValue);
    }

    [Fact]
    public async Task VerifyOtpAsync_success_verifies_phone()
    {
        await using var db = CreateDb();
        var user = await SeedUserAsync(db, isPhoneVerified: false);
        var secureHasher = new StubSecureHasher();
        var clock = new FixedClock();
        db.OtpCodes.Add(new OtpCode
        {
            PhoneNumber = "+905551112233",
            CodeHash = secureHasher.Hash("123456"),
            ExpiresAt = clock.UtcNow.AddMinutes(3),
            SentAt = clock.UtcNow
        });
        await db.SaveChangesAsync();
        var service = CreateAuthService(db);

        await service.VerifyOtpAsync(new VerifyOtpRequest("+905551112233", "123456"), CancellationToken.None);

        var updatedUser = await db.Users.FindAsync(user.Id);
        Assert.NotNull(updatedUser);
        Assert.True(updatedUser.IsPhoneVerified);
        var otp = await db.OtpCodes.FirstAsync(x => x.PhoneNumber == "+905551112233");
        Assert.NotNull(otp.VerifiedAt);
    }

    [Fact]
    public async Task VerifyOtpAsync_rejects_wrong_code()
    {
        await using var db = CreateDb();
        await SeedUserAsync(db, isPhoneVerified: false);
        var secureHasher = new StubSecureHasher();
        var clock = new FixedClock();
        db.OtpCodes.Add(new OtpCode
        {
            PhoneNumber = "+905551112233",
            CodeHash = secureHasher.Hash("123456"),
            ExpiresAt = clock.UtcNow.AddMinutes(3),
            SentAt = clock.UtcNow
        });
        await db.SaveChangesAsync();
        var service = CreateAuthService(db);

        var ex = await Assert.ThrowsAsync<AppException>(() =>
            service.VerifyOtpAsync(new VerifyOtpRequest("+905551112233", "999999"), CancellationToken.None));

        Assert.Equal(422, ex.StatusCode);
    }

    [Fact]
    public async Task VerifyOtpAsync_rejects_expired_otp()
    {
        await using var db = CreateDb();
        await SeedUserAsync(db, isPhoneVerified: false);
        var secureHasher = new StubSecureHasher();
        var clock = new FixedClock();
        db.OtpCodes.Add(new OtpCode
        {
            PhoneNumber = "+905551112233",
            CodeHash = secureHasher.Hash("123456"),
            ExpiresAt = clock.UtcNow.AddMinutes(-1),
            SentAt = clock.UtcNow.AddMinutes(-4)
        });
        await db.SaveChangesAsync();
        var service = CreateAuthService(db);

        var ex = await Assert.ThrowsAsync<AppException>(() =>
            service.VerifyOtpAsync(new VerifyOtpRequest("+905551112233", "123456"), CancellationToken.None));

        Assert.Equal(422, ex.StatusCode);
    }

    [Fact]
    public async Task RefreshTokenAsync_returns_new_tokens()
    {
        await using var db = CreateDb();
        var user = await SeedUserAsync(db, isPhoneVerified: true);
        var secureHasher = new StubSecureHasher();
        var clock = new FixedClock();
        var refreshTokenValue = "old_refresh_token";
        db.RefreshTokens.Add(new RefreshToken
        {
            UserId = user.Id,
            TokenHash = secureHasher.Hash(refreshTokenValue),
            ExpiresAt = clock.UtcNow.AddDays(30),
            CreatedAt = clock.UtcNow
        });
        await db.SaveChangesAsync();
        var service = CreateAuthService(db);

        var result = await service.RefreshAsync(new RefreshTokenRequest(refreshTokenValue), null, null, CancellationToken.None);

        Assert.NotNull(result);
        Assert.NotEmpty(result.AccessToken);
        Assert.NotEmpty(result.RefreshToken);
        Assert.NotNull(result.User);
        var revokedToken = await db.RefreshTokens.FirstAsync(x => x.UserId == user.Id);
        Assert.NotNull(revokedToken.RevokedAt);
    }

    [Fact]
    public async Task RefreshTokenAsync_rejects_revoked_token()
    {
        await using var db = CreateDb();
        var user = await SeedUserAsync(db, isPhoneVerified: true);
        var secureHasher = new StubSecureHasher();
        var clock = new FixedClock();
        db.RefreshTokens.Add(new RefreshToken
        {
            UserId = user.Id,
            TokenHash = secureHasher.Hash("revoked_token"),
            ExpiresAt = clock.UtcNow.AddDays(30),
            CreatedAt = clock.UtcNow,
            RevokedAt = clock.UtcNow
        });
        await db.SaveChangesAsync();
        var service = CreateAuthService(db);

        var ex = await Assert.ThrowsAsync<AppException>(() =>
            service.RefreshAsync(new RefreshTokenRequest("revoked_token"), null, null, CancellationToken.None));

        Assert.Equal(401, ex.StatusCode);
    }

    [Fact]
    public async Task LogoutAsync_revokes_all_user_tokens()
    {
        await using var db = CreateDb();
        var user = await SeedUserAsync(db, isPhoneVerified: true);
        var secureHasher = new StubSecureHasher();
        var clock = new FixedClock();
        var future = clock.UtcNow.AddDays(30);
        db.RefreshTokens.Add(new RefreshToken
        {
            UserId = user.Id,
            TokenHash = secureHasher.Hash("token_a"),
            ExpiresAt = future,
            CreatedAt = clock.UtcNow
        });
        db.RefreshTokens.Add(new RefreshToken
        {
            UserId = user.Id,
            TokenHash = secureHasher.Hash("token_b"),
            ExpiresAt = future,
            CreatedAt = clock.UtcNow
        });
        db.RefreshTokens.Add(new RefreshToken
        {
            UserId = user.Id,
            TokenHash = secureHasher.Hash("token_c"),
            ExpiresAt = future,
            CreatedAt = clock.UtcNow
        });
        await db.SaveChangesAsync();
        var service = CreateAuthService(db);

        await service.LogoutAsync(new LogoutRequest("token_a"), CancellationToken.None);

        var tokens = await db.RefreshTokens.Where(x => x.UserId == user.Id).ToListAsync();
        Assert.Equal(3, tokens.Count);
        Assert.All(tokens, t => Assert.NotNull(t.RevokedAt));
    }

    private static AppDbContext CreateDb()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .ConfigureWarnings(warnings => warnings.Ignore(Microsoft.EntityFrameworkCore.Diagnostics.InMemoryEventId.TransactionIgnoredWarning))
            .Options;
        return new AppDbContext(options);
    }

    private static async Task<User> SeedUserAsync(AppDbContext db, bool isPhoneVerified = true)
    {
        var user = new User
        {
            FullName = "Test User",
            PhoneNumber = "+905551112233",
            IsPhoneVerified = isPhoneVerified,
            IsActive = true,
            PasswordHash = $"HASHED:{FixedPasswordService.KnownPassword}",
            Role = UserRole.Customer
        };
        db.Users.Add(user);
        await db.SaveChangesAsync();
        return user;
    }

    private static AuthService CreateAuthService(AppDbContext db, IPasswordService? passwordService = null)
    {
        return new AuthService(
            db,
            passwordService ?? new FixedPasswordService(),
            new StubSecureHasher(),
            new StubTokenService(),
            new NoOpSmsSender(),
            new FixedClock(),
            new FixedEncryptionService(),
            new FixedTotpService());
    }
}
