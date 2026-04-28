using BerberYanimda.Application.Common;
using BerberYanimda.Application.DTOs;
using BerberYanimda.Application.Interfaces;
using BerberYanimda.Domain;
using Microsoft.EntityFrameworkCore;

namespace BerberYanimda.Application.Services;

public sealed class CatalogService(IAppDbContext db, IDateTimeProvider clock, ICacheService cache)
{
    public async Task<PagedResponse<BarberListItemDto>> GetBarbersAsync(
        Guid? userId,
        string? search,
        string? city,
        string? district,
        string? sortBy,
        int page,
        int pageSize,
        CancellationToken ct)
    {
        page = Math.Max(page, 1);
        pageSize = Math.Clamp(pageSize, 1, 50);

        var cacheKey = $"catalog:all:{search}:{city}:{district}:{sortBy}:{page}:{pageSize}:{userId}";
        var cached = cache.Get<PagedResponse<BarberListItemDto>>(cacheKey);
        if (cached is not null) return cached;

        var query = db.BarberShops
            .AsNoTracking()
            .Where(x => x.IsActive && x.IsApproved);

        if (!string.IsNullOrWhiteSpace(search))
        {
            var term = search.Trim().ToLower();
            query = query.Where(x => x.Name.ToLower().Contains(term) || x.District.ToLower().Contains(term) || x.City.ToLower().Contains(term));
        }

        if (!string.IsNullOrWhiteSpace(city))
        {
            query = query.Where(x => x.City == city);
        }

        if (!string.IsNullOrWhiteSpace(district))
        {
            query = query.Where(x => x.District == district);
        }

        query = sortBy switch
        {
            "rating" => query.OrderByDescending(x => x.AverageRating),
            "price" => query.OrderBy(x => x.StartingPrice),
            _ => query.OrderByDescending(x => x.AverageRating).ThenBy(x => x.StartingPrice)
        };

        var total = await query.CountAsync(ct);
        var favoriteIds = userId is null
            ? []
            : await db.FavoriteBarberShops
                .Where(x => x.UserId == userId.Value)
                .Select(x => x.BarberShopId)
                .ToListAsync(ct);

        var day = ToBusinessDay(clock.Today.DayOfWeek);
        var items = await query.Skip((page - 1) * pageSize).Take(pageSize)
            .Select(x => new BarberListItemDto(
                x.Id,
                x.Name,
                x.District,
                x.City,
                x.AverageRating,
                x.ReviewCount,
                null,
                x.StartingPrice,
                x.WorkingHours.Any(h => h.DayOfWeek == day && !h.IsClosed),
                x.CoverImageUrl,
                favoriteIds.Contains(x.Id)))
            .ToListAsync(ct);

        var result = new PagedResponse<BarberListItemDto>
        {
            Items = items,
            Page = page,
            PageSize = pageSize,
            TotalCount = total,
            TotalPages = (int)Math.Ceiling(total / (double)pageSize)
        };
        cache.Set(cacheKey, result, TimeSpan.FromMinutes(5));
        return result;
    }

    public async Task<BarberDetailDto> GetBarberAsync(Guid barberShopId, Guid? userId, CancellationToken ct)
    {
        var cacheKey = $"catalog:detail:{barberShopId}:{userId}";
        var cached = cache.Get<BarberDetailDto>(cacheKey);
        if (cached is not null) return cached;

        var shop = await db.BarberShops
            .AsNoTracking()
            .Include(x => x.Services.Where(s => s.IsActive))
            .Include(x => x.StaffMembers.Where(s => s.IsActive))
            .FirstOrDefaultAsync(x => x.Id == barberShopId && x.IsActive && x.IsApproved, ct)
            ?? throw new AppException("Berber bulunamadı.", 404);

        var isFavorite = userId is not null &&
            await db.FavoriteBarberShops.AnyAsync(x => x.UserId == userId.Value && x.BarberShopId == barberShopId, ct);

        var result = new BarberDetailDto(
            shop.Id,
            shop.Name,
            shop.Description,
            shop.District,
            shop.City,
            shop.Address,
            shop.PhoneNumber ?? string.Empty,
            shop.Latitude,
            shop.Longitude,
            shop.AverageRating,
            shop.ReviewCount,
            shop.StartingPrice,
            shop.CoverImageUrl,
            shop.LogoUrl,
            isFavorite,
            shop.Services.OrderBy(x => x.Price).Select(ToServiceDto).ToList(),
            shop.StaffMembers.OrderByDescending(x => x.AverageRating).Select(ToStaffDto).ToList());
        cache.Set(cacheKey, result, TimeSpan.FromMinutes(5));
        return result;
    }

    public async Task<IReadOnlyList<BarberServiceDto>> GetServicesAsync(Guid barberShopId, CancellationToken ct)
    {
        await EnsurePublicShopAsync(barberShopId, ct);
        return await db.BarberServices
            .AsNoTracking()
            .Where(x => x.BarberShopId == barberShopId && x.IsActive)
            .OrderBy(x => x.Price)
            .Select(x => ToServiceDto(x))
            .ToListAsync(ct);
    }

    public async Task<IReadOnlyList<StaffDto>> GetStaffAsync(Guid barberShopId, CancellationToken ct)
    {
        await EnsurePublicShopAsync(barberShopId, ct);
        return await db.StaffMembers
            .AsNoTracking()
            .Where(x => x.BarberShopId == barberShopId && x.IsActive)
            .OrderByDescending(x => x.AverageRating)
            .Select(x => ToStaffDto(x))
            .ToListAsync(ct);
    }

    private async Task EnsurePublicShopAsync(Guid barberShopId, CancellationToken ct)
    {
        if (!await db.BarberShops.AnyAsync(x => x.Id == barberShopId && x.IsActive && x.IsApproved, ct))
        {
            throw new AppException("Berber bulunamadı.", 404);
        }
    }

    private static BarberServiceDto ToServiceDto(BarberService service) =>
        new(service.Id, service.Name, service.Description, service.DurationMinutes, service.Price);

    private static StaffDto ToStaffDto(StaffMember staff) =>
        new(staff.Id, staff.FullName, staff.Expertise, staff.Bio, staff.AvatarUrl, staff.AverageRating, staff.IsActive);

    private static int ToBusinessDay(DayOfWeek day) => day == DayOfWeek.Sunday ? 7 : (int)day;
}
