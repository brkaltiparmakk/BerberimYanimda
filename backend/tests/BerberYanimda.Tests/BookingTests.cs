using BerberYanimda.Application.Common;
using BerberYanimda.Application.Interfaces;
using BerberYanimda.Application.Services;
using BerberYanimda.Application.DTOs;
using BerberYanimda.Domain;
using BerberYanimda.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace BerberYanimda.Tests;

public sealed class BookingTests
{
    [Fact]
    public async Task Availability_marks_overlapping_staff_slot_unavailable()
    {
        await using var db = CreateDb();
        var seed = await SeedMinimalAsync(db);
        var service = new AvailabilityService(db, new FixedClock());

        var slots = await service.GetSlotsAsync(seed.ShopId, seed.StaffId, [seed.ServiceId], new DateOnly(2026, 4, 24), CancellationToken.None);

        Assert.Contains(slots, x => x.StartTime == "10:00" && !x.IsAvailable);
        Assert.Contains(slots, x => x.StartTime == "10:30" && x.IsAvailable);
    }

    [Fact]
    public async Task Create_appointment_uses_backend_service_price_snapshot()
    {
        await using var db = CreateDb();
        var seed = await SeedMinimalAsync(db, includeExistingAppointment: false);
        var availability = new AvailabilityService(db, new FixedClock());
        var booking = new BookingService(db, availability, new FixedClock(), new NoOpAuditLogService(), new NoOpPushNotificationService());

        var appointment = await booking.CreateAsync(seed.CustomerId, new CreateAppointmentRequest(
            seed.ShopId,
            seed.StaffId,
            new DateOnly(2026, 4, 24),
            new TimeOnly(10, 0),
            [seed.ServiceId],
            "Kısa kesim"), CancellationToken.None);

        Assert.Equal(250, appointment.TotalPrice);
        Assert.Equal(30, appointment.TotalDurationMinutes);
        Assert.Single(appointment.Services);
        Assert.Equal("Saç Kesimi", appointment.Services[0].ServiceName);
    }

    [Fact]
    public async Task Create_appointment_rejects_overlapping_staff_slot()
    {
        await using var db = CreateDb();
        var seed = await SeedMinimalAsync(db);
        var availability = new AvailabilityService(db, new FixedClock());
        var booking = new BookingService(db, availability, new FixedClock(), new NoOpAuditLogService(), new NoOpPushNotificationService());

        var ex = await Assert.ThrowsAsync<AppException>(() => booking.CreateAsync(seed.CustomerId, new CreateAppointmentRequest(
            seed.ShopId,
            seed.StaffId,
            new DateOnly(2026, 4, 24),
            new TimeOnly(10, 15),
            [seed.ServiceId],
            null), CancellationToken.None));

        Assert.Equal(409, ex.StatusCode);
    }

    // ─── ConfirmAsync Tests ───

    [Fact]
    public async Task ConfirmAsync_transitions_pending_to_confirmed()
    {
        await using var db = CreateDb();
        var seed = await SeedMinimalAsync(db, status: AppointmentStatus.Pending);
        var service = new BookingService(db, new AvailabilityService(db, new FixedClock()), new FixedClock(), new NoOpAuditLogService(), new NoOpPushNotificationService());

        var result = await service.ConfirmAsync(seed.AppointmentId!.Value, seed.OwnerId, UserRole.BarberOwner, CancellationToken.None);

        Assert.Equal(AppointmentStatus.Confirmed, result.Status);
        var appointment = await db.Appointments.FindAsync(seed.AppointmentId!.Value);
        Assert.NotNull(appointment);
        Assert.Equal(AppointmentStatus.Confirmed, appointment.Status);
        Assert.NotNull(appointment.UpdatedAt);
    }

    [Fact]
    public async Task ConfirmAsync_throws_for_confirmed_appointment()
    {
        await using var db = CreateDb();
        var seed = await SeedMinimalAsync(db, status: AppointmentStatus.Confirmed);
        var service = new BookingService(db, new AvailabilityService(db, new FixedClock()), new FixedClock(), new NoOpAuditLogService(), new NoOpPushNotificationService());

        var ex = await Assert.ThrowsAsync<AppException>(() =>
            service.ConfirmAsync(seed.AppointmentId!.Value, seed.OwnerId, UserRole.BarberOwner, CancellationToken.None));

        Assert.Equal(409, ex.StatusCode);
    }

