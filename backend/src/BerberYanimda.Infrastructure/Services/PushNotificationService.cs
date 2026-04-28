using BerberYanimda.Application.Interfaces;
using BerberYanimda.Domain;
using BerberYanimda.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace BerberYanimda.Infrastructure.Services;

public sealed class FirebasePushNotificationService : IPushNotificationService
{
    private readonly AppDbContext _db;
    private readonly ILogger<FirebasePushNotificationService> _logger;
    private readonly bool _isEnabled;

    public FirebasePushNotificationService(
        AppDbContext db,
        IConfiguration configuration,
        ILogger<FirebasePushNotificationService> logger)
    {
        _db = db;
        _logger = logger;
        _isEnabled = !string.IsNullOrWhiteSpace(configuration["Firebase:ProjectId"]);
    }

    public async Task SendToUserAsync(Guid userId, string title, string body, Dictionary<string, string>? data = null, CancellationToken ct = default)
    {
        if (!_isEnabled)
        {
            _logger.LogDebug("Firebase yapılandırılmadı, push notification atlandı.");
            return;
        }

        var tokens = await _db.DeviceTokens
            .Where(x => x.UserId == userId && x.IsActive)
            .Select(x => x.Token)
            .ToListAsync(ct);

        if (tokens.Count == 0)
        {
            _logger.LogDebug("Kullanıcı {UserId} için aktif cihaz token'ı bulunamadı.", userId);
            return;
        }

        foreach (var token in tokens)
        {
            try
            {
                await SendToDeviceAsync(token, title, body, data);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Cihaz token'ına push notification gönderilemedi: {TokenPrefix}", token[..Math.Min(10, token.Length)]);

                var deviceToken = await _db.DeviceTokens.FirstOrDefaultAsync(x => x.Token == token, ct);
                if (deviceToken is not null)
                {
                    deviceToken.IsActive = false;
                    deviceToken.UpdatedAt = DateTime.UtcNow;
                }
            }
        }

        await _db.SaveChangesAsync(ct);
    }

    public async Task SendToUsersAsync(IEnumerable<Guid> userIds, string title, string body, Dictionary<string, string>? data = null, CancellationToken ct = default)
    {
        foreach (var userId in userIds)
        {
            await SendToUserAsync(userId, title, body, data, ct);
        }
    }

    public async Task RegisterDeviceAsync(Guid userId, string token, string platform, CancellationToken ct = default)
    {
        var existing = await _db.DeviceTokens
            .FirstOrDefaultAsync(x => x.Token == token, ct);

        if (existing is not null)
        {
            if (existing.UserId != userId)
            {
                existing.UserId = userId;
            }
            existing.IsActive = true;
            existing.Platform = platform;
            existing.UpdatedAt = DateTime.UtcNow;
        }
        else
        {
            _db.DeviceTokens.Add(new DeviceToken
            {
                UserId = userId,
                Token = token,
                Platform = platform,
                IsActive = true,
                CreatedAt = DateTime.UtcNow
            });
        }

        await _db.SaveChangesAsync(ct);
    }

    public async Task UnregisterDeviceAsync(string token, CancellationToken ct = default)
    {
        var deviceToken = await _db.DeviceTokens
            .FirstOrDefaultAsync(x => x.Token == token, ct);

        if (deviceToken is not null)
        {
            deviceToken.IsActive = false;
            deviceToken.UpdatedAt = DateTime.UtcNow;
            await _db.SaveChangesAsync(ct);
        }
    }

    private Task SendToDeviceAsync(string token, string title, string body, Dictionary<string, string>? data)
    {
        // Firebase Admin SDK entegrasyonu burada yapılacak
        // Şimdilik log atıyoruz
        _logger.LogInformation("Push notification gönderildi - Token: {TokenPrefix}, Title: {Title}",
            token[..Math.Min(10, token.Length)], title);
        return Task.CompletedTask;
    }
}

public sealed class MockPushNotificationService : IPushNotificationService
{
    private readonly ILogger<MockPushNotificationService> _logger;

    public MockPushNotificationService(ILogger<MockPushNotificationService> logger)
    {
        _logger = logger;
    }

    public Task SendToUserAsync(Guid userId, string title, string body, Dictionary<string, string>? data = null, CancellationToken ct = default)
    {
        _logger.LogInformation("Mock Push - User: {UserId}, Title: {Title}, Body: {Body}", userId, title, body);
        return Task.CompletedTask;
    }

    public Task SendToUsersAsync(IEnumerable<Guid> userIds, string title, string body, Dictionary<string, string>? data = null, CancellationToken ct = default)
    {
        _logger.LogInformation("Mock Push - Users: {UserIds}, Title: {Title}", string.Join(",", userIds), title);
        return Task.CompletedTask;
    }

    public Task RegisterDeviceAsync(Guid userId, string token, string platform, CancellationToken ct = default)
    {
        _logger.LogInformation("Mock Push - Register Device: User: {UserId}, Platform: {Platform}", userId, platform);
        return Task.CompletedTask;
    }

    public Task UnregisterDeviceAsync(string token, CancellationToken ct = default)
    {
        _logger.LogInformation("Mock Push - Unregister Device: {TokenPrefix}", token[..Math.Min(10, token.Length)]);
        return Task.CompletedTask;
    }
}
