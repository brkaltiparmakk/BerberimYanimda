using BerberYanimda.Application.Common;
using BerberYanimda.Application.DTOs;
using BerberYanimda.Application.Interfaces;
using BerberYanimda.Domain;
using Microsoft.EntityFrameworkCore;

namespace BerberYanimda.Application.Services;

public sealed class AdminService(IAppDbContext db, IDateTimeProvider clock, IAuditLogService auditLog)
{
    public async Task<IReadOnlyList<BarberListItemDto>> GetPendingBarbersAsync(CancellationToken ct)
    {
        return await db.BarberShops
            .AsNoTracking()
            .Where(x => x.IsActive && !x.IsApproved)
            .OrderBy(x => x.CreatedAt)
            .Select(x => new BarberListItemDto(
                x.Id,
                x.Name,
                x.District,
                x.City,
                x.AverageRating,
                x.ReviewCount,
                null,
                x.StartingPrice,
                false,
                x.CoverImageUrl,
                false))
            .ToListAsync(ct);
    }

    public async Task ApproveBarberAsync(Guid adminUserId, Guid barberShopId, string? ipAddress, string? userAgent, CancellationToken ct)
    {
        var shop = await db.BarberShops.FirstOrDefaultAsync(x => x.Id == barberShopId && x.IsActive, ct)
            ?? throw new AppException("Berber bulunamadı.", 404);

        shop.IsApproved = true;
        shop.UpdatedAt = clock.UtcNow;
        await auditLog.LogAsync(adminUserId, "BARBER_APPROVED", nameof(BarberShop), shop.Id.ToString(),
            oldValue: "false", newValue: "true", ipAddress: ipAddress, userAgent: userAgent, ct: ct);
        await db.SaveChangesAsync(ct);
    }

    public async Task DeactivateBarberAsync(Guid adminUserId, Guid barberShopId, string? ipAddress, string? userAgent, CancellationToken ct)
    {
        var shop = await db.BarberShops.FirstOrDefaultAsync(x => x.Id == barberShopId, ct)
            ?? throw new AppException("Berber bulunamadı.", 404);

        shop.IsActive = false;
        shop.UpdatedAt = clock.UtcNow;
        await auditLog.LogAsync(adminUserId, "BARBER_DEACTIVATED", nameof(BarberShop), shop.Id.ToString(),
            oldValue: "true", newValue: "false", ipAddress: ipAddress, userAgent: userAgent, ct: ct);
        await db.SaveChangesAsync(ct);
    }
}
