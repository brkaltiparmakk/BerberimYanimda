using BerberYanimda.Application.Common;
using BerberYanimda.Application.DTOs;
using BerberYanimda.Application.Interfaces;
using BerberYanimda.Domain;
using Microsoft.EntityFrameworkCore;

namespace BerberYanimda.Application.Services;

public sealed class UserService(IAppDbContext db, IPasswordService passwordService, IDateTimeProvider clock)
{
    public async Task<UserProfileDto> GetMeAsync(Guid userId, CancellationToken ct)
    {
        var user = await db.Users.FirstOrDefaultAsync(x => x.Id == userId && x.IsActive, ct)
            ?? throw new AppException("Kullanıcı bulunamadı.", 404);

        return new UserProfileDto(user.Id, user.FullName, user.PhoneNumber, user.Email, user.ProfileImageUrl, user.BirthDate, user.Role, user.IsPhoneVerified);
    }

    public async Task<UserProfileDto> UpdateMeAsync(Guid userId, UpdateProfileRequest request, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(request.FullName))
        {
            throw new AppException("Ad soyad zorunludur.", 422);
        }

        var user = await db.Users.FirstOrDefaultAsync(x => x.Id == userId && x.IsActive, ct)
            ?? throw new AppException("Kullanıcı bulunamadı.", 404);

        user.FullName = request.FullName.Trim();
        user.Email = string.IsNullOrWhiteSpace(request.Email) ? null : request.Email.Trim();
        user.BirthDate = request.BirthDate;
        user.UpdatedAt = clock.UtcNow;
        await db.SaveChangesAsync(ct);

