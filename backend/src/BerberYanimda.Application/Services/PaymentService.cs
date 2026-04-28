using BerberYanimda.Application.Common;
using BerberYanimda.Application.DTOs;
using BerberYanimda.Application.Interfaces;
using BerberYanimda.Domain;
using Microsoft.EntityFrameworkCore;

namespace BerberYanimda.Application.Services;

public sealed class PaymentService(IAppDbContext db, IDateTimeProvider clock, IPaymentProviderFactory paymentProviderFactory, IAuditLogService auditLog)
{
    public async Task<PaymentDto> PayAtBarberAsync(Guid userId, PayAtBarberRequest request, CancellationToken ct)
    {
        var appointment = await db.Appointments
            .FirstOrDefaultAsync(x => x.Id == request.AppointmentId && x.CustomerUserId == userId, ct)
            ?? throw new AppException("Randevu bulunamadı.", 404);

        if (appointment.Status == AppointmentStatus.Cancelled)
        {
            throw new AppException("İptal edilmiş randevu için ödeme yöntemi seçilemez.", 409);
        }

        var existing = await db.Payments.FirstOrDefaultAsync(x => x.AppointmentId == appointment.Id, ct);
        if (existing is not null)
        {
            return ToDto(existing);
        }

        var payment = new Payment
        {
            AppointmentId = appointment.Id,
            CustomerUserId = userId,
            PaymentMethod = PaymentMethod.PayAtBarber,
            Status = PaymentStatus.Pending,
            Amount = appointment.TotalPrice,
            Currency = "TRY",
            CreatedAt = clock.UtcNow
        };

        appointment.Status = AppointmentStatus.Confirmed;
        appointment.UpdatedAt = clock.UtcNow;
        db.Payments.Add(payment);
        db.Notifications.Add(new Notification
        {
            UserId = userId,
            Title = "Randevu onaylandı",
            Message = "Berberde öde seçeneği ile randevunuz onaylandı.",
            Type = NotificationType.AppointmentConfirmed,
            CreatedAt = clock.UtcNow
        });

        await db.SaveChangesAsync(ct);
        return ToDto(payment);
    }

    public async Task<PaymentSessionDto> CreateOnlinePaymentSessionAsync(Guid userId, CreatePaymentSessionRequest request, CancellationToken ct)
    {
        var appointment = await db.Appointments
            .Include(x => x.BarberShop)
            .FirstOrDefaultAsync(x => x.Id == request.AppointmentId && x.CustomerUserId == userId, ct)
            ?? throw new AppException("Randevu bulunamadı.", 404);

        if (appointment.Status == AppointmentStatus.Cancelled)
        {
            throw new AppException("İptal edilmiş randevu için ödeme başlatılamaz.", 409);
        }

        var existingPayment = await db.Payments.FirstOrDefaultAsync(x => x.AppointmentId == appointment.Id, ct);
        if (existingPayment is not null && existingPayment.Status == PaymentStatus.Paid)
        {
            throw new AppException("Bu randevu için ödeme zaten yapılmış.", 409);
        }

        var customer = await db.Users.FirstOrDefaultAsync(x => x.Id == userId, ct)
            ?? throw new AppException("Kullanıcı bulunamadı.", 404);

        var provider = paymentProviderFactory.GetDefaultProvider();

        var sessionRequest = new PaymentSessionRequest(
            AppointmentId: appointment.Id,
            CustomerUserId: userId,
            Amount: appointment.TotalPrice,
            Currency: "TRY",
            CustomerEmail: customer.Email ?? "",
            CustomerPhone: customer.PhoneNumber,
            Description: $"{appointment.BarberShop?.Name} - Randevu #{appointment.Id}");

        var session = await provider.CreateSessionAsync(sessionRequest, ct);
        if (string.IsNullOrWhiteSpace(session.SessionId) ||
            session.Amount != appointment.TotalPrice ||
            !string.Equals(session.Currency, "TRY", StringComparison.OrdinalIgnoreCase))
        {
            throw new AppException("Ödeme sağlayıcı oturumu doğrulanamadı.", 502);
        }

        if (existingPayment is not null)
        {
            existingPayment.PaymentProvider = provider.ProviderName;
            existingPayment.ProviderTransactionId = session.SessionId;
            existingPayment.Amount = session.Amount;
            existingPayment.Currency = session.Currency;
            existingPayment.UpdatedAt = clock.UtcNow;
        }
        else
        {
            var payment = new Payment
            {
                AppointmentId = appointment.Id,
                CustomerUserId = userId,
                PaymentMethod = PaymentMethod.Online,
                PaymentProvider = provider.ProviderName,
                ProviderTransactionId = session.SessionId,
                Status = PaymentStatus.Pending,
                Amount = session.Amount,
                Currency = session.Currency,
                CreatedAt = clock.UtcNow
            };
            db.Payments.Add(payment);
        }

        await db.SaveChangesAsync(ct);

        return new PaymentSessionDto(
            session.SessionId,
            session.RedirectUrl,
            session.Amount,
            session.Currency);
    }

