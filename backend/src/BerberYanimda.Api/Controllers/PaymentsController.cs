using BerberYanimda.Api.Extensions;
using BerberYanimda.Application.Common;
using BerberYanimda.Application.DTOs;
using BerberYanimda.Application.Services;
using BerberYanimda.Domain;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BerberYanimda.Api.Controllers;

[ApiController]
[Authorize(Roles = nameof(UserRole.Customer))]
[Route("api/v1/payments")]
public sealed class PaymentsController(PaymentService paymentService) : ControllerBase
{
    [HttpPost("pay-at-barber")]
    public async Task<ActionResult<ApiResponse<PaymentDto>>> PayAtBarber(PayAtBarberRequest request, CancellationToken ct)
    {
        var result = await paymentService.PayAtBarberAsync(User.GetUserId(), request, ct);
        return Ok(ApiResponse<PaymentDto>.Ok(result, "Berberde öde seçildi."));
    }

    [HttpPost("create-session")]
    public async Task<ActionResult<ApiResponse<PaymentSessionDto>>> CreateSession(CreatePaymentSessionRequest request, CancellationToken ct)
    {
        var result = await paymentService.CreateOnlinePaymentSessionAsync(User.GetUserId(), request, ct);
        return Ok(ApiResponse<PaymentSessionDto>.Ok(result, "Ödeme oturumu oluşturuldu."));
    }

    [HttpPost("webhook/{provider}")]
    [AllowAnonymous]
    public async Task<ActionResult<ApiResponse<object>>> Webhook(string provider, CancellationToken ct)
    {
        using var reader = new StreamReader(Request.Body);
        var payload = await reader.ReadToEndAsync(ct);
        var signature = Request.Headers["X-Webhook-Signature"].FirstOrDefault() ?? string.Empty;

        await paymentService.HandleWebhookAsync(provider, payload, signature, ct);
        return Ok(ApiResponse<object>.Ok(new { }, "Webhook işlendi."));
    }

    [HttpPost("sandbox/complete")]
    [Authorize(Roles = nameof(UserRole.Customer))]
    public async Task<ActionResult<ApiResponse<object>>> SandboxComplete(SandboxCompleteRequest request, CancellationToken ct)
    {
        var payload = $"txn:{request.SessionId}";
        var signature = request.Success ? "sandbox-success" : "sandbox-failed";
        await paymentService.HandleWebhookAsync("sandboxonline", payload, signature, ct);
        return Ok(ApiResponse<object>.Ok(new { }, request.Success ? "Ödeme başarılı." : "Ödeme başarısız."));
    }
}

public sealed record SandboxCompleteRequest(string SessionId, bool Success);
