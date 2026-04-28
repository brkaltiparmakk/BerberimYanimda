using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using BerberYanimda.Application.Interfaces;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace BerberYanimda.Infrastructure.Payments;

public sealed class IyzicoPaymentProvider : IPaymentProvider
{
    private readonly HttpClient _http;
    private readonly IyzicoConfig _config;
    private readonly ILogger<IyzicoPaymentProvider> _logger;

    public IyzicoPaymentProvider(HttpClient http, IConfiguration config, ILogger<IyzicoPaymentProvider> logger)
    {
        _http = http;
        _config = config.GetSection("Payment:Iyzico").Get<IyzicoConfig>() ?? new();
        _logger = logger;
    }

    public string ProviderName => "iyzico";

    public async Task<PaymentSessionResult> CreateSessionAsync(PaymentSessionRequest request, CancellationToken ct)
    {
        var customerName = ExtractNameFromEmail(request.CustomerEmail);

        var checkoutForm = new
        {
            locale = "tr",
            conversationId = request.AppointmentId.ToString(),
            price = request.Amount.ToString("F2"),
            paidPrice = request.Amount.ToString("F2"),
            currency = request.Currency ?? "TRY",
            basketId = $"B{request.AppointmentId:N}",
            paymentGroup = "PRODUCT",
            callbackUrl = _config.CallbackUrl,
            enabledInstallments = new[] { 1 },
            buyer = new
            {
                id = request.CustomerUserId.ToString(),
                name = customerName,
                surname = "",
                gsmNumber = request.CustomerPhone ?? "+905550000000",
                email = request.CustomerEmail ?? "musteri@example.com",
                identityNumber = "11111111111",
                registrationAddress = "N/A",
                city = "Istanbul",
                country = "Turkey",
                zipCode = "34000"
            },
            billingAddress = new
            {
                contactName = customerName,
                city = "Istanbul",
                country = "Turkey",
                address = "N/A"
            }
        };

        var json = JsonSerializer.Serialize(checkoutForm);
        var content = new StringContent(json, Encoding.UTF8, "application/json");
        AddAuthHeaders(json);

        var response = await _http.PostAsync($"{_config.BaseUrl}/payment/checkoutform/initialize", content, ct);
        var body = await response.Content.ReadAsStringAsync(ct);
        var result = JsonSerializer.Deserialize<JsonElement>(body);

        if (result.GetProperty("status").GetString() == "success")
        {
            var token = result.GetProperty("token").GetString()!;
            return new PaymentSessionResult(token, $"{_config.BaseUrl}/payment/checkoutform/initialize?token={token}", request.Amount, request.Currency ?? "TRY");
        }

        var error = result.GetProperty("errorMessage").GetString();
        _logger.LogError("Iyzico session error: {Error}", error);
        throw new PaymentException($"Iyzico oturum hatasi: {error}");
    }

    public async Task<PaymentVerificationResult> VerifyWebhookAsync(string payload, string signature, CancellationToken ct)
    {
        var callback = JsonSerializer.Deserialize<JsonElement>(payload);
        var token = callback.GetProperty("token").GetString();
        if (string.IsNullOrEmpty(token))
            return new PaymentVerificationResult(false, null, "", 0, "", "Token not found in callback");

        var json = JsonSerializer.Serialize(new { token });
        var content = new StringContent(json, Encoding.UTF8, "application/json");
        AddAuthHeaders(json);

        var response = await _http.PostAsync($"{_config.BaseUrl}/payment/iyzipos/checkoutform/auth/v2/retrieve", content, ct);
        var body = await response.Content.ReadAsStringAsync(ct);
        var result = JsonSerializer.Deserialize<JsonElement>(body);

        if (result.GetProperty("status").GetString() == "success")
        {
            var paymentStatus = result.GetProperty("paymentStatus").GetString();
            var isSuccess = paymentStatus == "SUCCESS";
            var transactionId = result.GetProperty("paymentId").GetString()!;
            var amount = result.GetProperty("paidPrice").GetDecimal();
            return new PaymentVerificationResult(isSuccess, transactionId, paymentStatus ?? "", amount, "TRY", isSuccess ? null : paymentStatus);
        }

        return new PaymentVerificationResult(false, null, "", 0, "", result.GetProperty("errorMessage").GetString());
    }

    private void AddAuthHeaders(string content)
    {
        var random = Guid.NewGuid().ToString();
        var hash = ComputeIyzicoHash(_config.ApiKey, _config.SecretKey, random, content);
        _http.DefaultRequestHeaders.Remove("Authorization");
        _http.DefaultRequestHeaders.Remove("x-iyzi-rnd");
        _http.DefaultRequestHeaders.TryAddWithoutValidation("Authorization", $"IYZWS {_config.ApiKey}:{hash}");
        _http.DefaultRequestHeaders.TryAddWithoutValidation("x-iyzi-rnd", random);
    }

    private static string ComputeIyzicoHash(string apiKey, string secretKey, string random, string content)
    {
        var data = apiKey + random + secretKey + content;
        var hash = SHA256.HashData(Encoding.UTF8.GetBytes(data));
        return Convert.ToBase64String(hash);
    }

    private static string ExtractNameFromEmail(string? email)
    {
        if (string.IsNullOrWhiteSpace(email))
            return "Musteri";
        var atIndex = email.IndexOf('@');
        return atIndex > 0 ? email[..atIndex] : email;
    }
}

public sealed class IyzicoConfig
{
    public string BaseUrl { get; set; } = "https://sandbox-api.iyzipay.com";
    public string ApiKey { get; set; } = "";
    public string SecretKey { get; set; } = "";
    public string CallbackUrl { get; set; } = "";
    public bool Enabled { get; set; }
}

public sealed class PaymentException : Exception
{
    public PaymentException(string message) : base(message) { }
    public PaymentException(string message, Exception inner) : base(message, inner) { }
}
