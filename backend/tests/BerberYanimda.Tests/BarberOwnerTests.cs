using BerberYanimda.Application.Common;
using BerberYanimda.Application.DTOs;
using BerberYanimda.Application.Interfaces;
using BerberYanimda.Application.Services;
using BerberYanimda.Domain;
using BerberYanimda.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace BerberYanimda.Tests;

public sealed class BarberOwnerTests
{
    [Fact]
    public async Task Create_shop_allows_only_one_active_shop()
    {
        await using var db = CreateDb();
        var owner = new User { FullName = "Owner", PhoneNumber = "+905552222222", Role = UserRole.BarberOwner };
        var shop = new BarberShop
        {
            OwnerUserId = owner.Id,
            Name = "Existing Shop",
            City = "İstanbul",
            District = "Kadıköy",
            Address = "Test",
            IsActive = true
        };
        db.Users.Add(owner);
        db.BarberShops.Add(shop);
        await db.SaveChangesAsync();

        var service = CreateService(db);

        var ex = await Assert.ThrowsAsync<AppException>(() =>
            service.CreateShopAsync(owner.Id, new CreateBarberShopRequest("New Shop", null, "+902121112233", "İstanbul", "Beşiktaş", "Test", null, null), CancellationToken.None));

        Assert.Equal(409, ex.StatusCode);
    }

    [Fact]
    public async Task Create_shop_requires_valid_name()
    {
        await using var db = CreateDb();
        var owner = new User { FullName = "Owner", PhoneNumber = "+905552222222", Role = UserRole.BarberOwner };
        db.Users.Add(owner);
        await db.SaveChangesAsync();

        var service = CreateService(db);

        var ex = await Assert.ThrowsAsync<AppException>(() =>
            service.CreateShopAsync(owner.Id, new CreateBarberShopRequest("", null, "+902121112233", "İstanbul", "Kadıköy", "Test", null, null), CancellationToken.None));

        Assert.Equal(422, ex.StatusCode);
    }

    [Fact]
    public async Task Create_service_validates_duration()
    {
        await using var db = CreateDb();
        var owner = await SeedOwnerWithShopAsync(db);
        var service = CreateService(db);

        var ex = await Assert.ThrowsAsync<AppException>(() =>
            service.CreateServiceAsync(owner.Id, new CreateServiceRequest("Test", null, 0, 100), CancellationToken.None));

        Assert.Equal(422, ex.StatusCode);
    }

    [Fact]
    public async Task Create_service_validates_price()
    {
        await using var db = CreateDb();
        var owner = await SeedOwnerWithShopAsync(db);
        var service = CreateService(db);

        var ex = await Assert.ThrowsAsync<AppException>(() =>
            service.CreateServiceAsync(owner.Id, new CreateServiceRequest("Test", null, 30, -10), CancellationToken.None));

        Assert.Equal(422, ex.StatusCode);
    }

    [Fact]
    public async Task Update_working_hours_validates_day_range()
    {
        await using var db = CreateDb();
        var owner = await SeedOwnerWithShopAsync(db);
        var service = CreateService(db);

        var ex = await Assert.ThrowsAsync<AppException>(() =>
            service.UpdateWorkingHoursAsync(owner.Id, new UpdateWorkingHoursRequest([
                new WorkingHourEntryDto(8, new TimeOnly(9, 0), new TimeOnly(18, 0), false)
            ]), CancellationToken.None));

        Assert.Equal(422, ex.StatusCode);
    }

    [Fact]
    public async Task Update_working_hours_validates_time_order()
    {
        await using var db = CreateDb();
        var owner = await SeedOwnerWithShopAsync(db);
        var service = CreateService(db);

        var ex = await Assert.ThrowsAsync<AppException>(() =>
            service.UpdateWorkingHoursAsync(owner.Id, new UpdateWorkingHoursRequest([
                new WorkingHourEntryDto(1, new TimeOnly(18, 0), new TimeOnly(9, 0), false)
            ]), CancellationToken.None));

        Assert.Equal(422, ex.StatusCode);
    }

