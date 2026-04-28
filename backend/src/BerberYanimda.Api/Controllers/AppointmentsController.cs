using BerberYanimda.Api.Extensions;
using BerberYanimda.Application.Common;
using BerberYanimda.Application.DTOs;
using BerberYanimda.Application.Services;
using BerberYanimda.Domain;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;

namespace BerberYanimda.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/v1/appointments")]
public sealed class AppointmentsController(BookingService bookingService) : ControllerBase
{
    [HttpPost]
    [EnableRateLimiting("Appointment")]
    [Authorize(Roles = nameof(UserRole.Customer))]
    public async Task<ActionResult<ApiResponse<AppointmentDto>>> Create(CreateAppointmentRequest request, CancellationToken ct)
    {
        var result = await bookingService.CreateAsync(User.GetUserId(), request, ct);
        return CreatedAtAction(nameof(GetById), new { appointmentId = result.Id }, ApiResponse<AppointmentDto>.Ok(result, "Randevu oluşturuldu."));
    }

    [HttpGet("my")]
    public async Task<ActionResult<ApiResponse<IReadOnlyList<AppointmentDto>>>> GetMine([FromQuery] AppointmentStatus? status, CancellationToken ct)
    {
        var result = await bookingService.GetMineAsync(User.GetUserId(), User.GetRole(), status, ct);
        return Ok(ApiResponse<IReadOnlyList<AppointmentDto>>.Ok(result));
    }

    [HttpGet("{appointmentId:guid}")]
    public async Task<ActionResult<ApiResponse<AppointmentDto>>> GetById(Guid appointmentId, CancellationToken ct)
    {
        var result = await bookingService.GetByIdAsync(appointmentId, User.GetUserId(), User.GetRole(), ct);
        return Ok(ApiResponse<AppointmentDto>.Ok(result));
    }

    [HttpPost("{appointmentId:guid}/cancel")]
    public async Task<ActionResult<ApiResponse<AppointmentDto>>> Cancel(Guid appointmentId, CancelAppointmentRequest request, CancellationToken ct)
    {
        var result = await bookingService.CancelAsync(appointmentId, User.GetUserId(), User.GetRole(), request, ct);
        return Ok(ApiResponse<AppointmentDto>.Ok(result, "Randevu iptal edildi."));
    }

    [HttpPatch("{appointmentId:guid}/confirm")]
    [Authorize(Roles = $"{nameof(UserRole.BarberOwner)},{nameof(UserRole.Staff)},{nameof(UserRole.Admin)}")]
    public async Task<ActionResult<ApiResponse<AppointmentDto>>> Confirm(Guid appointmentId, CancellationToken ct)
    {
        var result = await bookingService.ConfirmAsync(appointmentId, User.GetUserId(), User.GetRole(), ct);
        return Ok(ApiResponse<AppointmentDto>.Ok(result, "Randevu onaylandı."));
    }

    [HttpPatch("{appointmentId:guid}/complete")]
    [Authorize(Roles = $"{nameof(UserRole.BarberOwner)},{nameof(UserRole.Staff)},{nameof(UserRole.Admin)}")]
    public async Task<ActionResult<ApiResponse<AppointmentDto>>> Complete(Guid appointmentId, CancellationToken ct)
    {
        var result = await bookingService.CompleteAsync(appointmentId, User.GetUserId(), User.GetRole(), ct);
        return Ok(ApiResponse<AppointmentDto>.Ok(result, "Randevu tamamlandı."));
    }

    [HttpPatch("{appointmentId:guid}/reject")]
    [Authorize(Roles = $"{nameof(UserRole.BarberOwner)},{nameof(UserRole.Staff)},{nameof(UserRole.Admin)}")]
    public async Task<ActionResult<ApiResponse<AppointmentDto>>> Reject(Guid appointmentId, RejectAppointmentRequest request, CancellationToken ct)
    {
        var result = await bookingService.RejectAsync(appointmentId, User.GetUserId(), User.GetRole(), request, ct);
        return Ok(ApiResponse<AppointmentDto>.Ok(result, "Randevu reddedildi."));
    }

    [HttpGet("shop")]
    [Authorize(Roles = $"{nameof(UserRole.BarberOwner)},{nameof(UserRole.Staff)},{nameof(UserRole.Admin)}")]
    public async Task<ActionResult<ApiResponse<PagedResponse<AppointmentDto>>>> GetShopAppointments([FromQuery] ShopAppointmentsQuery query, CancellationToken ct)
    {
        var result = await bookingService.GetShopAppointmentsAsync(User.GetUserId(), User.GetRole(), query, ct);
        return Ok(ApiResponse<PagedResponse<AppointmentDto>>.Ok(result));
    }
}
