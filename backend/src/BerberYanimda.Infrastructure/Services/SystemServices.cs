using BerberYanimda.Application.Interfaces;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System.Net.Http.Json;

namespace BerberYanimda.Infrastructure.Services;

public sealed class SystemDateTimeProvider : IDateTimeProvider
{
    public DateTime UtcNow => DateTime.UtcNow;
    public DateOnly Today => DateOnly.FromDateTime(DateTime.UtcNow);
}

public sealed class MockSmsSender(ILogger<MockSmsSender> logger) : ISmsSender
{
    public Task SendOtpAsync(string phoneNumber, string code, CancellationToken cancellationToken)
    {
        logger.LogInformation("Mock OTP for {PhoneNumber}: {OtpCode}", MaskPhone(phoneNumber), code);
        return Task.CompletedTask;
    }

    private static string MaskPhone(string phone)
    {
        if (phone.Length < 4)
        {
            return "****";
        }

        return $"{phone[..Math.Min(4, phone.Length)]}******{phone[^2..]}";
    }
}

public sealed class HttpSmsSender(HttpClient httpClient, IConfiguration configuration, ILogger<HttpSmsSender> logger) : ISmsSender
{
    public async Task SendOtpAsync(string phoneNumber, string code, CancellationToken cancellationToken)
    {
        var endpoint = configuration["Sms:Endpoint"];
        var apiKey = configuration["Sms:ApiKey"];
        if (string.IsNullOrWhiteSpace(endpoint) || string.IsNullOrWhiteSpace(apiKey))
        {
            throw new InvalidOperationException("SMS provider configuration is missing.");
        }

        using var request = new HttpRequestMessage(HttpMethod.Post, endpoint)
        {
            Content = JsonContent.Create(new
            {
                to = phoneNumber,
                code,
                message = $"Berber Yanimda dogrulama kodu: {code}"
            })
        };
        request.Headers.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", apiKey);

        var response = await httpClient.SendAsync(request, cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            logger.LogWarning("SMS provider returned {StatusCode} for {PhoneNumber}", response.StatusCode, MaskPhone(phoneNumber));
            response.EnsureSuccessStatusCode();
        }
    }

    private static string MaskPhone(string phone)
    {
        if (phone.Length < 4)
        {
            return "****";
        }

        return $"{phone[..Math.Min(4, phone.Length)]}******{phone[^2..]}";
    }
}
