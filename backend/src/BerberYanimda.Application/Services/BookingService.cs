using BerberYanimda.Application.Common;
using BerberYanimda.Application.DTOs;
using BerberYanimda.Application.Interfaces;
using BerberYanimda.Domain;
using Microsoft.EntityFrameworkCore;

namespace BerberYanimda.Application.Services;

public sealed class BookingService(
    IAppDbContext db,
    AvailabilityService availabilityService,
    IDateTimeProvider clock,
    IAuditLogService auditLog,
    IPushNotificationService push)
{
    public async Task<AppointmentDto> CreateAsync(Guid customerUserId, CreateAppointmentRequest request, CancellationToken ct)
    {
        var customer = await db.Users.FirstOrDefaultAsync(x => x.Id == customerUserId && x.IsActive, ct)
            ?? throw new AppException("Kullanıcı bulunamadı.", 404);

        if (!customer.IsPhoneVerified)
        {
            throw new AppException("Randevu oluşturmak için telefon doğrulaması gereklidir.", 403);
        }

        await using var transaction = await db.Database.BeginTransactionAsync(ct);

        try
        {
            var totalDuration = await availabilityService.ValidateSelectionAsync(
                request.BarberShopId,
                request.StaffMemberId,
                request.ServiceIds,
                request.AppointmentDate,
                ct);

            var start = request.StartTime;
            var end = start.AddMinutes(totalDuration);
            await availabilityService.EnsureSlotAvailableAsync(request.BarberShopId, request.StaffMemberId, request.AppointmentDate, start, end, ct);

            var services = await db.BarberServices
                .Where(x => request.ServiceIds.Contains(x.Id) && x.BarberShopId == request.BarberShopId && x.IsActive)
                .ToListAsync(ct);

            var shop = await db.BarberShops.FirstAsync(x => x.Id == request.BarberShopId, ct);
            var staff = request.StaffMemberId is null
                ? null
                : await db.StaffMembers.FirstOrDefaultAsync(x => x.Id == request.StaffMemberId.Value, ct);

            var appointment = new Appointment
            {
                CustomerUserId = customerUserId,
                BarberShopId = request.BarberShopId,
                StaffMemberId = request.StaffMemberId,
                AppointmentDate = request.AppointmentDate,
                StartTime = start,
                EndTime = end,
                TotalDurationMinutes = totalDuration,
                TotalPrice = services.Sum(x => x.Price),
                Status = AppointmentStatus.Pending,
                CustomerNote = string.IsNullOrWhiteSpace(request.CustomerNote) ? null : request.CustomerNote.Trim(),
                CreatedAt = clock.UtcNow,
                Services = services.Select(x => new AppointmentService
                {
                    BarberServiceId = x.Id,
                    ServiceName = x.Name,
                    DurationMinutes = x.DurationMinutes,
                    Price = x.Price
                }).ToList()
            };

            db.Appointments.Add(appointment);
            db.Notifications.Add(new Notification
            {
                UserId = shop.OwnerUserId,
                Title = "Yeni randevu",
                Message = $"{customer.FullName}, {request.AppointmentDate:yyyy-MM-dd} {start:HH:mm} için randevu oluşturdu.",
                Type = NotificationType.System,
                CreatedAt = clock.UtcNow
            });

            await db.SaveChangesAsync(ct);
            await transaction.CommitAsync(ct);

            await push.SendToUserAsync(shop.OwnerUserId, "Yeni randevu",
                $"{customer.FullName}, {request.AppointmentDate:yyyy-MM-dd} {start:HH:mm} için randevu oluşturdu.",
                new Dictionary<string, string> { ["type"] = "AppointmentCreated", ["appointmentId"] = appointment.Id.ToString() }, ct);
            return ToDto(appointment, shop, staff);
        }
        catch
        {
            await transaction.RollbackAsync(ct);
            throw;
        }
    }

    public async Task<IReadOnlyList<AppointmentDto>> GetMineAsync(Guid userId, UserRole role, AppointmentStatus? status, CancellationToken ct)
    {
        var query = db.Appointments
            .AsNoTracking()
            .Include(x => x.BarberShop)
            .Include(x => x.StaffMember)
            .Include(x => x.Services)
            .AsQueryable();

        query = role switch
        {
            UserRole.Admin => query,
            UserRole.BarberOwner => query.Where(x => x.BarberShop != null && x.BarberShop.OwnerUserId == userId),
            UserRole.Staff => query.Where(x => x.StaffMember != null && x.StaffMember.UserId == userId),
            _ => query.Where(x => x.CustomerUserId == userId)
        };

        if (status is not null)
        {
            query = query.Where(x => x.Status == status.Value);
        }

        return await query
            .OrderByDescending(x => x.AppointmentDate)
            .ThenByDescending(x => x.StartTime)
            .Take(100)
            .Select(x => ToDto(x, x.BarberShop!, x.StaffMember))
            .ToListAsync(ct);
    }

    public async Task<AppointmentDto> GetByIdAsync(Guid appointmentId, Guid userId, UserRole role, CancellationToken ct)
    {
        var appointment = await db.Appointments
            .AsNoTracking()
            .Include(x => x.BarberShop)
            .Include(x => x.StaffMember)
            .Include(x => x.Services)
            .FirstOrDefaultAsync(x => x.Id == appointmentId, ct)
            ?? throw new AppException("Randevu bulunamadı.", 404);

        EnsureCanAccess(appointment, userId, role);
        return ToDto(appointment, appointment.BarberShop!, appointment.StaffMember);
    }

    public async Task<AppointmentDto> CancelAsync(Guid appointmentId, Guid userId, UserRole role, CancelAppointmentRequest request, CancellationToken ct)
    {
        var appointment = await db.Appointments
            .Include(x => x.BarberShop)
            .Include(x => x.StaffMember)
            .Include(x => x.Services)
            .FirstOrDefaultAsync(x => x.Id == appointmentId, ct)
            ?? throw new AppException("Randevu bulunamadı.", 404);

        EnsureCanAccess(appointment, userId, role);

        if (appointment.Status is AppointmentStatus.Cancelled or AppointmentStatus.Completed)
        {
            throw new AppException("Bu randevu iptal edilemez.", 409);
        }

        var appointmentStart = appointment.AppointmentDate.ToDateTime(appointment.StartTime);
        if (role == UserRole.Customer && appointmentStart <= clock.UtcNow.AddHours(2))
        {
            throw new AppException("Randevu başlangıcına 2 saatten az kaldığı için iptal edilemez.", 409);
        }

        var wasStatus = appointment.Status;
        appointment.Status = AppointmentStatus.Cancelled;
        appointment.CancellationReason = string.IsNullOrWhiteSpace(request.Reason) ? null : request.Reason.Trim();
        appointment.CancelledAt = clock.UtcNow;
        appointment.UpdatedAt = clock.UtcNow;
        db.Notifications.Add(new Notification
        {
            UserId = appointment.CustomerUserId,
            Title = "Randevu iptal edildi",
            Message = $"{appointment.BarberShop?.Name} randevunuz iptal edildi.",
            Type = NotificationType.AppointmentCancelled,
            CreatedAt = clock.UtcNow
        });

        await db.SaveChangesAsync(ct);
        await auditLog.LogAsync(userId, "APPOINTMENT_CANCELLED", nameof(Appointment), appointment.Id.ToString(),
            oldValue: wasStatus.ToString(), newValue: $"Cancelled:{appointment.CancellationReason}", ct: ct);

        if (role == UserRole.Customer)
        {
            await push.SendToUserAsync(appointment.BarberShop!.OwnerUserId, "Randevu iptal edildi",
                $"{appointment.CustomerUser?.FullName} randevusunu iptal etti.",
                new Dictionary<string, string> { ["type"] = "AppointmentCancelled", ["appointmentId"] = appointment.Id.ToString() }, ct);
        }
        else
        {
            await push.SendToUserAsync(appointment.CustomerUserId, "Randevu iptal edildi",
                $"{appointment.BarberShop?.Name} randevunuz iptal edildi.",
                new Dictionary<string, string> { ["type"] = "AppointmentCancelled", ["appointmentId"] = appointment.Id.ToString() }, ct);
        }
        return ToDto(appointment, appointment.BarberShop!, appointment.StaffMember);
    }

    private static void EnsureCanAccess(Appointment appointment, Guid userId, UserRole role)
    {
        var allowed = role switch
        {
            UserRole.Admin => true,
            UserRole.BarberOwner => appointment.BarberShop?.OwnerUserId == userId,
            UserRole.Staff => appointment.StaffMember?.UserId == userId,
            _ => appointment.CustomerUserId == userId
        };

        if (!allowed)
        {
            throw new AppException("Bu kayda erişim yetkiniz yok.", 403);
        }
    }

    public async Task<AppointmentDto> ConfirmAsync(Guid appointmentId, Guid userId, UserRole role, CancellationToken ct)
    {
        await using var transaction = await db.Database.BeginTransactionAsync(ct);

        try
        {
            var appointment = await db.Appointments
                .Include(x => x.BarberShop)
                .Include(x => x.StaffMember)
                .Include(x => x.CustomerUser)
                .Include(x => x.Services)
                .FirstOrDefaultAsync(x => x.Id == appointmentId, ct)
                ?? throw new AppException("Randevu bulunamadı.", 404);

            EnsureCanAccess(appointment, userId, role);
            if (role == UserRole.Customer)
            {
                throw new AppException("Bu işlemi yapma yetkiniz yok.", 403);
            }
            EnsureValidTransition(appointment.Status, AppointmentStatus.Confirmed);

            appointment.Status = AppointmentStatus.Confirmed;
            appointment.UpdatedAt = clock.UtcNow;

            db.Notifications.Add(new Notification
            {
                UserId = appointment.CustomerUserId,
                Title = "Randevunuz onaylandı",
                Message = $"{appointment.BarberShop?.Name} randevunuz onaylandı.",
                Type = NotificationType.AppointmentConfirmed,
                CreatedAt = clock.UtcNow
            });

            await db.SaveChangesAsync(ct);
            await transaction.CommitAsync(ct);

            await auditLog.LogAsync(userId, "APPOINTMENT_CONFIRMED", nameof(Appointment), appointment.Id.ToString(),
                oldValue: "Pending", newValue: "Confirmed", ct: ct);

            await push.SendToUserAsync(appointment.CustomerUserId, "Randevunuz onaylandı",
                $"{appointment.BarberShop?.Name} randevunuz onaylandı.",
                new Dictionary<string, string> { ["type"] = "AppointmentConfirmed", ["appointmentId"] = appointment.Id.ToString() }, ct);
            return ToDto(appointment, appointment.BarberShop!, appointment.StaffMember);
        }
        catch
        {
            await transaction.RollbackAsync(ct);
            throw;
        }
    }

    public async Task<AppointmentDto> CompleteAsync(Guid appointmentId, Guid userId, UserRole role, CancellationToken ct)
    {
        await using var transaction = await db.Database.BeginTransactionAsync(ct);

        try
        {
            var appointment = await db.Appointments
                .Include(x => x.BarberShop)
                .Include(x => x.StaffMember)
                .Include(x => x.CustomerUser)
                .Include(x => x.Services)
                .FirstOrDefaultAsync(x => x.Id == appointmentId, ct)
                ?? throw new AppException("Randevu bulunamadı.", 404);

            EnsureCanAccess(appointment, userId, role);
            if (role == UserRole.Customer)
            {
                throw new AppException("Bu işlemi yapma yetkiniz yok.", 403);
            }
            EnsureValidTransition(appointment.Status, AppointmentStatus.Completed);

            appointment.Status = AppointmentStatus.Completed;
            appointment.CompletedAt = clock.UtcNow;
            appointment.UpdatedAt = clock.UtcNow;

            db.Notifications.Add(new Notification
            {
                UserId = appointment.CustomerUserId,
                Title = "Randevunuz tamamlandı",
                Message = $"{appointment.BarberShop?.Name} randevunuz tamamlandı. Bizi değerlendirmeyi unutmayın!",
                Type = NotificationType.System,
                CreatedAt = clock.UtcNow
            });

            await db.SaveChangesAsync(ct);
            await transaction.CommitAsync(ct);

            await auditLog.LogAsync(userId, "APPOINTMENT_COMPLETED", nameof(Appointment), appointment.Id.ToString(),
                oldValue: "Confirmed", newValue: "Completed", ct: ct);

            await push.SendToUserAsync(appointment.CustomerUserId, "Randevunuz tamamlandı",
                $"{appointment.BarberShop?.Name} randevunuz tamamlandı. Bizi değerlendirmeyi unutmayın!",
                new Dictionary<string, string> { ["type"] = "AppointmentCompleted", ["appointmentId"] = appointment.Id.ToString() }, ct);
            return ToDto(appointment, appointment.BarberShop!, appointment.StaffMember);
        }
        catch
        {
            await transaction.RollbackAsync(ct);
            throw;
        }
    }

    public async Task<AppointmentDto> RejectAsync(Guid appointmentId, Guid userId, UserRole role, RejectAppointmentRequest request, CancellationToken ct)
    {
        await using var transaction = await db.Database.BeginTransactionAsync(ct);

        try
        {
            var appointment = await db.Appointments
                .Include(x => x.BarberShop)
                .Include(x => x.StaffMember)
                .Include(x => x.CustomerUser)
                .Include(x => x.Services)
                .FirstOrDefaultAsync(x => x.Id == appointmentId, ct)
                ?? throw new AppException("Randevu bulunamadı.", 404);

            EnsureCanAccess(appointment, userId, role);
            if (role == UserRole.Customer)
            {
                throw new AppException("Bu işlemi yapma yetkiniz yok.", 403);
            }
            EnsureValidTransition(appointment.Status, AppointmentStatus.Rejected);

            appointment.Status = AppointmentStatus.Rejected;
            appointment.RejectionReason = string.IsNullOrWhiteSpace(request.Reason) ? null : request.Reason.Trim();
            appointment.RejectedAt = clock.UtcNow;
            appointment.UpdatedAt = clock.UtcNow;

            db.Notifications.Add(new Notification
            {
                UserId = appointment.CustomerUserId,
                Title = "Randevunuz reddedildi",
                Message = $"{appointment.BarberShop?.Name} randevunuz reddedildi.{(appointment.RejectionReason != null ? " Sebep: " + appointment.RejectionReason : "")}",
                Type = NotificationType.AppointmentRejected,
                CreatedAt = clock.UtcNow
            });

            await db.SaveChangesAsync(ct);
            await transaction.CommitAsync(ct);

            await auditLog.LogAsync(userId, "APPOINTMENT_REJECTED", nameof(Appointment), appointment.Id.ToString(),
                oldValue: "Pending", newValue: $"Rejected:{appointment.RejectionReason}", ct: ct);

            await push.SendToUserAsync(appointment.CustomerUserId, "Randevunuz reddedildi",
                $"{appointment.BarberShop?.Name} randevunuz reddedildi.{(appointment.RejectionReason != null ? " Sebep: " + appointment.RejectionReason : "")}",
                new Dictionary<string, string> { ["type"] = "AppointmentRejected", ["appointmentId"] = appointment.Id.ToString() }, ct);
            return ToDto(appointment, appointment.BarberShop!, appointment.StaffMember);
        }
        catch
        {
            await transaction.RollbackAsync(ct);
            throw;
        }
    }

    public async Task<PagedResponse<AppointmentDto>> GetShopAppointmentsAsync(Guid userId, UserRole role, ShopAppointmentsQuery queryDto, CancellationToken ct)
    {
        if (role is not (UserRole.BarberOwner or UserRole.Staff or UserRole.Admin))
        {
            throw new AppException("Bu kaynağa erişim yetkiniz yok.", 403);
        }

        var query = db.Appointments
            .AsNoTracking()
            .Include(x => x.BarberShop)
            .Include(x => x.StaffMember)
            .Include(x => x.CustomerUser)
            .Include(x => x.Services)
            .AsQueryable();

        query = role switch
        {
            UserRole.Admin => query,
            UserRole.BarberOwner => query.Where(x => x.BarberShop != null && x.BarberShop.OwnerUserId == userId),
            UserRole.Staff => query.Where(x => x.StaffMember != null && x.StaffMember.UserId == userId),
            _ => query.Where(x => x.CustomerUserId == userId)
        };

        if (queryDto.Date.HasValue)
        {
            query = query.Where(x => x.AppointmentDate == queryDto.Date.Value);
        }

        if (queryDto.Status.HasValue)
        {
            query = query.Where(x => x.Status == queryDto.Status.Value);
        }

        var totalCount = await query.CountAsync(ct);
        var items = await query
            .OrderBy(x => x.AppointmentDate)
            .ThenBy(x => x.StartTime)
            .Skip((queryDto.Page - 1) * queryDto.PageSize)
            .Take(queryDto.PageSize)
            .Select(x => ToDto(x, x.BarberShop!, x.StaffMember))
            .ToListAsync(ct);

        return new PagedResponse<AppointmentDto>
        {
            Items = items,
            Page = queryDto.Page,
            PageSize = queryDto.PageSize,
            TotalCount = totalCount,
            TotalPages = (int)Math.Ceiling((double)totalCount / queryDto.PageSize)
        };
    }

    private static void EnsureValidTransition(AppointmentStatus current, AppointmentStatus next)
    {
        var valid = (current, next) switch
        {
            (AppointmentStatus.Pending, AppointmentStatus.Confirmed) => true,
            (AppointmentStatus.Pending, AppointmentStatus.Rejected) => true,
            (AppointmentStatus.Confirmed, AppointmentStatus.Completed) => true,
            (AppointmentStatus.Confirmed, AppointmentStatus.Cancelled) => true,
            _ => false
        };

        if (!valid)
        {
            throw new AppException($"Geçersiz durum geçişi: {current} → {next}", 409);
        }
    }

    private static AppointmentDto ToDto(Appointment appointment, BarberShop shop, StaffMember? staff) =>
        new(
            appointment.Id,
            shop.Id,
            shop.Name,
            shop.CoverImageUrl,
            shop.PhoneNumber,
            shop.Address,
            shop.Latitude,
            shop.Longitude,
            staff?.Id,
            staff?.FullName,
            appointment.AppointmentDate,
            appointment.StartTime.ToString("HH:mm"),
            appointment.EndTime.ToString("HH:mm"),
            appointment.TotalDurationMinutes,
            appointment.TotalPrice,
            appointment.Status,
            appointment.Services.Select(x => new AppointmentServiceDto(x.BarberServiceId, x.ServiceName, x.DurationMinutes, x.Price)).ToList(),
            appointment.CustomerNote,
            appointment.CustomerUser?.FullName,
            appointment.RejectionReason);
}
