using BerberYanimda.Application.Common;
using BerberYanimda.Application.DTOs;
using BerberYanimda.Application.Services;
using Microsoft.AspNetCore.Mvc;

namespace BerberYanimda.Api.Controllers;

[ApiController]
[Route("api/v1/availability")]
public sealed class AvailabilityController(AvailabilityService availabilityService) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<ApiResponse<IReadOnlyList<AvailabilitySlotDto>>>> GetSlots(
        [FromQuery] Guid barberShopId,
        [FromQuery] string? staffMemberId,
        [FromQuery] string serviceIds,
        [FromQuery] DateOnly date,
        CancellationToken ct)
    {
        var ids = new List<Guid>();
        foreach (var value in serviceIds.Split(',', StringSplitOptions.TrimEntries | StringSplitOptions.RemoveEmptyEntries))
        {
            if (!Guid.TryParse(value, out var id))
            {
                return BadRequest(ApiResponse<IReadOnlyList<AvailabilitySlotDto>>.Fail("Geçersiz hizmet ID değeri."));
            }

            ids.Add(id);
        }

        Guid? parsedStaffMemberId = null;
        if (!string.IsNullOrWhiteSpace(staffMemberId))
        {
            if (!Guid.TryParse(staffMemberId, out var id))
            {
                return BadRequest(ApiResponse<IReadOnlyList<AvailabilitySlotDto>>.Fail("Geçersiz personel ID değeri."));
            }

            parsedStaffMemberId = id;
        }

        var result = await availabilityService.GetSlotsAsync(barberShopId, parsedStaffMemberId, ids, date, ct);
        return Ok(ApiResponse<IReadOnlyList<AvailabilitySlotDto>>.Ok(result));
    }
}
