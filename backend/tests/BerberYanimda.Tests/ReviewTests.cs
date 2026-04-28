using BerberYanimda.Application.Common;
using BerberYanimda.Application.DTOs;
using BerberYanimda.Application.Interfaces;
using BerberYanimda.Application.Services;
using BerberYanimda.Domain;
using BerberYanimda.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace BerberYanimda.Tests;

public sealed class ReviewTests
{
    [Fact]
    public async Task Create_review_requires_completed_appointment()
    {
        await using var db = CreateDb();
        var seed = await SeedAsync(db, AppointmentStatus.Confirmed);
        var service = new ReviewService(db, new FixedClock());

        var ex = await Assert.ThrowsAsync<AppException>(() =>
            service.CreateAsync(seed.CustomerId, new CreateReviewRequest(seed.AppointmentId, 5, "Harika"), CancellationToken.None));

        Assert.Equal(422, ex.StatusCode);
        Assert.Contains("tamamlanmış", ex.Message);
    }

    [Fact]
    public async Task Create_review_requires_ownership()
    {
        await using var db = CreateDb();
        var seed = await SeedAsync(db, AppointmentStatus.Completed);
        var otherUser = new User { FullName = "Other", PhoneNumber = "+905559999999", IsPhoneVerified = true };
        db.Users.Add(otherUser);
        await db.SaveChangesAsync();

        var service = new ReviewService(db, new FixedClock());

        var ex = await Assert.ThrowsAsync<AppException>(() =>
            service.CreateAsync(otherUser.Id, new CreateReviewRequest(seed.AppointmentId, 5, "Harika"), CancellationToken.None));

        Assert.Equal(403, ex.StatusCode);
    }

    [Fact]
    public async Task Create_review_allows_only_one_per_appointment()
    {
        await using var db = CreateDb();
        var seed = await SeedAsync(db, AppointmentStatus.Completed);
        var service = new ReviewService(db, new FixedClock());

        await service.CreateAsync(seed.CustomerId, new CreateReviewRequest(seed.AppointmentId, 5, "Harika"), CancellationToken.None);

        var ex = await Assert.ThrowsAsync<AppException>(() =>
            service.CreateAsync(seed.CustomerId, new CreateReviewRequest(seed.AppointmentId, 4, "İyi"), CancellationToken.None));

        Assert.Equal(409, ex.StatusCode);
        Assert.Contains("zaten yorum", ex.Message);
    }

    [Fact]
    public async Task Create_review_validates_rating_range()
    {
        await using var db = CreateDb();
        var seed = await SeedAsync(db, AppointmentStatus.Completed);
        var service = new ReviewService(db, new FixedClock());

        var ex = await Assert.ThrowsAsync<AppException>(() =>
            service.CreateAsync(seed.CustomerId, new CreateReviewRequest(seed.AppointmentId, 0, null), CancellationToken.None));

        Assert.Equal(422, ex.StatusCode);
    }

    [Fact]
    public async Task Create_review_validates_rating_range_upper()
    {
        await using var db = CreateDb();
        var seed = await SeedAsync(db, AppointmentStatus.Completed);
        var service = new ReviewService(db, new FixedClock());

        var ex = await Assert.ThrowsAsync<AppException>(() =>
            service.CreateAsync(seed.CustomerId, new CreateReviewRequest(seed.AppointmentId, 6, null), CancellationToken.None));

        Assert.Equal(422, ex.StatusCode);
    }

    [Fact]
    public async Task Create_review_updates_shop_rating()
    {
        await using var db = CreateDb();
        var seed = await SeedAsync(db, AppointmentStatus.Completed);
        var service = new ReviewService(db, new FixedClock());

        var review = await service.CreateAsync(seed.CustomerId, new CreateReviewRequest(seed.AppointmentId, 4, "İyi"), CancellationToken.None);
        await service.ApproveAsync(review.Id, CancellationToken.None);

        var shop = await db.BarberShops.FirstAsync(x => x.Id == seed.ShopId);
        Assert.Equal(4m, shop.AverageRating);
        Assert.Equal(1, shop.ReviewCount);
    }

