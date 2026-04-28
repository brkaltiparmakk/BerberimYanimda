using BerberYanimda.Domain;
using BerberYanimda.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace BerberYanimda.Infrastructure.Jobs;

public static class CleanupJobs
{
    public static async Task CleanupExpiredOtpsAsync(IServiceProvider serviceProvider, ILogger logger)
    {
        using var scope = serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var cutoff = DateTime.UtcNow.AddHours(-24);

        var expiredOtps = await db.OtpCodes
            .Where(x => x.ExpiresAt < cutoff)
            .ToListAsync();

        if (expiredOtps.Count > 0)
        {
            db.OtpCodes.RemoveRange(expiredOtps);
            await db.SaveChangesAsync();
            logger.LogInformation("{Count} süresi dolmuş OTP temizlendi.", expiredOtps.Count);
        }
    }

    public static async Task CleanupRevokedTokensAsync(IServiceProvider serviceProvider, ILogger logger)
    {
        using var scope = serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var cutoff = DateTime.UtcNow.AddDays(-7);

        var revokedTokens = await db.RefreshTokens
            .Where(x => x.RevokedAt != null && x.RevokedAt < cutoff)
            .ToListAsync();

        if (revokedTokens.Count > 0)
        {
            db.RefreshTokens.RemoveRange(revokedTokens);
            await db.SaveChangesAsync();
            logger.LogInformation("{Count} revoked refresh token temizlendi.", revokedTokens.Count);
        }
    }

    public static async Task CleanupOldNotificationsAsync(IServiceProvider serviceProvider, ILogger logger)
    {
        using var scope = serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var cutoff = DateTime.UtcNow.AddDays(-30);

        var oldNotifications = await db.Notifications
            .Where(x => x.IsRead && x.CreatedAt < cutoff)
            .Take(1000)
            .ToListAsync();

        if (oldNotifications.Count > 0)
        {
            db.Notifications.RemoveRange(oldNotifications);
            await db.SaveChangesAsync();
            logger.LogInformation("{Count} eski bildirim temizlendi.", oldNotifications.Count);
        }
    }

    public static async Task CompleteExpiredAppointmentsAsync(IServiceProvider serviceProvider, ILogger logger)
    {
        using var scope = serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var today = DateOnly.FromDateTime(DateTime.UtcNow);
        var currentTime = TimeOnly.FromDateTime(DateTime.UtcNow);

        var expiredAppointments = await db.Appointments
            .Where(x => (x.Status == AppointmentStatus.Confirmed || x.Status == AppointmentStatus.Upcoming || x.Status == AppointmentStatus.Pending) &&
                (x.AppointmentDate < today || (x.AppointmentDate == today && x.EndTime < currentTime)))
            .ToListAsync();

        var now = DateTime.UtcNow;

        foreach (var appointment in expiredAppointments)
        {
            appointment.Status = AppointmentStatus.Completed;
            appointment.CompletedAt = now;
            appointment.UpdatedAt = now;
        }

        if (expiredAppointments.Count > 0)
        {
            await db.SaveChangesAsync();
            logger.LogInformation("{Count} süresi geçmiş randevu tamamlandı olarak işaretlendi.", expiredAppointments.Count);
        }
    }

    public static async Task CleanupInactiveDeviceTokensAsync(IServiceProvider serviceProvider, ILogger logger)
    {
        using var scope = serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var cutoff = DateTime.UtcNow.AddDays(-90);

        var inactiveTokens = await db.DeviceTokens
            .Where(x => !x.IsActive && x.UpdatedAt < cutoff)
            .ToListAsync();

        if (inactiveTokens.Count > 0)
        {
            db.DeviceTokens.RemoveRange(inactiveTokens);
            await db.SaveChangesAsync();
            logger.LogInformation("{Count} pasif cihaz token'ı temizlendi.", inactiveTokens.Count);
        }
    }
}
