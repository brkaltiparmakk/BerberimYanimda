using BerberYanimda.Api.Extensions;
using BerberYanimda.Application.Common;
using BerberYanimda.Application.DTOs;
using BerberYanimda.Application.Services;
using BerberYanimda.Domain;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BerberYanimda.Api.Controllers;

[ApiController]
[Route("api/v1")]
public sealed class ReviewsController(ReviewService reviewService) : ControllerBase
{
    [HttpPost("reviews")]
    [Authorize(Roles = nameof(UserRole.Customer))]
    public async Task<ActionResult<ApiResponse<ReviewDto>>> Create(CreateReviewRequest request, CancellationToken ct)
    {
        var result = await reviewService.CreateAsync(User.GetUserId(), request, ct);
        return Created(string.Empty, ApiResponse<ReviewDto>.Ok(result, "Yorum oluşturuldu."));
    }

    [HttpGet("barbers/{barberShopId:guid}/reviews")]
    public async Task<ActionResult<ApiResponse<IReadOnlyList<ReviewDto>>>> GetByBarberShop(Guid barberShopId, CancellationToken ct)
    {
        var result = await reviewService.GetByBarberShopAsync(barberShopId, ct);
        return Ok(ApiResponse<IReadOnlyList<ReviewDto>>.Ok(result));
    }

    [HttpGet("barbers/{barberShopId:guid}/reviews/summary")]
    public async Task<ActionResult<ApiResponse<ReviewSummaryDto>>> GetSummary(Guid barberShopId, CancellationToken ct)
    {
        var result = await reviewService.GetSummaryAsync(barberShopId, ct);
        return Ok(ApiResponse<ReviewSummaryDto>.Ok(result));
    }

    [HttpGet("admin/reviews/pending")]
    [Authorize(Roles = nameof(UserRole.Admin))]
    public async Task<ActionResult<ApiResponse<IReadOnlyList<ReviewDto>>>> GetPending(CancellationToken ct)
    {
        var result = await reviewService.GetPendingAsync(ct);
        return Ok(ApiResponse<IReadOnlyList<ReviewDto>>.Ok(result));
    }

    [HttpPost("admin/reviews/{reviewId:guid}/approve")]
    [Authorize(Roles = nameof(UserRole.Admin))]
    public async Task<ActionResult<ApiResponse<object>>> Approve(Guid reviewId, CancellationToken ct)
    {
        await reviewService.ApproveAsync(reviewId, ct);
        return Ok(ApiResponse<object>.Ok(new { }, "Yorum onaylandı."));
    }

    [HttpDelete("admin/reviews/{reviewId:guid}")]
    [Authorize(Roles = nameof(UserRole.Admin))]
    public async Task<ActionResult<ApiResponse<object>>> Delete(Guid reviewId, CancellationToken ct)
    {
        await reviewService.DeleteAsync(reviewId, ct);
        return Ok(ApiResponse<object>.Ok(new { }, "Yorum silindi."));
    }
}
