using BerberYanimda.Application.Interfaces;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace BerberYanimda.Infrastructure.Payments;

public sealed class PayAtBarberProvider : IPaymentProvider
{
    public string ProviderName => "PayAtBarber";

    public Task<PaymentSessionResult> CreateSessionAsync(PaymentSessionRequest request, CancellationToken ct)
    {
        var result = new PaymentSessionResult(
            SessionId: $"PAB-{request.AppointmentId:N}",
            RedirectUrl: string.Empty,
            Amount: request.Amount,
            Currency: request.Currency);

        return Task.FromResult(result);
    }

    public Task<PaymentVerificationResult> VerifyWebhookAsync(string payload, string signature, CancellationToken ct)
    {
        throw new NotSupportedException("PayAtBarber does not support webhooks.");
    }
}

public sealed class SandboxOnlinePaymentProvider : IPaymentProvider
{
    public string ProviderName => "SandboxOnline";

    public Task<PaymentSessionResult> CreateSessionAsync(PaymentSessionRequest request, CancellationToken ct)
    {
        var sessionId = $"SND-{request.AppointmentId:N}-{Guid.NewGuid():N}";
        var result = new PaymentSessionResult(
            SessionId: sessionId,
            RedirectUrl: $"/sandbox-payment?sessionId={sessionId}",
            Amount: request.Amount,
            Currency: request.Currency);

        return Task.FromResult(result);
    }

    public Task<PaymentVerificationResult> VerifyWebhookAsync(string payload, string signature, CancellationToken ct)
    {
        // Sandbox webhook: accept any payload with "sandbox-success" signature as paid
        var isSuccess = string.Equals(signature, "sandbox-success", StringComparison.OrdinalIgnoreCase);
        var isFailed = string.Equals(signature, "sandbox-failed", StringComparison.OrdinalIgnoreCase);

        if (!isSuccess && !isFailed)
        {
            return Task.FromResult(new PaymentVerificationResult(
                IsValid: false,
                ProviderTransactionId: string.Empty,
                Status: string.Empty,
                Amount: 0,
                Currency: string.Empty,
                FailureReason: "Invalid sandbox signature"));
        }

        // Parse minimal payload to extract transaction id
        var txnId = string.Empty;
        if (!string.IsNullOrWhiteSpace(payload))
        {
            var parts = payload.Split(',');
            foreach (var part in parts)
            {
                var kv = part.Split(':');
                if (kv.Length == 2 && kv[0].Trim() == "txn")
                {
                    txnId = kv[1].Trim();
                }
            }
        }

        return Task.FromResult(new PaymentVerificationResult(
            IsValid: true,
            ProviderTransactionId: txnId,
            Status: isSuccess ? "paid" : "failed",
            Amount: 0, // Will be matched against stored payment record
            Currency: "TRY",
            FailureReason: isFailed ? "Sandbox payment declined" : null));
    }
}

public sealed class NullOnlinePaymentProvider : IPaymentProvider
{
    public string ProviderName => "Online";

    public Task<PaymentSessionResult> CreateSessionAsync(PaymentSessionRequest request, CancellationToken ct)
    {
        throw new NotImplementedException("Online ödeme henüz aktif değil. Lütfen ödeme sağlayıcınızı yapılandırın.");
    }

    public Task<PaymentVerificationResult> VerifyWebhookAsync(string payload, string signature, CancellationToken ct)
    {
        throw new NotImplementedException("Online ödeme henüz aktif değil.");
    }
}

public sealed class PaymentProviderFactory : IPaymentProviderFactory
{
    private readonly IServiceProvider _serviceProvider;
    private readonly bool _useSandbox;

    public PaymentProviderFactory(IServiceProvider serviceProvider, IConfiguration configuration)
    {
        _serviceProvider = serviceProvider;
        _useSandbox = string.Equals(configuration["Payments:UseSandbox"], "true", StringComparison.OrdinalIgnoreCase);
    }

    public IPaymentProvider GetProvider(string providerName)
    {
        return providerName.ToLowerInvariant() switch
        {
            "payatbarber" => new PayAtBarberProvider(),
            "sandboxonline" => new SandboxOnlinePaymentProvider(),
            "iyzico" => _serviceProvider.GetRequiredService<IyzicoPaymentProvider>(),
            "online" => _useSandbox ? new SandboxOnlinePaymentProvider() : new NullOnlinePaymentProvider(),
            _ => throw new ArgumentException($"Bilinmeyen ödeme sağlayıcısı: {providerName}")
        };
    }

    public IPaymentProvider GetDefaultProvider()
    {
        return _useSandbox ? new SandboxOnlinePaymentProvider() : new PayAtBarberProvider();
    }
}
