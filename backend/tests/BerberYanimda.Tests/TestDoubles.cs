using BerberYanimda.Application.Interfaces;
using BerberYanimda.Domain;

namespace BerberYanimda.Tests;

public sealed class NoOpPushNotificationService : IPushNotificationService
{
    public Task SendToUserAsync(Guid userId, string title, string body, Dictionary<string, string>? data = null, CancellationToken ct = default)
        => Task.CompletedTask;

    public Task SendToUsersAsync(IEnumerable<Guid> userIds, string title, string body, Dictionary<string, string>? data = null, CancellationToken ct = default)
        => Task.CompletedTask;

    public Task RegisterDeviceAsync(Guid userId, string token, string platform, CancellationToken ct = default)
        => Task.CompletedTask;

    public Task UnregisterDeviceAsync(string token, CancellationToken ct = default)
        => Task.CompletedTask;
}

public sealed class NoOpAuditLogService : IAuditLogService
{
    public Task LogAsync(Guid? userId, string action, string? entityName = null, string? entityId = null, string? oldValue = null, string? newValue = null, string? ipAddress = null, string? userAgent = null, CancellationToken ct = default)
        => Task.CompletedTask;
}

public sealed class NoOpSmsSender : ISmsSender
{
    public Task SendOtpAsync(string phoneNumber, string code, CancellationToken cancellationToken = default) => Task.CompletedTask;
}

public sealed class StubTokenService : ITokenService
{
    public TokenIssueResult IssueAccessToken(User user) => new($"access_{user.Id}", 3600);

    public string GenerateRefreshToken() => $"refresh_{Guid.NewGuid():N}";

    public string IssueMfaTempToken(User user) => throw new NotImplementedException();

    public System.Security.Claims.ClaimsPrincipal ValidateMfaTempToken(string token) => throw new NotImplementedException();
}

public sealed class FixedPasswordService : IPasswordService
{
    public const string KnownPassword = "Test1234!";

    public string HashPassword(User user, string password) => $"HASHED:{password}";

    public bool VerifyPassword(User user, string password) => password == KnownPassword;
}

public sealed class StubSecureHasher : ISecureHasher
{
    public string Hash(string value) => $"HASHED_{value}";

    public bool Verify(string value, string hash) => hash == $"HASHED_{value}";
}

public sealed class FixedEncryptionService : IEncryptionService
{
    public string Encrypt(string plainText) => $"ENC:{plainText}";

    public string Decrypt(string cipherText) => cipherText.StartsWith("ENC:") ? cipherText[4..] : cipherText;
}

public sealed class FixedTotpService : ITotpService
{
    public string GenerateSecret() => "TESTSECRET123";

    public string GenerateQrCodeUri(string label, string secret, string issuer) => $"otpauth://totp/{issuer}:{label}?secret={secret}";

    public bool Verify(string secret, string code) => code == "123456";
}

public sealed class FixedClock : IDateTimeProvider
{
    public DateTime UtcNow => new(2026, 4, 23, 8, 0, 0, DateTimeKind.Utc);
    public DateOnly Today => new(2026, 4, 23);
}