    [Fact]
    public async Task Confirm_appointment_requires_pending_status()
    {
        await using var db = CreateDb();
        var owner = await SeedOwnerWithAppointmentAsync(db, AppointmentStatus.Confirmed);
        var service = CreateService(db);

        var ex = await Assert.ThrowsAsync<AppException>(() =>
            service.ConfirmAppointmentAsync(owner.Id, owner.AppointmentId, CancellationToken.None));

        Assert.Equal(409, ex.StatusCode);
    }

    [Fact]
    public async Task Complete_appointment_requires_confirmed_status()
    {
        await using var db = CreateDb();
        var owner = await SeedOwnerWithAppointmentAsync(db, AppointmentStatus.Pending);
        var service = CreateService(db);

        var ex = await Assert.ThrowsAsync<AppException>(() =>
            service.CompleteAppointmentAsync(owner.Id, owner.AppointmentId, CancellationToken.None));

        Assert.Equal(409, ex.StatusCode);
    }

    [Fact]
    public async Task Reject_appointment_requires_pending_status()
    {
        await using var db = CreateDb();
        var owner = await SeedOwnerWithAppointmentAsync(db, AppointmentStatus.Confirmed);
        var service = CreateService(db);

        var ex = await Assert.ThrowsAsync<AppException>(() =>
            service.RejectAppointmentAsync(owner.Id, owner.AppointmentId, "Müşteri gelmedi", CancellationToken.None));

        Assert.Equal(409, ex.StatusCode);
    }

    private static BarberOwnerService CreateService(AppDbContext db)
    {
        var clock = new FixedClock();
        var auditLog = new NoOpAuditLogService();
        var push = new NoOpPushNotificationService();
        var availability = new AvailabilityService(db, clock);
        var booking = new BookingService(db, availability, clock, auditLog, push);
        return new BarberOwnerService(db, clock, auditLog, booking);
    }

    private static AppDbContext CreateDb()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .ConfigureWarnings(warnings => warnings.Ignore(Microsoft.EntityFrameworkCore.Diagnostics.InMemoryEventId.TransactionIgnoredWarning))
            .Options;
        return new AppDbContext(options);
    }

    private static async Task<User> SeedOwnerWithShopAsync(AppDbContext db)
    {
        var owner = new User { FullName = "Owner", PhoneNumber = "+905552222222", Role = UserRole.BarberOwner };
        var shop = new BarberShop
        {
            OwnerUserId = owner.Id,
            Name = "Test Shop",
            City = "İstanbul",
            District = "Kadıköy",
            Address = "Test",
            IsActive = true,
            IsApproved = true
        };
        db.Users.Add(owner);
        db.BarberShops.Add(shop);
        await db.SaveChangesAsync();
        return owner;
    }

    private static async Task<OwnerWithAppointment> SeedOwnerWithAppointmentAsync(AppDbContext db, AppointmentStatus status)
    {
        var owner = new User { FullName = "Owner", PhoneNumber = "+905552222222", Role = UserRole.BarberOwner };
        var customer = new User { FullName = "Customer", PhoneNumber = "+905551111111", IsPhoneVerified = true };
        var shop = new BarberShop
        {
            OwnerUserId = owner.Id,
            Name = "Test Shop",
            City = "İstanbul",
            District = "Kadıköy",
            Address = "Test",
            IsActive = true,
            IsApproved = true
        };
        var appointment = new Appointment
        {
            CustomerUserId = customer.Id,
            BarberShopId = shop.Id,
            AppointmentDate = new DateOnly(2026, 4, 24),
            StartTime = new TimeOnly(10, 0),
            EndTime = new TimeOnly(10, 30),
            TotalDurationMinutes = 30,
            TotalPrice = 250,
            Status = status
        };

        db.Users.AddRange(owner, customer);
        db.BarberShops.Add(shop);
        db.Appointments.Add(appointment);
        await db.SaveChangesAsync();

        return new OwnerWithAppointment(owner.Id, shop.Id, appointment.Id);
    }

    private sealed class FixedClock : IDateTimeProvider
    {
        public DateTime UtcNow => new(2026, 4, 24, 12, 0, 0, DateTimeKind.Utc);
        public DateOnly Today => new(2026, 4, 24);
    }

    private sealed record OwnerWithAppointment(Guid Id, Guid ShopId, Guid AppointmentId);
}



