namespace BerberYanimda.Application.Interfaces;

public interface IPaymentProvider
{
    string ProviderName { get; }
    Task<PaymentSessionResult> CreateSessionAsync(PaymentSessionRequest request, CancellationToken ct);
    Task<PaymentVerificationResult> VerifyWebhookAsync(string payload, string signature, CancellationToken ct);
}

public sealed record PaymentSessionRequest(
    Guid AppointmentId,
    Guid CustomerUserId,
    decimal Amount,
    string Currency,
    string CustomerEmail,
    string CustomerPhone,
    string Description);

public sealed record PaymentSessionResult(
    string SessionId,
    string RedirectUrl,
    decimal Amount,
    string Currency);

public sealed record PaymentVerificationResult(
    bool IsValid,
    string? ProviderTransactionId,
    string Status,
    decimal Amount,
    string Currency,
    string? FailureReason);

public interface IPaymentProviderFactory
{
    IPaymentProvider GetProvider(string providerName);
    IPaymentProvider GetDefaultProvider();
}
