using BerberYanimda.Application.Interfaces;
using BerberYanimda.Domain;

namespace BerberYanimda.Application.Services;

public sealed class AuditLogService(IAppDbContext db, IDateTimeProvider clock) : IAuditLogService
{
    public async Task LogAsync(
        Guid? userId,
        string action,
        string? entityName = null,
        string? entityId = null,
        string? oldValue = null,
        string? newValue = null,
        string? ipAddress = null,
        string? userAgent = null,
        CancellationToken ct = default)
    {
        db.AuditLogs.Add(new AuditLog
        {
            UserId = userId,
            Action = action,
            EntityName = entityName,
            EntityId = entityId,
            OldValue = oldValue,
            NewValue = newValue,
            IpAddress = ipAddress,
            UserAgent = userAgent,
            CreatedAt = clock.UtcNow,
        });

        await db.SaveChangesAsync(ct);
    }
}
