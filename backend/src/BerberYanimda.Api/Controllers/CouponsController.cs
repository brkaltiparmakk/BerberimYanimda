using BerberYanimda.Application.Common;
using BerberYanimda.Application.DTOs;
using BerberYanimda.Application.Services;
using BerberYanimda.Domain;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BerberYanimda.Api.Controllers;

[ApiController]
[Authorize(Roles = nameof(UserRole.Customer))]
[Route("api/v1/coupons")]
public sealed class CouponsController(CouponService couponService) : ControllerBase
{
    [HttpPost("validate")]
    public async Task<ActionResult<ApiResponse<ValidateCouponResult>>> Validate(ValidateCouponRequest request, CancellationToken ct)
    {
        var result = await couponService.ValidateAsync(request, ct);
        return Ok(ApiResponse<ValidateCouponResult>.Ok(result));
    }
}