    [Fact]
    public async Task ConfirmAsync_throws_for_completed_appointment()
    {
        await using var db = CreateDb();
        var seed = await SeedMinimalAsync(db, status: AppointmentStatus.Completed);
        var service = new BookingService(db, new AvailabilityService(db, new FixedClock()), new FixedClock(), new NoOpAuditLogService(), new NoOpPushNotificationService());

        var ex = await Assert.ThrowsAsync<AppException>(() =>
            service.ConfirmAsync(seed.AppointmentId!.Value, seed.OwnerId, UserRole.BarberOwner, CancellationToken.None));

        Assert.Equal(409, ex.StatusCode);
    }

    [Fact]
    public async Task ConfirmAsync_allows_staff_to_confirm()
    {
        await using var db = CreateDb();
        var seed = await SeedMinimalAsync(db, status: AppointmentStatus.Pending);
        var service = new BookingService(db, new AvailabilityService(db, new FixedClock()), new FixedClock(), new NoOpAuditLogService(), new NoOpPushNotificationService());

        var result = await service.ConfirmAsync(seed.AppointmentId!.Value, seed.StaffUserId, UserRole.Staff, CancellationToken.None);
        Assert.Equal(AppointmentStatus.Confirmed, result.Status);
    }

    [Fact]
    public async Task ConfirmAsync_allows_admin_to_confirm()
    {
        await using var db = CreateDb();
        var seed = await SeedMinimalAsync(db, status: AppointmentStatus.Pending);
        var service = new BookingService(db, new AvailabilityService(db, new FixedClock()), new FixedClock(), new NoOpAuditLogService(), new NoOpPushNotificationService());

        var admin = new User { FullName = "Admin", PhoneNumber = "+905553333333", Role = UserRole.Admin };
        db.Users.Add(admin);
        await db.SaveChangesAsync();

        var result = await service.ConfirmAsync(seed.AppointmentId!.Value, admin.Id, UserRole.Admin, CancellationToken.None);
        Assert.Equal(AppointmentStatus.Confirmed, result.Status);
    }

    [Fact]
    public async Task ConfirmAsync_rejects_customer()
    {
        await using var db = CreateDb();
        var seed = await SeedMinimalAsync(db, status: AppointmentStatus.Pending);
        var service = new BookingService(db, new AvailabilityService(db, new FixedClock()), new FixedClock(), new NoOpAuditLogService(), new NoOpPushNotificationService());

        var ex = await Assert.ThrowsAsync<AppException>(() =>
            service.ConfirmAsync(seed.AppointmentId!.Value, seed.CustomerId, UserRole.Customer, CancellationToken.None));

        Assert.Equal(403, ex.StatusCode);
    }

    [Fact]
    public async Task ConfirmAsync_throws_when_appointment_not_found()
    {
        await using var db = CreateDb();
        var owner = new User { FullName = "Owner", PhoneNumber = "+905552222222", Role = UserRole.BarberOwner };
        db.Users.Add(owner);
        await db.SaveChangesAsync();
        var service = new BookingService(db, new AvailabilityService(db, new FixedClock()), new FixedClock(), new NoOpAuditLogService(), new NoOpPushNotificationService());

        var ex = await Assert.ThrowsAsync<AppException>(() =>
            service.ConfirmAsync(Guid.NewGuid(), owner.Id, UserRole.BarberOwner, CancellationToken.None));

        Assert.Equal(404, ex.StatusCode);
    }

    // ─── CompleteAsync Tests ───

    [Fact]
    public async Task CompleteAsync_transitions_confirmed_to_completed()
    {
        await using var db = CreateDb();
        var seed = await SeedMinimalAsync(db, status: AppointmentStatus.Confirmed);
        var service = new BookingService(db, new AvailabilityService(db, new FixedClock()), new FixedClock(), new NoOpAuditLogService(), new NoOpPushNotificationService());

        var result = await service.CompleteAsync(seed.AppointmentId!.Value, seed.OwnerId, UserRole.BarberOwner, CancellationToken.None);

        Assert.Equal(AppointmentStatus.Completed, result.Status);
        var appointment = await db.Appointments.FindAsync(seed.AppointmentId!.Value);
        Assert.NotNull(appointment);
        Assert.Equal(AppointmentStatus.Completed, appointment.Status);
        Assert.NotNull(appointment.CompletedAt);
    }

