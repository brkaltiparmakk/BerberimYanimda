using BerberYanimda.Application.Common;
using BerberYanimda.Application.DTOs;
using BerberYanimda.Application.Interfaces;
using BerberYanimda.Domain;
using Microsoft.EntityFrameworkCore;

namespace BerberYanimda.Application.Services;

public sealed class NotificationService(IAppDbContext db, IPushNotificationService pushNotificationService)
{
    public async Task<IReadOnlyList<NotificationDto>> GetMineAsync(Guid userId, CancellationToken ct)
    {
        return await db.Notifications
            .AsNoTracking()
            .Where(x => x.UserId == userId)
            .OrderByDescending(x => x.CreatedAt)
            .Take(100)
            .Select(x => new NotificationDto(x.Id, x.Title, x.Message, x.Type, x.IsRead, x.CreatedAt))
            .ToListAsync(ct);
    }

    public async Task MarkReadAsync(Guid userId, Guid notificationId, CancellationToken ct)
    {
        var notification = await db.Notifications.FirstOrDefaultAsync(x => x.Id == notificationId && x.UserId == userId, ct)
            ?? throw new AppException("Bildirim bulunamadı.", 404);
        notification.IsRead = true;
        await db.SaveChangesAsync(ct);
    }

    public async Task MarkAllReadAsync(Guid userId, CancellationToken ct)
    {
        var notifications = await db.Notifications.Where(x => x.UserId == userId && !x.IsRead).ToListAsync(ct);
        foreach (var notification in notifications)
        {
            notification.IsRead = true;
        }

        await db.SaveChangesAsync(ct);
    }

    public async Task CreateAndPushAsync(Guid userId, string title, string message, NotificationType type, CancellationToken ct)
    {
        var notification = new Notification
        {
            UserId = userId,
            Title = title,
            Message = message,
            Type = type,
            IsRead = false,
            CreatedAt = DateTime.UtcNow
        };

        db.Notifications.Add(notification);
        await db.SaveChangesAsync(ct);

        try
        {
            await pushNotificationService.SendToUserAsync(userId, title, message, ct: ct);
        }
        catch
        {
            // Push notification başarısız olsa bile akışı bozma
        }
    }
}
