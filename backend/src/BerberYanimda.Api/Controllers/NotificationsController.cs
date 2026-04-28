using BerberYanimda.Api.Extensions;
using BerberYanimda.Application.Common;
using BerberYanimda.Application.DTOs;
using BerberYanimda.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BerberYanimda.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/v1/notifications")]
public sealed class NotificationsController(NotificationService notificationService) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<ApiResponse<IReadOnlyList<NotificationDto>>>> GetMine(CancellationToken ct)
    {
        var result = await notificationService.GetMineAsync(User.GetUserId(), ct);
        return Ok(ApiResponse<IReadOnlyList<NotificationDto>>.Ok(result));
    }

    [HttpPost("{notificationId:guid}/read")]
    public async Task<ActionResult<ApiResponse<object>>> MarkRead(Guid notificationId, CancellationToken ct)
    {
        await notificationService.MarkReadAsync(User.GetUserId(), notificationId, ct);
        return Ok(ApiResponse<object>.Ok(new { }, "Bildirim okundu."));
    }

    [HttpPost("read-all")]
    public async Task<ActionResult<ApiResponse<object>>> MarkAllRead(CancellationToken ct)
    {
        await notificationService.MarkAllReadAsync(User.GetUserId(), ct);
        return Ok(ApiResponse<object>.Ok(new { }, "Tüm bildirimler okundu."));
    }
}
