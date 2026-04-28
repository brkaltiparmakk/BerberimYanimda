using BerberYanimda.Api.Extensions;
using BerberYanimda.Application.Common;
using BerberYanimda.Application.DTOs;
using BerberYanimda.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.AspNetCore.Mvc;

namespace BerberYanimda.Api.Controllers;

[ApiController]
[EnableRateLimiting("Auth")]
[Route("api/v1/auth")]
public sealed class AuthController(AuthService authService) : ControllerBase
{
    [HttpPost("register")]
    public async Task<ActionResult<ApiResponse<object>>> Register(RegisterRequest request, CancellationToken ct)
    {
        await authService.RegisterAsync(request, ct);
        return Created(string.Empty, ApiResponse<object>.Ok(new { }, "Kayıt başarılı. Telefon doğrulama kodu gönderildi."));
    }

    [HttpPost("login")]
    public async Task<ActionResult<ApiResponse<LoginResult>>> Login(LoginRequest request, CancellationToken ct)
    {
        var result = await authService.LoginAsync(request, HttpContext.Connection.RemoteIpAddress?.ToString(), Request.Headers.UserAgent, ct);
        return Ok(ApiResponse<LoginResult>.Ok(result));
    }

    [HttpPost("verify-otp")]
    public async Task<ActionResult<ApiResponse<object>>> VerifyOtp(VerifyOtpRequest request, CancellationToken ct)
    {
        await authService.VerifyOtpAsync(request, ct);
        return Ok(ApiResponse<object>.Ok(new { }, "Telefon doğrulandı."));
    }

    [HttpPost("verify-mfa")]
    public async Task<ActionResult<ApiResponse<TokenResponse>>> VerifyMfa(MfaVerifyRequest request, CancellationToken ct)
    {
        var result = await authService.VerifyMfaAsync(request, HttpContext.Connection.RemoteIpAddress?.ToString(), Request.Headers.UserAgent, ct);
        return Ok(ApiResponse<TokenResponse>.Ok(result));
    }

    [HttpPost("refresh-token")]
    public async Task<ActionResult<ApiResponse<TokenResponse>>> RefreshToken(RefreshTokenRequest request, CancellationToken ct)
    {
        var result = await authService.RefreshAsync(request, HttpContext.Connection.RemoteIpAddress?.ToString(), Request.Headers.UserAgent, ct);
        return Ok(ApiResponse<TokenResponse>.Ok(result));
    }

    [HttpPost("logout")]
    public async Task<ActionResult<ApiResponse<object>>> Logout(LogoutRequest request, CancellationToken ct)
    {
        await authService.LogoutAsync(request, ct);
        return Ok(ApiResponse<object>.Ok(new { }, "Çıkış yapıldı."));
    }

    [HttpPost("mfa/setup")]
    [Authorize]
    public async Task<ActionResult<ApiResponse<MfaSetupResponse>>> SetupMfa(CancellationToken ct)
    {
        var result = await authService.SetupMfaAsync(User.GetUserId(), ct);
        return Ok(ApiResponse<MfaSetupResponse>.Ok(result));
    }

    [HttpPost("mfa/verify-setup")]
    [Authorize]
    public async Task<ActionResult<ApiResponse<object>>> VerifyMfaSetup(string code, CancellationToken ct)
    {
        await authService.VerifyMfaSetupAsync(User.GetUserId(), code, ct);
        return Ok(ApiResponse<object>.Ok(new { }, "MFA aktif edildi."));
    }

    [HttpPost("mfa/disable")]
    [Authorize]
    public async Task<ActionResult<ApiResponse<object>>> DisableMfa(MfaDisableRequest request, CancellationToken ct)
    {
        await authService.DisableMfaAsync(User.GetUserId(), request, ct);
        return Ok(ApiResponse<object>.Ok(new { }, "MFA devre dışı bırakıldı."));
    }
}