    public async Task HandleWebhookAsync(string providerName, string payload, string signature, CancellationToken ct)
    {
        var provider = paymentProviderFactory.GetProvider(providerName);
        var verification = await provider.VerifyWebhookAsync(payload, signature, ct);

        if (!verification.IsValid)
        {
            throw new AppException("Webhook doğrulama başarısız.", 400);
        }

        if (string.IsNullOrWhiteSpace(verification.ProviderTransactionId))
        {
            throw new AppException("Webhook transaction bilgisi eksik.", 400);
        }

        var payment = await db.Payments
            .Include(x => x.Appointment)
            .FirstOrDefaultAsync(x =>
                x.ProviderTransactionId == verification.ProviderTransactionId &&
                x.PaymentProvider == provider.ProviderName, ct)
            ?? throw new AppException("Ödeme kaydı bulunamadı.", 404);

        if (payment.Amount != verification.Amount ||
            !string.Equals(payment.Currency, verification.Currency, StringComparison.OrdinalIgnoreCase))
        {
            throw new AppException("Webhook ödeme tutarı veya para birimi uyuşmuyor.", 409);
        }

        if (payment.Status == PaymentStatus.Paid)
        {
            return;
        }

        if (verification.Status == "paid" || verification.Status == "success")
        {
            payment.Status = PaymentStatus.Paid;
            payment.PaidAt = clock.UtcNow;

            if (payment.Appointment is not null)
            {
                payment.Appointment.Status = AppointmentStatus.Confirmed;
                payment.Appointment.UpdatedAt = clock.UtcNow;

                db.Notifications.Add(new Notification
                {
                    UserId = payment.CustomerUserId,
                    Title = "Ödeme başarılı",
                    Message = "Ödemeniz alındı. Randevunuz onaylandı.",
                    Type = NotificationType.PaymentSuccess,
                    CreatedAt = clock.UtcNow
                });
            }
        }
        else if (verification.Status == "failed" || verification.Status == "cancelled")
        {
            payment.Status = PaymentStatus.Failed;
            payment.FailedReason = verification.FailureReason;

            db.Notifications.Add(new Notification
            {
                UserId = payment.CustomerUserId,
                Title = "Ödeme başarısız",
                Message = "Ödeme işlemi başarısız oldu. Lütfen tekrar deneyin.",
                Type = NotificationType.PaymentFailed,
                CreatedAt = clock.UtcNow
            });
        }

        await auditLog.LogAsync(payment.CustomerUserId, $"PAYMENT_{payment.Status}",
            nameof(Payment), payment.Id.ToString(), newValue: payment.Status.ToString(), ct: ct);

        await db.SaveChangesAsync(ct);
    }

    private static PaymentDto ToDto(Payment payment) =>
        new(payment.Id, payment.AppointmentId, payment.PaymentMethod, payment.Status, payment.Amount, payment.Currency);
}
