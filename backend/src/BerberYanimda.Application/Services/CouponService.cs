using BerberYanimda.Application.DTOs;
using BerberYanimda.Application.Interfaces;
using BerberYanimda.Domain;
using Microsoft.EntityFrameworkCore;

namespace BerberYanimda.Application.Services;

public sealed class CouponService(IAppDbContext dbContext)
{
    public async Task<ValidateCouponResult> ValidateAsync(ValidateCouponRequest request, CancellationToken ct)
    {
        var coupon = await dbContext.Coupons
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.Code == request.Code && x.IsActive, ct);

        if (coupon == null)
        {
            return new ValidateCouponResult(false, "Kupon bulunamadı.", 0, request.OrderAmount, null);
        }

        if (DateTime.UtcNow < coupon.ValidFrom || DateTime.UtcNow > coupon.ValidUntil)
        {
            return new ValidateCouponResult(false, "Kupon geçerlilik süresi dışında.", 0, request.OrderAmount, null);
        }

        if (coupon.UsageCount >= coupon.UsageLimit)
        {
            return new ValidateCouponResult(false, "Kupon kullanım limitine ulaştı.", 0, request.OrderAmount, null);
        }

        if (coupon.MinOrderAmount.HasValue && request.OrderAmount < coupon.MinOrderAmount.Value)
        {
            return new ValidateCouponResult(false, $"Minimum sipariş tutarı {coupon.MinOrderAmount.Value:C} olmalıdır.", 0, request.OrderAmount, null);
        }

        decimal discount = 0;
        if (coupon.DiscountAmount.HasValue)
        {
            discount = coupon.DiscountAmount.Value;
        }
        else if (coupon.DiscountPercentage.HasValue)
        {
            discount = request.OrderAmount * (coupon.DiscountPercentage.Value / 100m);
        }

        if (coupon.MaxDiscountAmount.HasValue && discount > coupon.MaxDiscountAmount.Value)
        {
            discount = coupon.MaxDiscountAmount.Value;
        }

        discount = Math.Min(discount, request.OrderAmount);
        var finalAmount = request.OrderAmount - discount;

        var dto = new CouponDto(
            coupon.Id,
            coupon.Code,
            coupon.Description,
            coupon.DiscountAmount,
            coupon.DiscountPercentage,
            coupon.MinOrderAmount,
            coupon.MaxDiscountAmount,
            coupon.ValidFrom,
            coupon.ValidUntil,
            coupon.UsageLimit,
            coupon.UsageCount,
            coupon.IsActive
        );

        return new ValidateCouponResult(true, "Kupon uygulandı.", discount, finalAmount, dto);
    }
}
