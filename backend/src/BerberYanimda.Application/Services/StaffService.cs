using BerberYanimda.Application.Common;
using BerberYanimda.Application.DTOs;
using BerberYanimda.Application.Interfaces;
using BerberYanimda.Domain;
using Microsoft.EntityFrameworkCore;

namespace BerberYanimda.Application.Services;

public sealed class StaffService(IAppDbContext db, IDateTimeProvider clock)
{
    public async Task<IReadOnlyList<OwnerAppointmentDto>> GetMyAppointmentsAsync(Guid staffUserId, AppointmentStatus? status, CancellationToken ct)
    {
        var staff = await db.StaffMembers
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.UserId == staffUserId && x.IsActive, ct)
            ?? throw new AppException("Aktif personel kaydı bulunamadı.", 404);

        var query = db.Appointments
            .AsNoTracking()
            .Include(x => x.CustomerUser)
            .Include(x => x.StaffMember)
            .Include(x => x.Services)
            .Where(x => x.StaffMemberId == staff.Id);

        if (status is not null)
        {
            query = query.Where(x => x.Status == status.Value);
        }

        return await query
            .OrderByDescending(x => x.AppointmentDate)
            .ThenByDescending(x => x.StartTime)
            .Take(100)
            .Select(x => ToOwnerAppointmentDto(x))
            .ToListAsync(ct);
    }

    public async Task<OwnerAppointmentDto> ConfirmAppointmentAsync(Guid staffUserId, Guid appointmentId, CancellationToken ct)
    {
        var staff = await db.StaffMembers
            .FirstOrDefaultAsync(x => x.UserId == staffUserId && x.IsActive, ct)
            ?? throw new AppException("Aktif personel kaydı bulunamadı.", 404);

        var appointment = await db.Appointments
            .Include(x => x.CustomerUser)
            .Include(x => x.StaffMember)
            .Include(x => x.Services)
            .FirstOrDefaultAsync(x => x.Id == appointmentId && x.StaffMemberId == staff.Id, ct)
            ?? throw new AppException("Randevu bulunamadı.", 404);

        if (appointment.Status != AppointmentStatus.Pending)
        {
            throw new AppException("Sadece bekleyen randevular onaylanabilir.", 422);
        }

        appointment.Status = AppointmentStatus.Confirmed;
        appointment.UpdatedAt = clock.UtcNow;

        db.Notifications.Add(new Notification
        {
            UserId = appointment.CustomerUserId,
            Title = "Randevunuz onaylandı",
            Message = $"{staff.FullName} randevunuzu onayladı.",
            Type = NotificationType.AppointmentConfirmed,
            CreatedAt = clock.UtcNow
        });

        db.AuditLogs.Add(new AuditLog
        {
            UserId = staffUserId,
            Action = "APPOINTMENT_CONFIRMED_BY_STAFF",
            EntityName = nameof(Appointment),
            EntityId = appointment.Id.ToString(),
            NewValue = AppointmentStatus.Confirmed.ToString(),
            CreatedAt = clock.UtcNow
        });

        await db.SaveChangesAsync(ct);
        return ToOwnerAppointmentDto(appointment);
    }

    public async Task<OwnerAppointmentDto> CompleteAppointmentAsync(Guid staffUserId, Guid appointmentId, CancellationToken ct)
    {
        var staff = await db.StaffMembers
            .FirstOrDefaultAsync(x => x.UserId == staffUserId && x.IsActive, ct)
            ?? throw new AppException("Aktif personel kaydı bulunamadı.", 404);

        var appointment = await db.Appointments
            .Include(x => x.CustomerUser)
            .Include(x => x.StaffMember)
            .Include(x => x.Services)
            .FirstOrDefaultAsync(x => x.Id == appointmentId && x.StaffMemberId == staff.Id, ct)
            ?? throw new AppException("Randevu bulunamadı.", 404);

        if (appointment.Status is not (AppointmentStatus.Confirmed or AppointmentStatus.Upcoming))
        {
            throw new AppException("Sadece onaylanmış randevular tamamlanabilir.", 422);
        }

        appointment.Status = AppointmentStatus.Completed;
        appointment.CompletedAt = clock.UtcNow;
        appointment.UpdatedAt = clock.UtcNow;

        db.AuditLogs.Add(new AuditLog
        {
            UserId = staffUserId,
            Action = "APPOINTMENT_COMPLETED_BY_STAFF",
            EntityName = nameof(Appointment),
            EntityId = appointment.Id.ToString(),
            NewValue = AppointmentStatus.Completed.ToString(),
            CreatedAt = clock.UtcNow
        });

        await db.SaveChangesAsync(ct);
        return ToOwnerAppointmentDto(appointment);
    }

    public async Task<OwnerAppointmentDto> RejectAppointmentAsync(Guid staffUserId, Guid appointmentId, string? reason, CancellationToken ct)
    {
        var staff = await db.StaffMembers
            .FirstOrDefaultAsync(x => x.UserId == staffUserId && x.IsActive, ct)
            ?? throw new AppException("Aktif personel kaydı bulunamadı.", 404);

        var appointment = await db.Appointments
            .Include(x => x.CustomerUser)
            .Include(x => x.StaffMember)
            .Include(x => x.Services)
            .FirstOrDefaultAsync(x => x.Id == appointmentId && x.StaffMemberId == staff.Id, ct)
            ?? throw new AppException("Randevu bulunamadı.", 404);

        if (appointment.Status != AppointmentStatus.Pending)
        {
            throw new AppException("Sadece bekleyen randevular reddedilebilir.", 422);
        }

        appointment.Status = AppointmentStatus.Rejected;
        appointment.CancellationReason = string.IsNullOrWhiteSpace(reason) ? null : reason.Trim();
        appointment.CancelledAt = clock.UtcNow;
        appointment.UpdatedAt = clock.UtcNow;

        db.Notifications.Add(new Notification
        {
            UserId = appointment.CustomerUserId,
            Title = "Randevunuz reddedildi",
            Message = $"{staff.FullName} randevunuzu reddetti.",
            Type = NotificationType.AppointmentCancelled,
            CreatedAt = clock.UtcNow
        });

        db.AuditLogs.Add(new AuditLog
        {
            UserId = staffUserId,
            Action = "APPOINTMENT_REJECTED_BY_STAFF",
            EntityName = nameof(Appointment),
            EntityId = appointment.Id.ToString(),
            NewValue = AppointmentStatus.Rejected.ToString(),
            CreatedAt = clock.UtcNow
        });

        await db.SaveChangesAsync(ct);
        return ToOwnerAppointmentDto(appointment);
    }

    private static OwnerAppointmentDto ToOwnerAppointmentDto(Appointment appointment) =>
        new(
            appointment.Id,
            appointment.CustomerUserId,
            appointment.CustomerUser?.FullName ?? "Bilinmeyen",
            appointment.CustomerUser?.PhoneNumber,
            appointment.StaffMemberId,
            appointment.StaffMember?.FullName,
            appointment.AppointmentDate,
            appointment.StartTime.ToString("HH:mm"),
            appointment.EndTime.ToString("HH:mm"),
            appointment.TotalDurationMinutes,
            appointment.TotalPrice,
            appointment.Status.ToString(),
            appointment.Services.Select(x => new AppointmentServiceDto(x.BarberServiceId, x.ServiceName, x.DurationMinutes, x.Price)).ToList(),
            appointment.CustomerNote);
}