    [Fact]
    public async Task CompleteAsync_throws_for_pending_appointment()
    {
        await using var db = CreateDb();
        var seed = await SeedMinimalAsync(db, status: AppointmentStatus.Pending);
        var service = new BookingService(db, new AvailabilityService(db, new FixedClock()), new FixedClock(), new NoOpAuditLogService(), new NoOpPushNotificationService());

        var ex = await Assert.ThrowsAsync<AppException>(() =>
            service.CompleteAsync(seed.AppointmentId!.Value, seed.OwnerId, UserRole.BarberOwner, CancellationToken.None));

        Assert.Equal(409, ex.StatusCode);
    }

    [Fact]
    public async Task CompleteAsync_throws_for_cancelled_appointment()
    {
        await using var db = CreateDb();
        var seed = await SeedMinimalAsync(db, status: AppointmentStatus.Cancelled);
        var service = new BookingService(db, new AvailabilityService(db, new FixedClock()), new FixedClock(), new NoOpAuditLogService(), new NoOpPushNotificationService());

        var ex = await Assert.ThrowsAsync<AppException>(() =>
            service.CompleteAsync(seed.AppointmentId!.Value, seed.OwnerId, UserRole.BarberOwner, CancellationToken.None));

        Assert.Equal(409, ex.StatusCode);
    }

    [Fact]
    public async Task CompleteAsync_rejects_customer()
    {
        await using var db = CreateDb();
        var seed = await SeedMinimalAsync(db, status: AppointmentStatus.Confirmed);
        var service = new BookingService(db, new AvailabilityService(db, new FixedClock()), new FixedClock(), new NoOpAuditLogService(), new NoOpPushNotificationService());

        var ex = await Assert.ThrowsAsync<AppException>(() =>
            service.CompleteAsync(seed.AppointmentId!.Value, seed.CustomerId, UserRole.Customer, CancellationToken.None));

        Assert.Equal(403, ex.StatusCode);
    }

    // ─── RejectAsync Tests ───

    [Fact]
    public async Task RejectAsync_transitions_pending_to_rejected()
    {
        await using var db = CreateDb();
        var seed = await SeedMinimalAsync(db, status: AppointmentStatus.Pending);
        var service = new BookingService(db, new AvailabilityService(db, new FixedClock()), new FixedClock(), new NoOpAuditLogService(), new NoOpPushNotificationService());

        var result = await service.RejectAsync(seed.AppointmentId!.Value, seed.OwnerId, UserRole.BarberOwner, new RejectAppointmentRequest("Müşteri gelmedi"), CancellationToken.None);

        Assert.Equal(AppointmentStatus.Rejected, result.Status);
        Assert.Equal("Müşteri gelmedi", result.RejectionReason);
        var appointment = await db.Appointments.FindAsync(seed.AppointmentId!.Value);
        Assert.NotNull(appointment);
        Assert.Equal(AppointmentStatus.Rejected, appointment.Status);
        Assert.NotNull(appointment.RejectedAt);
    }

    [Fact]
    public async Task RejectAsync_allows_null_reason()
    {
        await using var db = CreateDb();
        var seed = await SeedMinimalAsync(db, status: AppointmentStatus.Pending);
        var service = new BookingService(db, new AvailabilityService(db, new FixedClock()), new FixedClock(), new NoOpAuditLogService(), new NoOpPushNotificationService());

        var result = await service.RejectAsync(seed.AppointmentId!.Value, seed.OwnerId, UserRole.BarberOwner, new RejectAppointmentRequest(null), CancellationToken.None);

        Assert.Equal(AppointmentStatus.Rejected, result.Status);
        Assert.Null(result.RejectionReason);
    }

    [Fact]
    public async Task RejectAsync_throws_for_confirmed_appointment()
    {
        await using var db = CreateDb();
        var seed = await SeedMinimalAsync(db, status: AppointmentStatus.Confirmed);
        var service = new BookingService(db, new AvailabilityService(db, new FixedClock()), new FixedClock(), new NoOpAuditLogService(), new NoOpPushNotificationService());

        var ex = await Assert.ThrowsAsync<AppException>(() =>
            service.RejectAsync(seed.AppointmentId!.Value, seed.OwnerId, UserRole.BarberOwner, new RejectAppointmentRequest("Sebep"), CancellationToken.None));

        Assert.Equal(409, ex.StatusCode);
    }

