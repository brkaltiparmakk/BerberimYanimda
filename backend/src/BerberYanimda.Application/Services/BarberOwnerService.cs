using BerberYanimda.Application.Common;
using BerberYanimda.Application.DTOs;
using BerberYanimda.Application.Interfaces;
using BerberYanimda.Domain;
using Microsoft.EntityFrameworkCore;

namespace BerberYanimda.Application.Services;

public sealed class BarberOwnerService(IAppDbContext db, IDateTimeProvider clock, IAuditLogService auditLog, BookingService bookingService)
{
    private async Task<BarberShop> GetShopForOwnerAsync(Guid ownerId, CancellationToken ct)
    {
        return await db.BarberShops
            .FirstOrDefaultAsync(x => x.OwnerUserId == ownerId && x.IsActive, ct)
            ?? throw new AppException("Aktif berber dükkanı bulunamadı.", 404);
    }

    public async Task<BarberShopDetailDto?> GetMyShopAsync(Guid ownerId, CancellationToken ct)
    {
        var shop = await db.BarberShops
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.OwnerUserId == ownerId && x.IsActive, ct);

        if (shop is null) return null;

        return ToShopDetailDto(shop);
    }

    public async Task<BarberShopDetailDto> CreateShopAsync(Guid ownerId, CreateBarberShopRequest request, CancellationToken ct)
    {
        var existingShop = await db.BarberShops
            .AnyAsync(x => x.OwnerUserId == ownerId && x.IsActive, ct);

        if (existingShop)
        {
            throw new AppException("Zaten aktif bir berber dükkanınız var.", 409);
        }

        if (string.IsNullOrWhiteSpace(request.Name))
        {
            throw new AppException("Dükkan adı zorunludur.", 422);
        }

        if (string.IsNullOrWhiteSpace(request.City) || string.IsNullOrWhiteSpace(request.District))
        {
            throw new AppException("İl ve ilçe bilgileri zorunludur.", 422);
        }

        var shop = new BarberShop
        {
            OwnerUserId = ownerId,
            Name = request.Name.Trim(),
            Description = string.IsNullOrWhiteSpace(request.Description) ? null : request.Description.Trim(),
            PhoneNumber = request.PhoneNumber?.Trim(),
            City = request.City.Trim(),
            District = request.District.Trim(),
            Address = request.Address?.Trim() ?? string.Empty,
            Latitude = request.Latitude,
            Longitude = request.Longitude,
            IsApproved = false,
            IsActive = true,
            CreatedAt = clock.UtcNow
        };

        db.BarberShops.Add(shop);

        var defaultWorkingHours = CreateDefaultWorkingHours(shop.Id);
        db.WorkingHours.AddRange(defaultWorkingHours);

        await db.SaveChangesAsync(ct);
        return ToShopDetailDto(shop);
    }

    public async Task<BarberShopDetailDto> UpdateShopAsync(Guid ownerId, UpdateBarberShopRequest request, CancellationToken ct)
    {
        var shop = await GetShopForOwnerAsync(ownerId, ct);

        if (string.IsNullOrWhiteSpace(request.Name))
        {
            throw new AppException("Dükkan adı zorunludur.", 422);
        }

        shop.Name = request.Name.Trim();
        shop.Description = string.IsNullOrWhiteSpace(request.Description) ? null : request.Description.Trim();
        shop.PhoneNumber = request.PhoneNumber?.Trim();
        shop.City = request.City?.Trim() ?? shop.City;
        shop.District = request.District?.Trim() ?? shop.District;
        shop.Address = request.Address?.Trim() ?? shop.Address;
        shop.Latitude = request.Latitude;
        shop.Longitude = request.Longitude;
        shop.UpdatedAt = clock.UtcNow;

        await db.SaveChangesAsync(ct);
        return ToShopDetailDto(shop);
    }

    public async Task<IReadOnlyList<OwnerServiceDto>> GetServicesAsync(Guid ownerId, CancellationToken ct)
    {
        var shop = await GetShopForOwnerAsync(ownerId, ct);

        return await db.BarberServices
            .AsNoTracking()
            .Where(x => x.BarberShopId == shop.Id)
            .OrderBy(x => x.Name)
            .Select(x => ToOwnerServiceDto(x))
            .ToListAsync(ct);
    }

    public async Task<OwnerServiceDto> CreateServiceAsync(Guid ownerId, CreateServiceRequest request, CancellationToken ct)
    {
        var shop = await GetShopForOwnerAsync(ownerId, ct);

        if (string.IsNullOrWhiteSpace(request.Name))
        {
            throw new AppException("Hizmet adı zorunludur.", 422);
        }

        if (request.DurationMinutes <= 0)
        {
            throw new AppException("Süre 0'dan büyük olmalıdır.", 422);
        }

        if (request.Price < 0)
        {
            throw new AppException("Fiyat negatif olamaz.", 422);
        }

        var service = new BarberService
        {
            BarberShopId = shop.Id,
            Name = request.Name.Trim(),
            Description = string.IsNullOrWhiteSpace(request.Description) ? null : request.Description.Trim(),
            DurationMinutes = request.DurationMinutes,
            Price = request.Price,
            IsActive = true,
            CreatedAt = clock.UtcNow
        };

        db.BarberServices.Add(service);
        await db.SaveChangesAsync(ct);
        return ToOwnerServiceDto(service);
    }

    public async Task<OwnerServiceDto> UpdateServiceAsync(Guid ownerId, Guid serviceId, UpdateServiceRequest request, CancellationToken ct)
    {
        var shop = await GetShopForOwnerAsync(ownerId, ct);

        var service = await db.BarberServices
            .FirstOrDefaultAsync(x => x.Id == serviceId && x.BarberShopId == shop.Id, ct)
            ?? throw new AppException("Hizmet bulunamadı.", 404);

        if (string.IsNullOrWhiteSpace(request.Name))
        {
            throw new AppException("Hizmet adı zorunludur.", 422);
        }

        service.Name = request.Name.Trim();
        service.Description = string.IsNullOrWhiteSpace(request.Description) ? null : request.Description.Trim();
        service.DurationMinutes = request.DurationMinutes;
        service.Price = request.Price;
        service.UpdatedAt = clock.UtcNow;

        await db.SaveChangesAsync(ct);
        return ToOwnerServiceDto(service);
    }

    public async Task DeleteServiceAsync(Guid ownerId, Guid serviceId, CancellationToken ct)
    {
        var shop = await GetShopForOwnerAsync(ownerId, ct);

        var service = await db.BarberServices
            .FirstOrDefaultAsync(x => x.Id == serviceId && x.BarberShopId == shop.Id, ct)
            ?? throw new AppException("Hizmet bulunamadı.", 404);

        service.IsActive = false;
        service.UpdatedAt = clock.UtcNow;
        await db.SaveChangesAsync(ct);
    }

    public async Task<IReadOnlyList<OwnerStaffDto>> GetStaffAsync(Guid ownerId, CancellationToken ct)
    {
        var shop = await GetShopForOwnerAsync(ownerId, ct);

        return await db.StaffMembers
            .AsNoTracking()
            .Include(x => x.StaffServices)
            .ThenInclude(x => x.BarberService)
            .Where(x => x.BarberShopId == shop.Id)
            .OrderBy(x => x.FullName)
            .Select(x => ToOwnerStaffDto(x))
            .ToListAsync(ct);
    }

    public async Task<OwnerStaffDto> CreateStaffAsync(Guid ownerId, CreateStaffRequest request, CancellationToken ct)
    {
        var shop = await GetShopForOwnerAsync(ownerId, ct);

        if (string.IsNullOrWhiteSpace(request.FullName))
        {
            throw new AppException("Personel adı zorunludur.", 422);
        }

        var staff = new StaffMember
        {
            BarberShopId = shop.Id,
            FullName = request.FullName.Trim(),
            Expertise = string.IsNullOrWhiteSpace(request.Expertise) ? null : request.Expertise.Trim(),
            Bio = string.IsNullOrWhiteSpace(request.Bio) ? null : request.Bio.Trim(),
            IsActive = true,
            CreatedAt = clock.UtcNow
        };

        db.StaffMembers.Add(staff);
        await db.SaveChangesAsync(ct);

        return new OwnerStaffDto(
            staff.Id,
            staff.FullName,
            staff.Expertise,
            staff.Bio,
            staff.AvatarUrl,
            staff.AverageRating,
            staff.IsActive,
            []);
    }

    public async Task<OwnerStaffDto> UpdateStaffAsync(Guid ownerId, Guid staffId, UpdateStaffRequest request, CancellationToken ct)
    {
        var shop = await GetShopForOwnerAsync(ownerId, ct);

        var staff = await db.StaffMembers
            .FirstOrDefaultAsync(x => x.Id == staffId && x.BarberShopId == shop.Id, ct)
            ?? throw new AppException("Personel bulunamadı.", 404);

        if (string.IsNullOrWhiteSpace(request.FullName))
        {
            throw new AppException("Personel adı zorunludur.", 422);
        }

        staff.FullName = request.FullName.Trim();
        staff.Expertise = string.IsNullOrWhiteSpace(request.Expertise) ? null : request.Expertise.Trim();
        staff.Bio = string.IsNullOrWhiteSpace(request.Bio) ? null : request.Bio.Trim();
        staff.UpdatedAt = clock.UtcNow;

        await db.SaveChangesAsync(ct);

        var services = await db.StaffServices
            .AsNoTracking()
            .Include(x => x.BarberService)
            .Where(x => x.StaffMemberId == staffId)
            .ToListAsync(ct);

        return new OwnerStaffDto(
            staff.Id,
            staff.FullName,
            staff.Expertise,
            staff.Bio,
            staff.AvatarUrl,
            staff.AverageRating,
            staff.IsActive,
            services.Select(x => ToOwnerServiceDto(x.BarberService!)).ToList());
    }

    public async Task DeleteStaffAsync(Guid ownerId, Guid staffId, CancellationToken ct)
    {
        var shop = await GetShopForOwnerAsync(ownerId, ct);

        var staff = await db.StaffMembers
            .FirstOrDefaultAsync(x => x.Id == staffId && x.BarberShopId == shop.Id, ct)
            ?? throw new AppException("Personel bulunamadı.", 404);

        staff.IsActive = false;
        staff.UpdatedAt = clock.UtcNow;
        await db.SaveChangesAsync(ct);
    }

    public async Task AssignStaffServicesAsync(Guid ownerId, Guid staffId, AssignStaffServicesRequest request, CancellationToken ct)
    {
        var shop = await GetShopForOwnerAsync(ownerId, ct);

        var staff = await db.StaffMembers
            .FirstOrDefaultAsync(x => x.Id == staffId && x.BarberShopId == shop.Id, ct)
            ?? throw new AppException("Personel bulunamadı.", 404);

        var validServiceIds = await db.BarberServices
            .Where(x => request.ServiceIds.Contains(x.Id) && x.BarberShopId == shop.Id && x.IsActive)
            .Select(x => x.Id)
            .ToListAsync(ct);

        if (validServiceIds.Count != request.ServiceIds.Distinct().Count())
        {
            throw new AppException("Geçersiz hizmet ID'leri var.", 422);
        }

        var existingLinks = await db.StaffServices
            .Where(x => x.StaffMemberId == staffId)
            .ToListAsync(ct);

        db.StaffServices.RemoveRange(existingLinks);

        foreach (var serviceId in validServiceIds)
        {
            db.StaffServices.Add(new BerberYanimda.Domain.StaffService
            {
                StaffMemberId = staffId,
                BarberServiceId = serviceId
            });
        }

        await db.SaveChangesAsync(ct);
    }

    public async Task<IReadOnlyList<OwnerWorkingHourDto>> GetWorkingHoursAsync(Guid ownerId, CancellationToken ct)
    {
        var shop = await GetShopForOwnerAsync(ownerId, ct);

        return await db.WorkingHours
            .AsNoTracking()
            .Where(x => x.BarberShopId == shop.Id && x.StaffMemberId == null)
            .OrderBy(x => x.DayOfWeek)
            .Select(x => ToOwnerWorkingHourDto(x))
            .ToListAsync(ct);
    }

    public async Task UpdateWorkingHoursAsync(Guid ownerId, UpdateWorkingHoursRequest request, CancellationToken ct)
    {
        var shop = await GetShopForOwnerAsync(ownerId, ct);

        var existingHours = await db.WorkingHours
            .Where(x => x.BarberShopId == shop.Id && x.StaffMemberId == null)
            .ToListAsync(ct);

        db.WorkingHours.RemoveRange(existingHours);

        foreach (var entry in request.WorkingHours)
        {
            if (entry.DayOfWeek < 1 || entry.DayOfWeek > 7)
            {
                throw new AppException("Geçersiz gün değeri (1-7).", 422);
            }

            if (!entry.IsClosed && entry.StartTime >= entry.EndTime)
            {
                throw new AppException("Başlangıç saati bitiş saatinden önce olmalıdır.", 422);
            }

            db.WorkingHours.Add(new WorkingHour
            {
                BarberShopId = shop.Id,
                DayOfWeek = entry.DayOfWeek,
                StartTime = entry.StartTime,
                EndTime = entry.EndTime,
                IsClosed = entry.IsClosed
            });
        }

        await db.SaveChangesAsync(ct);
    }

    public async Task<IReadOnlyList<OwnerAppointmentDto>> GetAppointmentsAsync(Guid ownerId, AppointmentStatus? status, CancellationToken ct)
    {
        var shop = await GetShopForOwnerAsync(ownerId, ct);

        var query = db.Appointments
            .AsNoTracking()
            .Include(x => x.CustomerUser)
            .Include(x => x.StaffMember)
            .Include(x => x.Services)
            .Where(x => x.BarberShopId == shop.Id);

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

    public async Task<OwnerAppointmentDto> ConfirmAppointmentAsync(Guid ownerId, Guid appointmentId, CancellationToken ct)
    {
        await bookingService.ConfirmAsync(appointmentId, ownerId, UserRole.BarberOwner, ct);

        var appointment = await db.Appointments
            .AsNoTracking()
            .Include(x => x.CustomerUser)
            .Include(x => x.StaffMember)
            .Include(x => x.Services)
            .FirstAsync(x => x.Id == appointmentId, ct);

        return ToOwnerAppointmentDto(appointment);
    }

    public async Task<OwnerAppointmentDto> CompleteAppointmentAsync(Guid ownerId, Guid appointmentId, CancellationToken ct)
    {
        await bookingService.CompleteAsync(appointmentId, ownerId, UserRole.BarberOwner, ct);

        var appointment = await db.Appointments
            .AsNoTracking()
            .Include(x => x.CustomerUser)
            .Include(x => x.StaffMember)
            .Include(x => x.Services)
            .FirstAsync(x => x.Id == appointmentId, ct);

        return ToOwnerAppointmentDto(appointment);
    }

    public async Task<OwnerAppointmentDto> RejectAppointmentAsync(Guid ownerId, Guid appointmentId, string? reason, CancellationToken ct)
    {
        await bookingService.RejectAsync(appointmentId, ownerId, UserRole.BarberOwner, new RejectAppointmentRequest(reason), ct);

        var appointment = await db.Appointments
            .AsNoTracking()
            .Include(x => x.CustomerUser)
            .Include(x => x.StaffMember)
            .Include(x => x.Services)
            .FirstAsync(x => x.Id == appointmentId, ct);

        return ToOwnerAppointmentDto(appointment);
    }

    public async Task<DashboardDto> GetDashboardAsync(Guid ownerId, CancellationToken ct)
    {
        var shop = await GetShopForOwnerAsync(ownerId, ct);
        var today = clock.Today;

        var appointments = await db.Appointments
            .AsNoTracking()
            .Where(x => x.BarberShopId == shop.Id)
            .ToListAsync(ct);

        var reviews = await db.Reviews
            .AsNoTracking()
            .Where(x => x.BarberShopId == shop.Id && x.IsApproved)
            .ToListAsync(ct);

        var todayAppointments = appointments.Where(x => x.AppointmentDate == today).ToList();
        var paidPayments = await db.Payments
            .AsNoTracking()
            .Where(x => appointments.Select(a => a.Id).Contains(x.AppointmentId) && x.Status == PaymentStatus.Paid)
            .ToListAsync(ct);

        return new DashboardDto(
            TotalAppointments: appointments.Count,
            TodayAppointments: todayAppointments.Count,
            PendingAppointments: appointments.Count(x => x.Status == AppointmentStatus.Pending),
            CompletedAppointments: appointments.Count(x => x.Status == AppointmentStatus.Completed),
            TotalRevenue: paidPayments.Sum(x => x.Amount),
            TodayRevenue: paidPayments.Where(x => todayAppointments.Any(a => a.Id == x.AppointmentId)).Sum(x => x.Amount),
            TotalReviews: reviews.Count,
            AverageRating: reviews.Count == 0 ? 0 : Math.Round((decimal)reviews.Average(x => x.Rating), 2));
    }

    private static IEnumerable<WorkingHour> CreateDefaultWorkingHours(Guid barberShopId)
    {
        for (var day = 1; day <= 6; day++)
        {
            yield return new WorkingHour
            {
                BarberShopId = barberShopId,
                DayOfWeek = day,
                StartTime = new TimeOnly(9, 0),
                EndTime = new TimeOnly(20, 0)
            };
        }

        yield return new WorkingHour
        {
            BarberShopId = barberShopId,
            DayOfWeek = 7,
            StartTime = new TimeOnly(10, 0),
            EndTime = new TimeOnly(18, 0)
        };
    }

    private static BarberShopDetailDto ToShopDetailDto(BarberShop shop) =>
        new(
            shop.Id,
            shop.Name,
            shop.Description,
            shop.PhoneNumber ?? string.Empty,
            shop.Email,
            shop.City,
            shop.District,
            shop.Address,
            shop.Latitude,
            shop.Longitude,
            shop.CoverImageUrl,
            shop.LogoUrl,
            shop.IsApproved,
            shop.IsActive,
            shop.CreatedAt);

    private static OwnerServiceDto ToOwnerServiceDto(BarberService service) =>
        new(
            service.Id,
            service.Name,
            service.Description,
            service.DurationMinutes,
            service.Price,
            service.IsActive,
            service.CreatedAt);

    private static OwnerStaffDto ToOwnerStaffDto(StaffMember staff) =>
        new(
            staff.Id,
            staff.FullName,
            staff.Expertise,
            staff.Bio,
            staff.AvatarUrl,
            staff.AverageRating,
            staff.IsActive,
            staff.StaffServices
                .Where(x => x.BarberService != null)
                .Select(x => ToOwnerServiceDto(x.BarberService!))
                .ToList());

    private static OwnerWorkingHourDto ToOwnerWorkingHourDto(WorkingHour hour) =>
        new(
            hour.Id,
            hour.DayOfWeek,
            hour.StartTime,
            hour.EndTime,
            hour.IsClosed);

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
