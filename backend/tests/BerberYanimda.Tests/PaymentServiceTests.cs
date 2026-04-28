using BerberYanimda.Application.Common;
using BerberYanimda.Application.DTOs;
using BerberYanimda.Application.Interfaces;
using BerberYanimda.Application.Services;
using BerberYanimda.Domain;
using BerberYanimda.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace BerberYanimda.Tests;

public sealed class PaymentServiceTests
{
    [Fact]
    public async Task PayAtBarberAsync_creates_payment_and_confirms()
    {
        await using var db = CreateDb();
        var seed = await SeedAppointmentAsync(db, AppointmentStatus.Pending);
        var service = CreatePaymentService(db);

        var result = await service.PayAtBarberAsync(seed.CustomerId, new PayAtBarberRequest(seed.AppointmentId), CancellationToken.None);

        Assert.Equal(seed.AppointmentId, result.AppointmentId);
        Assert.Equal(PaymentMethod.PayAtBarber, result.PaymentMethod);
        Assert.Equal(PaymentStatus.Pending, result.Status);
        Assert.Equal(250, result.Amount);
        Assert.Equal("TRY", result.Currency);

        var appointment = await db.Appointments.FindAsync(seed.AppointmentId);
        Assert.NotNull(appointment);
        Assert.Equal(AppointmentStatus.Confirmed, appointment.Status);

        var notification = await db.Notifications.FirstOrDefaultAsync(x => x.UserId == seed.CustomerId);
        Assert.NotNull(notification);
        Assert.Equal("Randevu onaylandı", notification.Title);
        Assert.Equal(NotificationType.AppointmentConfirmed, notification.Type);
    }

    [Fact]
    public async Task PayAtBarberAsync_rejects_invalid_appointment()
    {
        await using var db = CreateDb();
        var service = CreatePaymentService(db);

        var ex = await Assert.ThrowsAsync<AppException>(() =>
            service.PayAtBarberAsync(Guid.NewGuid(), new PayAtBarberRequest(Guid.NewGuid()), CancellationToken.None));

        Assert.Equal(404, ex.StatusCode);
    }

    [Fact]
    public async Task CreateOnlinePaymentSessionAsync_returns_session_url()
    {
        await using var db = CreateDb();
        var seed = await SeedAppointmentAsync(db, AppointmentStatus.Pending);
        var service = CreatePaymentService(db);

        var result = await service.CreateOnlinePaymentSessionAsync(seed.CustomerId, new CreatePaymentSessionRequest(seed.AppointmentId), CancellationToken.None);

        Assert.Equal("session_123", result.SessionId);
        Assert.Equal("https://payment.example.com/pay", result.RedirectUrl);
        Assert.Equal(250, result.Amount);
        Assert.Equal("TRY", result.Currency);

        var payment = await db.Payments.FirstOrDefaultAsync(x => x.AppointmentId == seed.AppointmentId);
        Assert.NotNull(payment);
        Assert.Equal(PaymentMethod.Online, payment.PaymentMethod);
        Assert.Equal(PaymentStatus.Pending, payment.Status);
    }

    [Fact]
    public async Task CreateOnlinePaymentSessionAsync_rejects_paid_appointment()
    {
        await using var db = CreateDb();
        var seed = await SeedAppointmentAsync(db, AppointmentStatus.Pending);
        db.Payments.Add(new Payment
        {
            AppointmentId = seed.AppointmentId,
            CustomerUserId = seed.CustomerId,
            PaymentMethod = PaymentMethod.Online,
            Status = PaymentStatus.Paid,
            Amount = 250,
            Currency = "TRY"
        });
        await db.SaveChangesAsync();
        var service = CreatePaymentService(db);

        var ex = await Assert.ThrowsAsync<AppException>(() =>
            service.CreateOnlinePaymentSessionAsync(seed.CustomerId, new CreatePaymentSessionRequest(seed.AppointmentId), CancellationToken.None));

        Assert.Equal(409, ex.StatusCode);
    }