    [Fact]
    public async Task RejectAsync_rejects_customer()
    {
        await using var db = CreateDb();
        var seed = await SeedMinimalAsync(db, status: AppointmentStatus.Pending);
        var service = new BookingService(db, new AvailabilityService(db, new FixedClock()), new FixedClock(), new NoOpAuditLogService(), new NoOpPushNotificationService());

        var ex = await Assert.ThrowsAsync<AppException>(() =>
            service.RejectAsync(seed.AppointmentId!.Value, seed.CustomerId, UserRole.Customer, new RejectAppointmentRequest("Sebep"), CancellationToken.None));

        Assert.Equal(403, ex.StatusCode);
    }

    // ─── GetShopAppointmentsAsync Tests ───

    [Fact]
    public async Task GetShopAppointmentsAsync_rejects_customer()
    {
        await using var db = CreateDb();
        var seed = await SeedMinimalAsync(db, status: AppointmentStatus.Confirmed);
        var service = new BookingService(db, new AvailabilityService(db, new FixedClock()), new FixedClock(), new NoOpAuditLogService(), new NoOpPushNotificationService());

        var ex = await Assert.ThrowsAsync<AppException>(() =>
            service.GetShopAppointmentsAsync(seed.CustomerId, UserRole.Customer, new ShopAppointmentsQuery(null, null), CancellationToken.None));

        Assert.Equal(403, ex.StatusCode);
    }

    [Fact]
    public async Task GetShopAppointmentsAsync_returns_owner_shop_appointments()
    {
        await using var db = CreateDb();
        var seed = await SeedMinimalAsync(db, status: AppointmentStatus.Confirmed);
        var service = new BookingService(db, new AvailabilityService(db, new FixedClock()), new FixedClock(), new NoOpAuditLogService(), new NoOpPushNotificationService());

        var result = await service.GetShopAppointmentsAsync(seed.OwnerId, UserRole.BarberOwner, new ShopAppointmentsQuery(null, null), CancellationToken.None);

        Assert.Single(result.Items);
        Assert.Equal(seed.AppointmentId!.Value, result.Items[0].Id);
    }

    [Fact]
    public async Task GetShopAppointmentsAsync_returns_staff_appointments()
    {
        await using var db = CreateDb();
        var seed = await SeedMinimalAsync(db, status: AppointmentStatus.Confirmed);
        var service = new BookingService(db, new AvailabilityService(db, new FixedClock()), new FixedClock(), new NoOpAuditLogService(), new NoOpPushNotificationService());

        var result = await service.GetShopAppointmentsAsync(seed.StaffUserId, UserRole.Staff, new ShopAppointmentsQuery(null, null), CancellationToken.None);

        Assert.Single(result.Items);
    }

    [Fact]
    public async Task GetShopAppointmentsAsync_returns_all_for_admin()
    {
        await using var db = CreateDb();
        var seed = await SeedMinimalAsync(db, status: AppointmentStatus.Confirmed);
        var admin = new User { FullName = "Admin", PhoneNumber = "+905553333333", Role = UserRole.Admin };
        db.Users.Add(admin);
        await db.SaveChangesAsync();
        var service = new BookingService(db, new AvailabilityService(db, new FixedClock()), new FixedClock(), new NoOpAuditLogService(), new NoOpPushNotificationService());

        var result = await service.GetShopAppointmentsAsync(admin.Id, UserRole.Admin, new ShopAppointmentsQuery(null, null), CancellationToken.None);

        Assert.Single(result.Items);
    }

    [Fact]
    public async Task GetShopAppointmentsAsync_filters_by_date()
    {
        await using var db = CreateDb();
        var seed = await SeedMinimalAsync(db, status: AppointmentStatus.Confirmed);
        var service = new BookingService(db, new AvailabilityService(db, new FixedClock()), new FixedClock(), new NoOpAuditLogService(), new NoOpPushNotificationService());

        var result = await service.GetShopAppointmentsAsync(seed.OwnerId, UserRole.BarberOwner, new ShopAppointmentsQuery(new DateOnly(2026, 4, 24), null), CancellationToken.None);
        Assert.Single(result.Items);

        var emptyResult = await service.GetShopAppointmentsAsync(seed.OwnerId, UserRole.BarberOwner, new ShopAppointmentsQuery(new DateOnly(2026, 4, 25), null), CancellationToken.None);
        Assert.Empty(emptyResult.Items);
    }

