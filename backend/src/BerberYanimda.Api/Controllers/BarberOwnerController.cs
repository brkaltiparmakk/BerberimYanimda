using BerberYanimda.Api.Extensions;
using BerberYanimda.Application.Common;
using BerberYanimda.Application.DTOs;
using BerberYanimda.Application.Services;
using BerberYanimda.Domain;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BerberYanimda.Api.Controllers;

[ApiController]
[Authorize(Roles = nameof(UserRole.BarberOwner))]
[Route("api/v1/barber-owner")]
public sealed class BarberOwnerController(BarberOwnerService barberOwnerService) : ControllerBase
{
    [HttpGet("shop")]
    public async Task<ActionResult<ApiResponse<BarberShopDetailDto?>>> GetMyShop(CancellationToken ct)
    {
        var result = await barberOwnerService.GetMyShopAsync(User.GetUserId(), ct);
        return Ok(ApiResponse<BarberShopDetailDto?>.Ok(result));
    }

    [HttpPost("shop")]
    public async Task<ActionResult<ApiResponse<BarberShopDetailDto>>> CreateShop(CreateBarberShopRequest request, CancellationToken ct)
    {
        var result = await barberOwnerService.CreateShopAsync(User.GetUserId(), request, ct);
        return Created(string.Empty, ApiResponse<BarberShopDetailDto>.Ok(result, "Dükkan oluşturuldu. Onay bekleniyor."));
    }

    [HttpPut("shop")]
    public async Task<ActionResult<ApiResponse<BarberShopDetailDto>>> UpdateShop(UpdateBarberShopRequest request, CancellationToken ct)
    {
        var result = await barberOwnerService.UpdateShopAsync(User.GetUserId(), request, ct);
        return Ok(ApiResponse<BarberShopDetailDto>.Ok(result, "Dükkan bilgileri güncellendi."));
    }

    [HttpGet("services")]
    public async Task<ActionResult<ApiResponse<IReadOnlyList<OwnerServiceDto>>>> GetServices(CancellationToken ct)
    {
        var result = await barberOwnerService.GetServicesAsync(User.GetUserId(), ct);
        return Ok(ApiResponse<IReadOnlyList<OwnerServiceDto>>.Ok(result));
    }

    [HttpPost("services")]
    public async Task<ActionResult<ApiResponse<OwnerServiceDto>>> CreateService(CreateServiceRequest request, CancellationToken ct)
    {
        var result = await barberOwnerService.CreateServiceAsync(User.GetUserId(), request, ct);
        return Created(string.Empty, ApiResponse<OwnerServiceDto>.Ok(result, "Hizmet eklendi."));
    }

    [HttpPut("services/{serviceId:guid}")]
    public async Task<ActionResult<ApiResponse<OwnerServiceDto>>> UpdateService(Guid serviceId, UpdateServiceRequest request, CancellationToken ct)
    {
        var result = await barberOwnerService.UpdateServiceAsync(User.GetUserId(), serviceId, request, ct);
        return Ok(ApiResponse<OwnerServiceDto>.Ok(result, "Hizmet güncellendi."));
    }

    [HttpDelete("services/{serviceId:guid}")]
    public async Task<ActionResult<ApiResponse<object>>> DeleteService(Guid serviceId, CancellationToken ct)
    {
        await barberOwnerService.DeleteServiceAsync(User.GetUserId(), serviceId, ct);
        return Ok(ApiResponse<object>.Ok(new { }, "Hizmet silindi."));
    }

    [HttpGet("staff")]
    public async Task<ActionResult<ApiResponse<IReadOnlyList<OwnerStaffDto>>>> GetStaff(CancellationToken ct)
    {
        var result = await barberOwnerService.GetStaffAsync(User.GetUserId(), ct);
        return Ok(ApiResponse<IReadOnlyList<OwnerStaffDto>>.Ok(result));
    }

    [HttpPost("staff")]
    public async Task<ActionResult<ApiResponse<OwnerStaffDto>>> CreateStaff(CreateStaffRequest request, CancellationToken ct)
    {
        var result = await barberOwnerService.CreateStaffAsync(User.GetUserId(), request, ct);
        return Created(string.Empty, ApiResponse<OwnerStaffDto>.Ok(result, "Personel eklendi."));
    }

    [HttpPut("staff/{staffId:guid}")]
    public async Task<ActionResult<ApiResponse<OwnerStaffDto>>> UpdateStaff(Guid staffId, UpdateStaffRequest request, CancellationToken ct)
    {
        var result = await barberOwnerService.UpdateStaffAsync(User.GetUserId(), staffId, request, ct);
        return Ok(ApiResponse<OwnerStaffDto>.Ok(result, "Personel güncellendi."));
    }

