using BerberYanimda.Application.Common;
using BerberYanimda.Application.DTOs;
using BerberYanimda.Application.Interfaces;
using BerberYanimda.Domain;
using Microsoft.EntityFrameworkCore;

namespace BerberYanimda.Application.Services;

public sealed class FavoriteService(IAppDbContext db, IDateTimeProvider clock)
{
    public async Task<IReadOnlyList<FavoriteDto>> GetMineAsync(Guid userId, CancellationToken ct)
    {
        return await db.FavoriteBarberShops
            .AsNoTracking()
            .Include(x => x.BarberShop)
            .Where(x => x.UserId == userId && x.BarberShop != null && x.BarberShop.IsActive && x.BarberShop.IsApproved)
            .OrderByDescending(x => x.CreatedAt)
            .Select(x => new FavoriteDto(
                x.BarberShopId,
                x.BarberShop!.Name,
                x.BarberShop.District,
                x.BarberShop.City,
                x.BarberShop.CoverImageUrl,
                x.BarberShop.AverageRating))
            .ToListAsync(ct);
    }

    public async Task AddAsync(Guid userId, Guid barberShopId, CancellationToken ct)
    {
        var exists = await db.BarberShops.AnyAsync(x => x.Id == barberShopId && x.IsActive && x.IsApproved, ct);
        if (!exists)
        {
            throw new AppException("Berber bulunamadı.", 404);
        }

        var alreadyFavorite = await db.FavoriteBarberShops.AnyAsync(x => x.UserId == userId && x.BarberShopId == barberShopId, ct);
        if (!alreadyFavorite)
        {
            db.FavoriteBarberShops.Add(new FavoriteBarberShop
            {
                UserId = userId,
                BarberShopId = barberShopId,
                CreatedAt = clock.UtcNow
            });
            await db.SaveChangesAsync(ct);
        }
    }

    public async Task RemoveAsync(Guid userId, Guid barberShopId, CancellationToken ct)
    {
        var favorite = await db.FavoriteBarberShops.FirstOrDefaultAsync(x => x.UserId == userId && x.BarberShopId == barberShopId, ct);
        if (favorite is not null)
        {
            db.FavoriteBarberShops.Remove(favorite);
            await db.SaveChangesAsync(ct);
        }
    }
}