    [Fact]
    public async Task GetShopAppointmentsAsync_filters_by_status()
    {
        await using var db = CreateDb();
        var seed = await SeedMinimalAsync(db, status: AppointmentStatus.Confirmed);
        var service = new BookingService(db, new AvailabilityService(db, new FixedClock()), new FixedClock(), new NoOpAuditLogService(), new NoOpPushNotificationService());

        var result = await service.GetShopAppointmentsAsync(seed.OwnerId, UserRole.BarberOwner, new ShopAppointmentsQuery(null, AppointmentStatus.Confirmed), CancellationToken.None);
        Assert.Single(result.Items);

        var emptyResult = await service.GetShopAppointmentsAsync(seed.OwnerId, UserRole.BarberOwner, new ShopAppointmentsQuery(null, AppointmentStatus.Pending), CancellationToken.None);
        Assert.Empty(emptyResult.Items);
    }

    [Fact]
    public async Task GetShopAppointmentsAsync_paginates()
    {
        await using var db = CreateDb();
        var seed = await SeedMinimalAsync(db, status: AppointmentStatus.Confirmed);
        // add second appointment
        db.Appointments.Add(new Appointment
        {
            CustomerUserId = seed.CustomerId,
            BarberShopId = seed.ShopId,
            StaffMemberId = seed.StaffId,
            AppointmentDate = new DateOnly(2026, 4, 25),
            StartTime = new TimeOnly(11, 0),
            EndTime = new TimeOnly(11, 30),
            TotalDurationMinutes = 30,
            TotalPrice = 250,
            Status = AppointmentStatus.Confirmed
        });
        await db.SaveChangesAsync();
        var service = new BookingService(db, new AvailabilityService(db, new FixedClock()), new FixedClock(), new NoOpAuditLogService(), new NoOpPushNotificationService());

        var page1 = await service.GetShopAppointmentsAsync(seed.OwnerId, UserRole.BarberOwner, new ShopAppointmentsQuery(null, null, 1, 1), CancellationToken.None);
        Assert.Single(page1.Items);
        Assert.Equal(2, page1.TotalCount);
        Assert.Equal(2, page1.TotalPages);

        var page2 = await service.GetShopAppointmentsAsync(seed.OwnerId, UserRole.BarberOwner, new ShopAppointmentsQuery(null, null, 2, 1), CancellationToken.None);
        Assert.Single(page2.Items);
    }

    [Fact]
    public async Task GetShopAppointmentsAsync_excludes_other_shops_for_owner()
    {
        await using var db = CreateDb();
        var seed = await SeedMinimalAsync(db, status: AppointmentStatus.Confirmed);
        var otherOwner = new User { FullName = "Other Owner", PhoneNumber = "+905554444444", Role = UserRole.BarberOwner };
        var otherShop = new BarberShop
        {
            OwnerUserId = otherOwner.Id,
            Name = "Other Shop",
            City = "İstanbul",
            District = "Beşiktaş",
            Address = "Test",
            IsActive = true,
            IsApproved = true
        };
        db.Users.Add(otherOwner);
        db.BarberShops.Add(otherShop);
        await db.SaveChangesAsync();
        var service = new BookingService(db, new AvailabilityService(db, new FixedClock()), new FixedClock(), new NoOpAuditLogService(), new NoOpPushNotificationService());

        var result = await service.GetShopAppointmentsAsync(otherOwner.Id, UserRole.BarberOwner, new ShopAppointmentsQuery(null, null), CancellationToken.None);
        Assert.Empty(result.Items);
    }

    // ─── CancelAsync State Transition Tests (existing method, new coverage) ───

    [Fact]
    public async Task CancelAsync_allows_confirmed_to_cancelled()
    {
        await using var db = CreateDb();
        var seed = await SeedMinimalAsync(db, status: AppointmentStatus.Confirmed);
        var service = new BookingService(db, new AvailabilityService(db, new FixedClock()), new FixedClock(), new NoOpAuditLogService(), new NoOpPushNotificationService());

        var result = await service.CancelAsync(seed.AppointmentId!.Value, seed.CustomerId, UserRole.Customer, new CancelAppointmentRequest("Plan değişti"), CancellationToken.None);

        Assert.Equal(AppointmentStatus.Cancelled, result.Status);
    }

