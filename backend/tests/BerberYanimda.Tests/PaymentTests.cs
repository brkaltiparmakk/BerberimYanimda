using BerberYanimda.Application.Common;
using BerberYanimda.Application.Interfaces;
using BerberYanimda.Application.Services;
using BerberYanimda.Domain;
using BerberYanimda.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace BerberYanimda.Tests;

public sealed class PaymentTests
{
    [Fact]
    public async Task Webhook_rejects_amount_mismatch()
    {
        await using var db = CreateDb();
        var seed = await SeedPaymentAsync(db);
        var service = new PaymentService(
            db,
            new FixedClock(),
            new FakePaymentProviderFactory(new PaymentVerificationResult(true, seed.TransactionId, "paid", 249, "TRY", null)),
            new NoOpAuditLogService());

        var ex = await Assert.ThrowsAsync<AppException>(() =>
            service.HandleWebhookAsync("fake", "{}", "valid-signature", CancellationToken.None));

        Assert.Equal(409, ex.StatusCode);
        Assert.Equal(PaymentStatus.Pending, (await db.Payments.SingleAsync()).Status);
    }

    [Fact]
    public async Task Webhook_marks_payment_and_appointment_paid_when_amount_matches()
    {
        await using var db = CreateDb();
        var seed = await SeedPaymentAsync(db);
        var service = new PaymentService(
            db,
            new FixedClock(),
            new FakePaymentProviderFactory(new PaymentVerificationResult(true, seed.TransactionId, "paid", 250, "TRY", null)),
            new NoOpAuditLogService());

        await service.HandleWebhookAsync("fake", "{}", "valid-signature", CancellationToken.None);

        var payment = await db.Payments.Include(x => x.Appointment).SingleAsync();
        Assert.Equal(PaymentStatus.Paid, payment.Status);
        Assert.Equal(AppointmentStatus.Confirmed, payment.Appointment?.Status);
    }

    private static AppDbContext CreateDb()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
        return new AppDbContext(options);
    }

    private static async Task<SeedIds> SeedPaymentAsync(AppDbContext db)
    {
        var customer = new User { FullName = "Customer", PhoneNumber = "+905551111111", IsPhoneVerified = true };
        var shop = new BarberShop
        {
            OwnerUserId = customer.Id,
            Name = "Modern Barber",
            City = "Istanbul",
            District = "Kadikoy",
            Address = "Moda",
            IsApproved = true,
            IsActive = true
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
            Status = AppointmentStatus.Pending
        };
        const string transactionId = "txn-123";
        var payment = new Payment
        {
            AppointmentId = appointment.Id,
            CustomerUserId = customer.Id,
            PaymentMethod = PaymentMethod.Online,
            PaymentProvider = FakePaymentProvider.Name,
            ProviderTransactionId = transactionId,
            Status = PaymentStatus.Pending,
            Amount = 250,
            Currency = "TRY"
        };

        db.Users.Add(customer);
        db.BarberShops.Add(shop);
        db.Appointments.Add(appointment);
        db.Payments.Add(payment);
        await db.SaveChangesAsync();
        return new SeedIds(transactionId);
    }

    private sealed class FixedClock : IDateTimeProvider
    {
        public DateTime UtcNow => new(2026, 4, 24, 12, 0, 0, DateTimeKind.Utc);
        public DateOnly Today => new(2026, 4, 24);
    }

    private sealed class FakePaymentProviderFactory(PaymentVerificationResult verification) : IPaymentProviderFactory
    {
        public IPaymentProvider GetProvider(string providerName) => new FakePaymentProvider(verification);
        public IPaymentProvider GetDefaultProvider() => new FakePaymentProvider(verification);
    }

    private sealed class FakePaymentProvider(PaymentVerificationResult verification) : IPaymentProvider
    {
        public const string Name = "FakePay";
        public string ProviderName => Name;

        public Task<PaymentSessionResult> CreateSessionAsync(PaymentSessionRequest request, CancellationToken ct) =>
            Task.FromResult(new PaymentSessionResult("txn-123", "https://payments.example/txn-123", request.Amount, request.Currency));

        public Task<PaymentVerificationResult> VerifyWebhookAsync(string payload, string signature, CancellationToken ct) =>
            Task.FromResult(verification);
    }

    private sealed record SeedIds(string TransactionId);
}
