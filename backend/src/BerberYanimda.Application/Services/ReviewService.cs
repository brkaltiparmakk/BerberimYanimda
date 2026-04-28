using BerberYanimda.Application.Common;
using BerberYanimda.Application.DTOs;
using BerberYanimda.Application.Interfaces;
using BerberYanimda.Domain;
using Microsoft.EntityFrameworkCore;

namespace BerberYanimda.Application.Services;

public sealed class ReviewService(IAppDbContext db, IDateTimeProvider clock)
{
    public async Task<ReviewDto> CreateAsync(Guid customerUserId, CreateReviewRequest request, CancellationToken ct)
    {
        if (request.Rating < 1 || request.Rating > 5)
        {
            throw new AppException("Puan 1 ile 5 arasında olmalıdır.", 422);
        }

        var appointment = await db.Appointments
            .Include(x => x.BarberShop)
            .Include(x => x.StaffMember)
            .FirstOrDefaultAsync(x => x.Id == request.AppointmentId, ct)
            ?? throw new AppException("Randevu bulunamadı.", 404);

        if (appointment.CustomerUserId != customerUserId)
        {
            throw new AppException("Bu randevuya yorum yapma yetkiniz yok.", 403);
        }

        if (appointment.Status != AppointmentStatus.Completed)
        {
            throw new AppException("Sadece tamamlanmış randevulara yorum yapılabilir.", 422);
        }

        var existingReview = await db.Reviews.AnyAsync(x => x.AppointmentId == request.AppointmentId, ct);
        if (existingReview)
        {
            throw new AppException("Bu randevu için zaten yorum yapılmış.", 409);
        }

        var customer = await db.Users.FirstOrDefaultAsync(x => x.Id == customerUserId, ct)
            ?? throw new AppException("Kullanıcı bulunamadı.", 404);

        var review = new Review
        {
            AppointmentId = request.AppointmentId,
            CustomerUserId = customerUserId,
            BarberShopId = appointment.BarberShopId,
            StaffMemberId = appointment.StaffMemberId,
            Rating = request.Rating,
            Comment = string.IsNullOrWhiteSpace(request.Comment) ? null : request.Comment.Trim(),
            IsApproved = false,
            CreatedAt = clock.UtcNow
        };

        db.Reviews.Add(review);
        await db.SaveChangesAsync(ct);

        return ToDto(review, customer.FullName, appointment.StaffMember?.FullName);
    }

    public async Task<IReadOnlyList<ReviewDto>> GetByBarberShopAsync(Guid barberShopId, CancellationToken ct)
    {
        var shopExists = await db.BarberShops.AnyAsync(x => x.Id == barberShopId && x.IsActive && x.IsApproved, ct);
        if (!shopExists)
        {
            throw new AppException("Berber bulunamadı.", 404);
        }

        return await db.Reviews
            .AsNoTracking()
            .Include(x => x.CustomerUser)
            .Include(x => x.StaffMember)
            .Where(x => x.BarberShopId == barberShopId && x.IsApproved)
            .OrderByDescending(x => x.CreatedAt)
            .Select(x => ToDto(x, x.CustomerUser!.FullName, x.StaffMember != null ? x.StaffMember.FullName : null))
            .ToListAsync(ct);
    }

    public async Task<ReviewSummaryDto> GetSummaryAsync(Guid barberShopId, CancellationToken ct)
    {
        var reviews = await db.Reviews
            .AsNoTracking()
            .Where(x => x.BarberShopId == barberShopId && x.IsApproved)
            .ToListAsync(ct);

        if (reviews.Count == 0)
        {
            return new ReviewSummaryDto(0, 0);
        }

        var average = (decimal)reviews.Average(x => x.Rating);
        return new ReviewSummaryDto(Math.Round(average, 2), reviews.Count);
    }

    public async Task<IReadOnlyList<ReviewDto>> GetPendingAsync(CancellationToken ct)
    {
        return await db.Reviews
            .AsNoTracking()
            .Include(x => x.CustomerUser)
            .Include(x => x.StaffMember)
            .Where(x => !x.IsApproved)
            .OrderBy(x => x.CreatedAt)
            .Select(x => ToDto(x, x.CustomerUser!.FullName, x.StaffMember != null ? x.StaffMember.FullName : null))
            .ToListAsync(ct);
    }

    public async Task ApproveAsync(Guid reviewId, CancellationToken ct)
    {
        var review = await db.Reviews.FirstOrDefaultAsync(x => x.Id == reviewId, ct)
            ?? throw new AppException("Yorum bulunamadı.", 404);

        if (review.IsApproved)
        {
            throw new AppException("Yorum zaten onaylanmış.", 409);
        }

        review.IsApproved = true;
        await db.SaveChangesAsync(ct);

        await UpdateShopRatingAsync(review.BarberShopId, ct);

        if (review.StaffMemberId.HasValue)
        {
            await UpdateStaffRatingAsync(review.StaffMemberId.Value, ct);
        }

        await db.SaveChangesAsync(ct);
    }

    public async Task DeleteAsync(Guid reviewId, CancellationToken ct)
    {
        var review = await db.Reviews.FirstOrDefaultAsync(x => x.Id == reviewId, ct)
            ?? throw new AppException("Yorum bulunamadı.", 404);

        var barberShopId = review.BarberShopId;
        var staffMemberId = review.StaffMemberId;

        db.Reviews.Remove(review);
        await UpdateShopRatingAsync(barberShopId, ct);

        if (staffMemberId.HasValue)
        {
            await UpdateStaffRatingAsync(staffMemberId.Value, ct);
        }

        await db.SaveChangesAsync(ct);
    }

    private async Task UpdateShopRatingAsync(Guid barberShopId, CancellationToken ct)
    {
        var shop = await db.BarberShops.FirstOrDefaultAsync(x => x.Id == barberShopId, ct);
        if (shop is null) return;

        var reviews = await db.Reviews
            .Where(x => x.BarberShopId == barberShopId && x.IsApproved)
            .ToListAsync(ct);

        shop.ReviewCount = reviews.Count;
        shop.AverageRating = reviews.Count == 0 ? 0 : Math.Round((decimal)reviews.Average(x => x.Rating), 2);
        shop.UpdatedAt = clock.UtcNow;
    }

    private async Task UpdateStaffRatingAsync(Guid staffMemberId, CancellationToken ct)
    {
        var staff = await db.StaffMembers.FirstOrDefaultAsync(x => x.Id == staffMemberId, ct);
        if (staff is null) return;

        var reviews = await db.Reviews
            .Where(x => x.StaffMemberId == staffMemberId && x.IsApproved)
            .ToListAsync(ct);

        staff.ReviewCount = reviews.Count;
        staff.AverageRating = reviews.Count == 0 ? 0 : Math.Round((decimal)reviews.Average(x => x.Rating), 2);
        staff.UpdatedAt = clock.UtcNow;
    }

    private static ReviewDto ToDto(Review review, string customerName, string? staffName) =>
        new(
            review.Id,
            review.AppointmentId,
            review.CustomerUserId,
            customerName,
            review.BarberShopId,
            review.StaffMemberId,
            staffName,
            review.Rating,
            review.Comment,
            review.IsApproved,
            review.CreatedAt);
}