        return new UserProfileDto(user.Id, user.FullName, user.PhoneNumber, user.Email, user.ProfileImageUrl, user.BirthDate, user.Role, user.IsPhoneVerified);
    }

    public async Task<UserProfileDto> UpdateProfileImageAsync(Guid userId, string imageUrl, CancellationToken ct)
    {
        var user = await db.Users.FirstOrDefaultAsync(x => x.Id == userId && x.IsActive, ct)
            ?? throw new AppException("Kullanıcı bulunamadı.", 404);

        user.ProfileImageUrl = imageUrl;
        user.UpdatedAt = clock.UtcNow;
        await db.SaveChangesAsync(ct);
        return new UserProfileDto(user.Id, user.FullName, user.PhoneNumber, user.Email, user.ProfileImageUrl, user.BirthDate, user.Role, user.IsPhoneVerified);
    }

    public async Task ChangePasswordAsync(Guid userId, ChangePasswordRequest request, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(request.CurrentPassword) || string.IsNullOrWhiteSpace(request.NewPassword))
        {
            throw new AppException("Mevcut şifre ve yeni şifre zorunludur.", 422);
        }

        if (request.NewPassword.Length < 8)
        {
            throw new AppException("Yeni şifre minimum 8 karakter olmalıdır.", 422);
        }

        var user = await db.Users.FirstOrDefaultAsync(x => x.Id == userId && x.IsActive, ct)
            ?? throw new AppException("Kullanıcı bulunamadı.", 404);

        if (!passwordService.VerifyPassword(user, request.CurrentPassword))
        {
            throw new AppException("Mevcut şifre hatalı.", 422);
        }

        user.PasswordHash = passwordService.HashPassword(user, request.NewPassword);
        user.UpdatedAt = clock.UtcNow;

        var userTokens = await db.RefreshTokens
            .Where(x => x.UserId == userId && x.RevokedAt == null)
            .ToListAsync(ct);

        foreach (var token in userTokens)
        {
            token.RevokedAt = clock.UtcNow;
        }

        await db.SaveChangesAsync(ct);
    }

    public async Task RequestAccountDeletionAsync(Guid userId, DeleteAccountRequest request, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(request.Password))
        {
            throw new AppException("Hesap silme için şifrenizi girmelisiniz.", 422);
        }

        var user = await db.Users.FirstOrDefaultAsync(x => x.Id == userId && x.IsActive, ct)
            ?? throw new AppException("Kullanıcı bulunamadı.", 404);

        if (!passwordService.VerifyPassword(user, request.Password))
        {
            throw new AppException("Şifre hatalı.", 422);
        }

        var hasActiveAppointments = await db.Appointments
            .AnyAsync(x => x.CustomerUserId == userId &&
                (x.Status == AppointmentStatus.Pending ||
                 x.Status == AppointmentStatus.Confirmed ||
                 x.Status == AppointmentStatus.Upcoming), ct);

        if (hasActiveAppointments)
        {
            throw new AppException("Aktif randevularınız bulunduğu için hesap silinemez. Önce randevularınızı iptal edin.", 422);
        }

        // Anonimleştirme
        var oldPhone = user.PhoneNumber;
        user.FullName = "Silinmiş Kullanıcı";
        user.PhoneNumber = $"DELETED-{userId:N}";
        user.Email = $"deleted-{userId:N}@anonim.berberyanimda";
        user.PasswordHash = null;
        user.ProfileImageUrl = null;
        user.BirthDate = null;
        user.MfaSecret = null;
        user.MfaEnabled = false;
        user.MfaVerifiedAt = null;
        user.IsActive = false;
        user.DeletedAt = clock.UtcNow;
        user.UpdatedAt = clock.UtcNow;

        var userTokens = await db.RefreshTokens
            .Where(x => x.UserId == userId && x.RevokedAt == null)
            .ToListAsync(ct);

        foreach (var token in userTokens)
        {
            token.RevokedAt = clock.UtcNow;
        }

        var deviceTokens = await db.DeviceTokens
            .Where(x => x.UserId == userId)
            .ToListAsync(ct);
        db.DeviceTokens.RemoveRange(deviceTokens);

        var favorites = await db.FavoriteBarberShops
            .Where(x => x.UserId == userId)
            .ToListAsync(ct);
        db.FavoriteBarberShops.RemoveRange(favorites);

        db.AuditLogs.Add(new AuditLog
        {
            UserId = userId,
            Action = "ACCOUNT_DELETION_REQUESTED",
            EntityName = nameof(User),
            EntityId = userId.ToString(),
            OldValue = $"Phone:{oldPhone}",
            CreatedAt = clock.UtcNow
        });

        await db.SaveChangesAsync(ct);
    }

    public async Task<UserDataExportDto> ExportUserDataAsync(Guid userId, CancellationToken ct)
    {
        var user = await db.Users.FirstOrDefaultAsync(x => x.Id == userId, ct)
            ?? throw new AppException("Kullanıcı bulunamadı.", 404);

        var appointments = await db.Appointments
            .AsNoTracking()
            .Include(x => x.BarberShop)
            .Include(x => x.Services)
            .Where(x => x.CustomerUserId == userId)
            .OrderByDescending(x => x.CreatedAt)
            .ToListAsync(ct);

        var payments = await db.Payments
            .AsNoTracking()
            .Where(x => x.CustomerUserId == userId)
            .OrderByDescending(x => x.CreatedAt)
            .ToListAsync(ct);

        var reviews = await db.Reviews
            .AsNoTracking()
            .Where(x => x.CustomerUserId == userId)
            .OrderByDescending(x => x.CreatedAt)
            .ToListAsync(ct);

        return new UserDataExportDto(
            UserProfile: new UserProfileDto(user.Id, user.FullName, user.PhoneNumber, user.Email, user.ProfileImageUrl, user.BirthDate, user.Role, user.IsPhoneVerified),
            CreatedAt: user.CreatedAt,
            Appointments: appointments.Select(a => new AppointmentDto(
                a.Id, a.BarberShopId, a.BarberShop?.Name ?? "", a.BarberShop?.CoverImageUrl,
                a.BarberShop?.PhoneNumber, a.BarberShop?.Address, a.BarberShop?.Latitude, a.BarberShop?.Longitude,
                a.StaffMemberId, null, a.AppointmentDate, a.StartTime.ToString("HH:mm"),
                a.EndTime.ToString("HH:mm"), a.TotalDurationMinutes, a.TotalPrice, a.Status,
                a.Services.Select(s => new AppointmentServiceDto(s.BarberServiceId, s.ServiceName, s.DurationMinutes, s.Price)).ToList(),
                a.CustomerNote, a.CustomerUser?.FullName, a.RejectionReason)).ToList(),
            Payments: payments.Select(p => new PaymentDto(p.Id, p.AppointmentId, p.PaymentMethod, p.Status, p.Amount, p.Currency)).ToList(),
            Reviews: reviews.Select(r => new ReviewDto(r.Id, r.AppointmentId, r.CustomerUserId, "", r.BarberShopId, r.StaffMemberId, null, r.Rating, r.Comment, r.IsApproved, r.CreatedAt)).ToList());
    }
}
