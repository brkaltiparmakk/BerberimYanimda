using BerberYanimda.Api.Extensions;
using BerberYanimda.Application.Common;
using BerberYanimda.Application.DTOs;
using BerberYanimda.Application.Interfaces;
using BerberYanimda.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BerberYanimda.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/v1/users")]
public sealed class UsersController(UserService userService, IPushNotificationService pushNotificationService, IWebHostEnvironment environment, IConfiguration configuration) : ControllerBase
{
    [HttpGet("me")]
    public async Task<ActionResult<ApiResponse<UserProfileDto>>> GetMe(CancellationToken ct)
    {
        var result = await userService.GetMeAsync(User.GetUserId(), ct);
        return Ok(ApiResponse<UserProfileDto>.Ok(result));
    }

    [HttpPut("me")]
    public async Task<ActionResult<ApiResponse<UserProfileDto>>> UpdateMe(UpdateProfileRequest request, CancellationToken ct)
    {
        var result = await userService.UpdateMeAsync(User.GetUserId(), request, ct);
        return Ok(ApiResponse<UserProfileDto>.Ok(result, "Profil güncellendi."));
    }

    [HttpPost("me/profile-image")]
    [RequestSizeLimit(5_242_880)]
    public async Task<ActionResult<ApiResponse<UserProfileDto>>> UploadProfileImage(IFormFile file, CancellationToken ct)
    {
        if (file.Length == 0 || file.Length > 5_242_880)
        {
            return BadRequest(ApiResponse<UserProfileDto>.Fail("Dosya boyutu 5 MB altında olmalıdır."));
        }

        var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
        var allowed = new HashSet<string> { ".jpg", ".jpeg", ".png", ".webp" };
        if (!allowed.Contains(ext))
        {
            return BadRequest(ApiResponse<UserProfileDto>.Fail("Sadece jpg, jpeg, png ve webp dosyaları yüklenebilir."));
        }

        var allowedContentTypes = new HashSet<string> { "image/jpeg", "image/png", "image/webp" };
        if (!allowedContentTypes.Contains(file.ContentType.ToLowerInvariant()))
        {
            return BadRequest(ApiResponse<UserProfileDto>.Fail("Geçersiz dosya içerik tipi."));
        }

        var uploadRoot = Path.Combine(environment.WebRootPath ?? Path.Combine(environment.ContentRootPath, "wwwroot"), "uploads", "profiles");
        Directory.CreateDirectory(uploadRoot);
        var fileName = $"{Guid.NewGuid():N}{ext}";
        var path = Path.Combine(uploadRoot, fileName);
        await using (var stream = System.IO.File.Create(path))
        {
            await file.CopyToAsync(stream, ct);
        }

        var baseUrl = configuration["Storage:BaseUrl"]?.TrimEnd('/');
        var imageUrl = string.IsNullOrWhiteSpace(baseUrl)
            ? $"/uploads/profiles/{fileName}"
            : $"{baseUrl}/uploads/profiles/{fileName}";

        var result = await userService.UpdateProfileImageAsync(User.GetUserId(), imageUrl, ct);
        return Ok(ApiResponse<UserProfileDto>.Ok(result, "Profil fotoğrafı güncellendi."));
    }

    [HttpPost("me/device-token")]
    public async Task<ActionResult<ApiResponse<object>>> RegisterDeviceToken(RegisterDeviceTokenRequest request, CancellationToken ct)
    {
        await pushNotificationService.RegisterDeviceAsync(User.GetUserId(), request.Token, request.Platform, ct);
        return Ok(ApiResponse<object>.Ok(new { }, "Cihaz token'ı kaydedildi."));
    }

    [HttpDelete("me/device-token")]
    public async Task<ActionResult<ApiResponse<object>>> UnregisterDeviceToken(UnregisterDeviceTokenRequest request, CancellationToken ct)
    {
        await pushNotificationService.UnregisterDeviceAsync(request.Token, ct);
        return Ok(ApiResponse<object>.Ok(new { }, "Cihaz token'ı kaldırıldı."));
    }

    [HttpPost("me/change-password")]
    public async Task<ActionResult<ApiResponse<object>>> ChangePassword(ChangePasswordRequest request, CancellationToken ct)
    {
        await userService.ChangePasswordAsync(User.GetUserId(), request, ct);
        return Ok(ApiResponse<object>.Ok(new { }, "Şifre değiştirildi. Diğer oturumlarınız sonlandırıldı."));
    }

    [HttpPost("me/delete-account")]
    public async Task<ActionResult<ApiResponse<object>>> DeleteAccount(DeleteAccountRequest request, CancellationToken ct)
    {
        await userService.RequestAccountDeletionAsync(User.GetUserId(), request, ct);
        return Ok(ApiResponse<object>.Ok(new { }, "Hesap silme talebiniz alındı."));
    }

    [HttpGet("me/export-data")]
    public async Task<ActionResult<ApiResponse<UserDataExportDto>>> ExportData(CancellationToken ct)
    {
        var result = await userService.ExportUserDataAsync(User.GetUserId(), ct);
        return Ok(ApiResponse<UserDataExportDto>.Ok(result));
    }
}

public sealed record RegisterDeviceTokenRequest(string Token, string Platform);
public sealed record UnregisterDeviceTokenRequest(string Token);