    [Fact]
    public async Task CancelAsync_rejects_completed_to_cancelled()
    {
        await using var db = CreateDb();
        var seed = await SeedMinimalAsync(db, status: AppointmentStatus.Completed);
        var service = new BookingService(db, new AvailabilityService(db, new FixedClock()), new FixedClock(), new NoOpAuditLogService(), new NoOpPushNotificationService());

        var ex = await Assert.ThrowsAsync<AppException>(() =>
            service.CancelAsync(seed.AppointmentId!.Value, seed.CustomerId, UserRole.Customer, new CancelAppointmentRequest("Sebep"), CancellationToken.None));

        Assert.Equal(409, ex.StatusCode);
    }

    // ─── Helpers ───

    private static AppDbContext CreateDb()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .ConfigureWarnings(warnings => warnings.Ignore(Microsoft.EntityFrameworkCore.Diagnostics.InMemoryEventId.TransactionIgnoredWarning))
            .Options;
        return new AppDbContext(options);
    }

    private static async Task<SeedIds> SeedMinimalAsync(AppDbContext db, bool includeExistingAppointment = true, AppointmentStatus status = AppointmentStatus.Confirmed)
    {
        var customer = new User { FullName = "Customer", PhoneNumber = "+905551111111", IsPhoneVerified = true };
        var owner = new User { FullName = "Owner", PhoneNumber = "+905552222222", IsPhoneVerified = true, Role = UserRole.BarberOwner };
        var shop = new BarberShop
        {
            OwnerUserId = owner.Id,
            Name = "Modern Barber",
            City = "İstanbul",
            District = "Kadıköy",
            Address = "Moda",
            IsApproved = true,
            IsActive = true
        };
        var service = new BarberService { BarberShopId = shop.Id, Name = "Saç Kesimi", DurationMinutes = 30, Price = 250 };
        var staff = new StaffMember { BarberShopId = shop.Id, FullName = "Mehmet Usta", IsActive = true };
        var staffUser = new User { FullName = "Mehmet Usta", PhoneNumber = "+905555555555", Role = UserRole.Staff };
        staff.UserId = staffUser.Id;

        db.Users.AddRange(customer, owner, staffUser);
        db.BarberShops.Add(shop);
        db.BarberServices.Add(service);
        db.StaffMembers.Add(staff);
        db.StaffServices.Add(new BerberYanimda.Domain.StaffService { StaffMemberId = staff.Id, BarberServiceId = service.Id });
        db.WorkingHours.Add(new WorkingHour
        {
            BarberShopId = shop.Id,
            StaffMemberId = staff.Id,
            DayOfWeek = 5,
            StartTime = new TimeOnly(9, 0),
            EndTime = new TimeOnly(12, 0)
        });

        Guid? appointmentId = null;
        if (includeExistingAppointment)
        {
            var appointment = new Appointment
            {
                CustomerUserId = customer.Id,
                BarberShopId = shop.Id,
                StaffMemberId = staff.Id,
                AppointmentDate = new DateOnly(2026, 4, 24),
                StartTime = new TimeOnly(10, 0),
                EndTime = new TimeOnly(10, 30),
                TotalDurationMinutes = 30,
                TotalPrice = 250,
                Status = status
            };
            db.Appointments.Add(appointment);
            await db.SaveChangesAsync();
            appointmentId = appointment.Id;
        }

        await db.SaveChangesAsync();
        return new SeedIds(customer.Id, shop.Id, staff.Id, service.Id, owner.Id, staffUser.Id, appointmentId);
    }

    private sealed class FixedClock : IDateTimeProvider
    {
        public DateTime UtcNow => new(2026, 4, 23, 8, 0, 0, DateTimeKind.Utc);
        public DateOnly Today => new(2026, 4, 23);
    }

    private sealed record SeedIds(Guid CustomerId, Guid ShopId, Guid StaffId, Guid ServiceId, Guid OwnerId, Guid StaffUserId, Guid? AppointmentId);
}