    [HttpDelete("staff/{staffId:guid}")]
    public async Task<ActionResult<ApiResponse<object>>> DeleteStaff(Guid staffId, CancellationToken ct)
    {
        await barberOwnerService.DeleteStaffAsync(User.GetUserId(), staffId, ct);
        return Ok(ApiResponse<object>.Ok(new { }, "Personel silindi."));
    }

    [HttpPost("staff/{staffId:guid}/services")]
    public async Task<ActionResult<ApiResponse<object>>> AssignStaffServices(Guid staffId, AssignStaffServicesRequest request, CancellationToken ct)
    {
        await barberOwnerService.AssignStaffServicesAsync(User.GetUserId(), staffId, request, ct);
        return Ok(ApiResponse<object>.Ok(new { }, "Personel hizmetleri güncellendi."));
    }

    [HttpPost("staff/{staffId:guid}/avatar")]
    public async Task<ActionResult<ApiResponse<object>>> UpdateStaffAvatar(Guid staffId, [FromBody] UpdateStaffAvatarRequest request, CancellationToken ct)
    {
        // In-memory/mock için doğrudan başarılı dönüyoruz.
        return Ok(ApiResponse<object>.Ok(new { staffId, request.AvatarUrl }, "Personel avatarı güncellendi."));
    }

    [HttpGet("working-hours")]
    public async Task<ActionResult<ApiResponse<IReadOnlyList<OwnerWorkingHourDto>>>> GetWorkingHours(CancellationToken ct)
    {
        var result = await barberOwnerService.GetWorkingHoursAsync(User.GetUserId(), ct);
        return Ok(ApiResponse<IReadOnlyList<OwnerWorkingHourDto>>.Ok(result));
    }

    [HttpPut("working-hours")]
    public async Task<ActionResult<ApiResponse<object>>> UpdateWorkingHours(UpdateWorkingHoursRequest request, CancellationToken ct)
    {
        await barberOwnerService.UpdateWorkingHoursAsync(User.GetUserId(), request, ct);
        return Ok(ApiResponse<object>.Ok(new { }, "Çalışma saatleri güncellendi."));
    }

    [HttpGet("appointments")]
    public async Task<ActionResult<ApiResponse<IReadOnlyList<OwnerAppointmentDto>>>> GetAppointments(
        [FromQuery] AppointmentStatus? status,
        CancellationToken ct)
    {
        var result = await barberOwnerService.GetAppointmentsAsync(User.GetUserId(), status, ct);
        return Ok(ApiResponse<IReadOnlyList<OwnerAppointmentDto>>.Ok(result));
    }

    [HttpPost("appointments/{appointmentId:guid}/confirm")]
    public async Task<ActionResult<ApiResponse<OwnerAppointmentDto>>> ConfirmAppointment(Guid appointmentId, CancellationToken ct)
    {
        var result = await barberOwnerService.ConfirmAppointmentAsync(User.GetUserId(), appointmentId, ct);
        return Ok(ApiResponse<OwnerAppointmentDto>.Ok(result, "Randevu onaylandı."));
    }

    [HttpPost("appointments/{appointmentId:guid}/complete")]
    public async Task<ActionResult<ApiResponse<OwnerAppointmentDto>>> CompleteAppointment(Guid appointmentId, CancellationToken ct)
    {
        var result = await barberOwnerService.CompleteAppointmentAsync(User.GetUserId(), appointmentId, ct);
        return Ok(ApiResponse<OwnerAppointmentDto>.Ok(result, "Randevu tamamlandı."));
    }

    [HttpPost("appointments/{appointmentId:guid}/reject")]
    public async Task<ActionResult<ApiResponse<OwnerAppointmentDto>>> RejectAppointment(Guid appointmentId, [FromBody] RejectRequest? request, CancellationToken ct)
    {
        var result = await barberOwnerService.RejectAppointmentAsync(User.GetUserId(), appointmentId, request?.Reason, ct);
        return Ok(ApiResponse<OwnerAppointmentDto>.Ok(result, "Randevu reddedildi."));
    }

    [HttpGet("dashboard")]
    public async Task<ActionResult<ApiResponse<DashboardDto>>> GetDashboard(CancellationToken ct)
    {
        var result = await barberOwnerService.GetDashboardAsync(User.GetUserId(), ct);
        return Ok(ApiResponse<DashboardDto>.Ok(result));
    }
}

public sealed record RejectRequest(string? Reason);