    [Fact]
    public async Task Approve_review_requires_pending()
    {
        await using var db = CreateDb();
        var seed = await SeedAsync(db, AppointmentStatus.Completed);
        var service = new ReviewService(db, new FixedClock());

        var review = await service.CreateAsync(seed.CustomerId, new CreateReviewRequest(seed.AppointmentId, 5, "Harika"), CancellationToken.None);
        await service.ApproveAsync(review.Id, CancellationToken.None);

        var ex = await Assert.ThrowsAsync<AppException>(() =>
            service.ApproveAsync(review.Id, CancellationToken.None));

        Assert.Equal(409, ex.StatusCode);
    }

    [Fact]
    public async Task Get_pending_returns_only_unapproved()
    {
        await using var db = CreateDb();
        var seed = await SeedAsync(db, AppointmentStatus.Completed);
        var service = new ReviewService(db, new FixedClock());

        var review = await service.CreateAsync(seed.CustomerId, new CreateReviewRequest(seed.AppointmentId, 5, "Harika"), CancellationToken.None);

        var pending = await service.GetPendingAsync(CancellationToken.None);
        Assert.Single(pending);
        Assert.Equal(review.Id, pending[0].Id);

        await service.ApproveAsync(review.Id, CancellationToken.None);

        pending = await service.GetPendingAsync(CancellationToken.None);
        Assert.Empty(pending);
    }

    private static AppDbContext CreateDb()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
        return new AppDbContext(options);
    }

    private static async Task<SeedData> SeedAsync(AppDbContext db, AppointmentStatus appointmentStatus)
    {
        var customer = new User { FullName = "Customer", PhoneNumber = "+905551111111", IsPhoneVerified = true };
        var owner = new User { FullName = "Owner", PhoneNumber = "+905552222222", IsPhoneVerified = true, Role = UserRole.BarberOwner };
        var shop = new BarberShop
        {
            OwnerUserId = owner.Id,
            Name = "Test Barber",
            City = "İstanbul",
            District = "Kadıköy",
            Address = "Test",
            IsApproved = true,
            IsActive = true
        };
        var service = new BarberService { BarberShopId = shop.Id, Name = "Saç Kesimi", DurationMinutes = 30, Price = 250 };
        var staff = new StaffMember { BarberShopId = shop.Id, FullName = "Test Usta", IsActive = true };
        var appointment = new Appointment
        {
            CustomerUserId = customer.Id,
            BarberShopId = shop.Id,
            StaffMemberId = staff.Id,
            AppointmentDate = new DateOnly(2026, 4, 23),
            StartTime = new TimeOnly(10, 0),
            EndTime = new TimeOnly(10, 30),
            TotalDurationMinutes = 30,
            TotalPrice = 250,
            Status = appointmentStatus,
            CompletedAt = appointmentStatus == AppointmentStatus.Completed ? new DateTime(2026, 4, 23, 10, 30, 0, DateTimeKind.Utc) : null
        };

        db.Users.AddRange(customer, owner);
        db.BarberShops.Add(shop);
        db.BarberServices.Add(service);
        db.StaffMembers.Add(staff);
        db.StaffServices.Add(new BerberYanimda.Domain.StaffService { StaffMemberId = staff.Id, BarberServiceId = service.Id });
        db.Appointments.Add(appointment);
        await db.SaveChangesAsync();

        return new SeedData(customer.Id, shop.Id, staff.Id, service.Id, appointment.Id);
    }

    private sealed class FixedClock : IDateTimeProvider
    {
        public DateTime UtcNow => new(2026, 4, 24, 12, 0, 0, DateTimeKind.Utc);
        public DateOnly Today => new(2026, 4, 24);
    }

    private sealed record SeedData(Guid CustomerId, Guid ShopId, Guid StaffId, Guid ServiceId, Guid AppointmentId);
}