    [Fact]
    public async Task HandleWebhookAsync_marks_payment_paid()
    {
        await using var db = CreateDb();
        var seed = await SeedAppointmentAsync(db, AppointmentStatus.Pending);
        const string transactionId = "txn-success-999";
        db.Payments.Add(new Payment
        {
            AppointmentId = seed.AppointmentId,
            CustomerUserId = seed.CustomerId,
            PaymentMethod = PaymentMethod.Online,
            PaymentProvider = "StubPay",
            ProviderTransactionId = transactionId,
            Status = PaymentStatus.Pending,
            Amount = 250,
            Currency = "TRY"
        });
        await db.SaveChangesAsync();

        var verification = new PaymentVerificationResult(true, transactionId, "paid", 250, "TRY", null);
        var factory = new StubPaymentProviderFactory(verification);
        var service = CreatePaymentService(db, factory);

        await service.HandleWebhookAsync("StubPay", "{}", "sig", CancellationToken.None);

        var payment = await db.Payments.Include(x => x.Appointment).FirstOrDefaultAsync(x => x.ProviderTransactionId == transactionId);
        Assert.NotNull(payment);
        Assert.Equal(PaymentStatus.Paid, payment.Status);
        Assert.NotNull(payment.PaidAt);
        Assert.Equal(AppointmentStatus.Confirmed, payment.Appointment?.Status);
    }

    [Fact]
    public async Task HandleWebhookAsync_rejects_unknown_payment()
    {
        await using var db = CreateDb();
        await SeedAppointmentAsync(db, AppointmentStatus.Pending);
        var verification = new PaymentVerificationResult(true, "nonexistent-txn", "paid", 250, "TRY", null);
        var factory = new StubPaymentProviderFactory(verification);
        var service = CreatePaymentService(db, factory);

        var ex = await Assert.ThrowsAsync<AppException>(() =>
            service.HandleWebhookAsync("StubPay", "{}", "sig", CancellationToken.None));

        Assert.Equal(404, ex.StatusCode);
    }

    private static AppDbContext CreateDb()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .ConfigureWarnings(warnings => warnings.Ignore(Microsoft.EntityFrameworkCore.Diagnostics.InMemoryEventId.TransactionIgnoredWarning))
            .Options;
        return new AppDbContext(options);
    }

    private static async Task<SeedData> SeedAppointmentAsync(AppDbContext db, AppointmentStatus status)
    {
        var customer = new User
        {
            FullName = "Test Customer",
            PhoneNumber = "+905551112233",
            IsPhoneVerified = true,
            Email = "customer@test.com"
        };
        var owner = new User
        {
            FullName = "Barber Owner",
            PhoneNumber = "+905554443322",
            IsPhoneVerified = true,
            Role = UserRole.BarberOwner
        };
        db.Users.Add(customer);
        db.Users.Add(owner);
        await db.SaveChangesAsync();

        var shop = new BarberShop
        {
            OwnerUserId = owner.Id,
            Name = "Test Barber Shop",
            City = "Istanbul",
            District = "Kadikoy",
            Address = "Test Address",
            IsApproved = true,
            IsActive = true
        };
        db.BarberShops.Add(shop);
        await db.SaveChangesAsync();

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
        db.Appointments.Add(appointment);
        await db.SaveChangesAsync();

        return new SeedData(customer.Id, appointment.Id, shop.Id);
    }

    private static PaymentService CreatePaymentService(AppDbContext db, IPaymentProviderFactory? factory = null)
    {
        return new PaymentService(
            db,
            new FixedClock(),
            factory ?? new StubPaymentProviderFactory(null),
            new NoOpAuditLogService());
    }

    private sealed record SeedData(Guid CustomerId, Guid AppointmentId, Guid ShopId);
}

public sealed class StubPaymentProvider(PaymentVerificationResult? verification) : IPaymentProvider
{
    private readonly PaymentVerificationResult _verification = verification ?? new PaymentVerificationResult(true, "transaction_456", "paid", 250, "TRY", null);

    public string ProviderName => "StubPay";

    public Task<PaymentSessionResult> CreateSessionAsync(PaymentSessionRequest request, CancellationToken ct)
        => Task.FromResult(new PaymentSessionResult("session_123", "https://payment.example.com/pay", request.Amount, request.Currency));

    public Task<PaymentVerificationResult> VerifyWebhookAsync(string payload, string signature, CancellationToken ct)
        => Task.FromResult(_verification);
}

public sealed class StubPaymentProviderFactory(PaymentVerificationResult? verification) : IPaymentProviderFactory
{
    public IPaymentProvider GetProvider(string providerName) => new StubPaymentProvider(verification);

    public IPaymentProvider GetDefaultProvider() => new StubPaymentProvider(verification);
}
