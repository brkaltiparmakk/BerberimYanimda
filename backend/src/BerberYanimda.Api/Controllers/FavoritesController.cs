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
[Route("api/v1/favorites")]
public sealed class FavoritesController(FavoriteService favoriteService) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<ApiResponse<IReadOnlyList<FavoriteDto>>>> GetMine(CancellationToken ct)
    {
        var result = await favoriteService.GetMineAsync(User.GetUserId(), ct);
        return Ok(ApiResponse<IReadOnlyList<FavoriteDto>>.Ok(result));
    }

    [HttpPost("{barberShopId:guid}")]
    public async Task<ActionResult<ApiResponse<object>>> Add(Guid barberShopId, CancellationToken ct)
    {
        await favoriteService.AddAsync(User.GetUserId(), barberShopId, ct);
        return Ok(ApiResponse<object>.Ok(new { }, "Favorilere eklendi."));
    }

    [HttpDelete("{barberShopId:guid}")]
    public async Task<ActionResult<ApiResponse<object>>> Remove(Guid barberShopId, CancellationToken ct)
    {
        await favoriteService.RemoveAsync(User.GetUserId(), barberShopId, ct);
        return Ok(ApiResponse<object>.Ok(new { }, "Favorilerden çıkarıldı."));
    }
}
