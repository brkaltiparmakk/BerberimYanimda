using BerberYanimda.Api.Extensions;
using BerberYanimda.Application.Common;
using BerberYanimda.Application.DTOs;
using BerberYanimda.Application.Services;
using BerberYanimda.Domain;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BerberYanimda.Api.Controllers;

[ApiController]
[Authorize(Roles = nameof(UserRole.Admin))]
[Route("api/v1/admin/barbers")]
public sealed class AdminBarbersController(AdminService adminService) : ControllerBase
{
    [HttpGet("pending")]
    public async Task<ActionResult<ApiResponse<IReadOnlyList<BarberListItemDto>>>> GetPending(CancellationToken ct)
    {
        var result = await adminService.GetPendingBarbersAsync(ct);
        return Ok(ApiResponse<IReadOnlyList<BarberListItemDto>>.Ok(result));
    }

    [HttpPost("{barberShopId:guid}/approve")]
    public async Task<ActionResult<ApiResponse<object>>> Approve(Guid barberShopId, CancellationToken ct)
    {
        await adminService.ApproveBarberAsync(User.GetUserId(), barberShopId, HttpContext.Connection.RemoteIpAddress?.ToString(), Request.Headers.UserAgent, ct);
        return Ok(ApiResponse<object>.Ok(new { }, "Berber onaylandı."));
    }

    [HttpPost("{barberShopId:guid}/deactivate")]
    public async Task<ActionResult<ApiResponse<object>>> Deactivate(Guid barberShopId, CancellationToken ct)
    {
        await adminService.DeactivateBarberAsync(User.GetUserId(), barberShopId, HttpContext.Connection.RemoteIpAddress?.ToString(), Request.Headers.UserAgent, ct);
        return Ok(ApiResponse<object>.Ok(new { }, "Berber pasife alındı."));
    }
}
