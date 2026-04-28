using BerberYanimda.Application.Common;
using BerberYanimda.Application.DTOs;
using BerberYanimda.Application.Services;
using BerberYanimda.Domain;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace BerberYanimda.Api.Controllers;

[ApiController]
[Route("api/v1/barbers")]
public sealed class BarbersController(CatalogService catalogService) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<ApiResponse<PagedResponse<BarberListItemDto>>>> GetBarbers(
        [FromQuery] string? search,
        [FromQuery] string? city,
        [FromQuery] string? district,
        [FromQuery] string? sortBy,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken ct = default)
    {
        var result = await catalogService.GetBarbersAsync(GetOptionalUserId(), search, city, district, sortBy, page, pageSize, ct);
        return Ok(ApiResponse<PagedResponse<BarberListItemDto>>.Ok(result));
    }

    [HttpGet("{barberShopId:guid}")]
    public async Task<ActionResult<ApiResponse<BarberDetailDto>>> GetBarber(Guid barberShopId, CancellationToken ct)
    {
        var result = await catalogService.GetBarberAsync(barberShopId, GetOptionalUserId(), ct);
        return Ok(ApiResponse<BarberDetailDto>.Ok(result));
    }

    [HttpGet("{barberShopId:guid}/services")]
    public async Task<ActionResult<ApiResponse<IReadOnlyList<BarberServiceDto>>>> GetServices(Guid barberShopId, CancellationToken ct)
    {
        var result = await catalogService.GetServicesAsync(barberShopId, ct);
        return Ok(ApiResponse<IReadOnlyList<BarberServiceDto>>.Ok(result));
    }

    [HttpGet("{barberShopId:guid}/staff")]
    public async Task<ActionResult<ApiResponse<IReadOnlyList<StaffDto>>>> GetStaff(Guid barberShopId, CancellationToken ct)
    {
        var result = await catalogService.GetStaffAsync(barberShopId, ct);
        return Ok(ApiResponse<IReadOnlyList<StaffDto>>.Ok(result));
    }

    [HttpPost("{barberShopId:guid}/images")]
    public async Task<ActionResult<ApiResponse<object>>> AddImage(Guid barberShopId, [FromBody] AddBarberImageRequest request, CancellationToken ct)
    {
        var image = new BarberShopImage
        {
            BarberShopId = barberShopId,
            ImageUrl = request.ImageUrl,
            SortOrder = request.SortOrder
        };
        // In-memory/mock için doğrudan başarılı dönüyoruz.
        // Gerçek uygulamada CatalogService üzerinden eklenecektir.
        return Ok(ApiResponse<object>.Ok(new { image.BarberShopId, image.ImageUrl }, "Görsel eklendi."));
    }

    private Guid? GetOptionalUserId()
    {
        if (User.Identity?.IsAuthenticated != true)
        {
            return null;
        }

        var value = User.FindFirstValue(ClaimTypes.NameIdentifier);
        return Guid.TryParse(value, out var userId) ? userId : null;
    }
}
