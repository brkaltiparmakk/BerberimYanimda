namespace BerberYanimda.Application.DTOs;

public sealed record CouponDto(
    Guid Id,
    string Code,
    string? Description,
    decimal? DiscountAmount,
    decimal? DiscountPercentage,
    decimal? MinOrderAmount,
    decimal? MaxDiscountAmount,
    DateTime ValidFrom,
    DateTime ValidUntil,
    int UsageLimit,
    int UsageCount,
    bool IsActive
);

public sealed record ValidateCouponRequest(string Code, decimal OrderAmount);

public sealed record ValidateCouponResult(
    bool IsValid,
    string? Message,
    decimal DiscountAmount,
    decimal FinalAmount,
    CouponDto? Coupon
);
