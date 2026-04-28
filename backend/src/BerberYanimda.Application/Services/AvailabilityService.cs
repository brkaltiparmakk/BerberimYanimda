using BerberYanimda.Application.Common;
using BerberYanimda.Application.DTOs;
using BerberYanimda.Application.Interfaces;
using BerberYanimda.Domain;
using Microsoft.EntityFrameworkCore;

namespace BerberYanimda.Application.Services;

public sealed class AvailabilityService(IAppDbContext db, IDateTimeProvider clock)
{
    private static readonly AppointmentStatus[] BlockingStatuses =
    [
        AppointmentStatus.Pending,
        AppointmentStatus.Confirmed,
        AppointmentStatus.Upcoming
    ];

    public async Task<IReadOnlyList<AvailabilitySlotDto>> GetSlotsAsync(
        Guid barberShopId,
        Guid? staffMemberId,
        IReadOnlyList<Guid> serviceIds,
        DateOnly date,
        CancellationToken ct)
    {
        var totalDuration = await ValidateSelectionAsync(barberShopId, staffMemberId, serviceIds, date, ct);
        var workingHour = await ResolveWorkingHourAsync(barberShopId, staffMemberId, date, ct)
            ?? throw new AppException("Seçilen gün için çalışma saati bulunamadı.", 404);

        var breaks = staffMemberId is null
            ? []
            : await db.StaffBreaks.AsNoTracking()
                .Where(x => x.StaffMemberId == staffMemberId.Value && x.BreakDate == date)
                .ToListAsync(ct);

        var appointments = await db.Appointments.AsNoTracking()
            .Where(x =>
                x.BarberShopId == barberShopId &&
                x.AppointmentDate == date &&
                x.StaffMemberId == staffMemberId &&
                BlockingStatuses.Contains(x.Status))
            .ToListAsync(ct);

        var slots = new List<AvailabilitySlotDto>();
        var cursor = workingHour.StartTime;
        while (cursor.AddMinutes(totalDuration) <= workingHour.EndTime)
        {
            var end = cursor.AddMinutes(totalDuration);
            var isPast = date == clock.Today && cursor <= TimeOnly.FromDateTime(clock.UtcNow.ToLocalTime());
            var inBreak = breaks.Any(x => Overlaps(cursor, end, x.StartTime, x.EndTime));
            var hasConflict = appointments.Any(x => Overlaps(cursor, end, x.StartTime, x.EndTime));

            slots.Add(new AvailabilitySlotDto(
                cursor.ToString("HH:mm"),
                end.ToString("HH:mm"),
                !isPast && !inBreak && !hasConflict));

            cursor = cursor.AddMinutes(15);
        }

        return slots;
    }

    internal async Task<int> ValidateSelectionAsync(
        Guid barberShopId,
        Guid? staffMemberId,
        IReadOnlyList<Guid> serviceIds,
        DateOnly date,
        CancellationToken ct)
    {
        if (date < clock.Today)
        {
            throw new AppException("Geçmiş tarihe randevu oluşturulamaz.", 422);
        }

        if (serviceIds.Count == 0)
        {
            throw new AppException("En az bir hizmet seçilmelidir.", 422);
        }

        var shopExists = await db.BarberShops.AnyAsync(x => x.Id == barberShopId && x.IsActive && x.IsApproved, ct);
        if (!shopExists)
        {
            throw new AppException("Berber aktif veya onaylı değil.", 404);
        }

        var services = await db.BarberServices
            .Where(x => serviceIds.Contains(x.Id) && x.BarberShopId == barberShopId && x.IsActive)
            .ToListAsync(ct);

        if (services.Count != serviceIds.Distinct().Count())
        {
            throw new AppException("Seçilen hizmetlerden biri aktif değil veya bu berbere ait değil.", 422);
        }

        if (staffMemberId is not null)
        {
            var staff = await db.StaffMembers
                .Include(x => x.StaffServices)
                .FirstOrDefaultAsync(x => x.Id == staffMemberId.Value && x.BarberShopId == barberShopId && x.IsActive, ct)
                ?? throw new AppException("Personel aktif değil veya bulunamadı.", 422);

            var staffServiceIds = staff.StaffServices.Select(x => x.BarberServiceId).ToHashSet();
            if (services.Any(x => !staffServiceIds.Contains(x.Id)))
            {
                throw new AppException("Seçilen personel bu hizmetlerin tamamını veremiyor.", 422);
            }
        }

        return services.Sum(x => x.DurationMinutes);
    }

    internal async Task<WorkingHour?> ResolveWorkingHourAsync(Guid barberShopId, Guid? staffMemberId, DateOnly date, CancellationToken ct)
    {
        var day = ToBusinessDay(date.DayOfWeek);
        var query = db.WorkingHours.AsNoTracking()
            .Where(x => x.BarberShopId == barberShopId && x.DayOfWeek == day && !x.IsClosed);

        var staffHour = staffMemberId is null
            ? null
            : await query.FirstOrDefaultAsync(x => x.StaffMemberId == staffMemberId.Value, ct);

        return staffHour ?? await query.FirstOrDefaultAsync(x => x.StaffMemberId == null, ct);
    }

    internal async Task EnsureSlotAvailableAsync(
        Guid barberShopId,
        Guid? staffMemberId,
        DateOnly date,
        TimeOnly start,
        TimeOnly end,
        CancellationToken ct)
    {
        var workingHour = await ResolveWorkingHourAsync(barberShopId, staffMemberId, date, ct)
            ?? throw new AppException("Çalışma saati bulunamadı.", 422);

        if (start < workingHour.StartTime || end > workingHour.EndTime)
        {
            throw new AppException("Seçilen saat çalışma saatleri dışında.", 422);
        }

        if (staffMemberId is not null)
        {
            var hasBreak = await db.StaffBreaks.AnyAsync(x =>
                x.StaffMemberId == staffMemberId.Value &&
                x.BreakDate == date &&
                start < x.EndTime &&
                end > x.StartTime, ct);

            if (hasBreak)
            {
                throw new AppException("Seçilen saat personel molası ile çakışıyor.", 409);
            }
        }

        var hasConflict = await db.Appointments.AnyAsync(x =>
            x.BarberShopId == barberShopId &&
            x.StaffMemberId == staffMemberId &&
            x.AppointmentDate == date &&
            BlockingStatuses.Contains(x.Status) &&
            start < x.EndTime &&
            end > x.StartTime, ct);

        if (hasConflict)
        {
            throw new AppException("Seçilen saat uygun değil.", 409);
        }
    }

    private static bool Overlaps(TimeOnly start, TimeOnly end, TimeOnly existingStart, TimeOnly existingEnd) =>
        start < existingEnd && end > existingStart;

    private static int ToBusinessDay(DayOfWeek day) => day == DayOfWeek.Sunday ? 7 : (int)day;
}
