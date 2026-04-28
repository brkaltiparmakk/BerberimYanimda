using BerberYanimda.Application.DTOs;
using BerberYanimda.Application.Services;
using BerberYanimda.Domain;
using BerberYanimda.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace BerberYanimda.Tests;

public sealed class CouponServiceTests
{
    [Fact]
    public async Task ValidateAsync_returns_discount_for_valid_coupon()
    {
        await using var db = CreateDb();
        var coupon = SeedCoupon(db, code: "SAVE20", discountPercentage: 20, discountAmount: null);
        await db.SaveChangesAsync();
        var service = CreateCouponService(db);

        var result = await service.ValidateAsync(new ValidateCouponRequest("SAVE20", 300), CancellationToken.None);

        Assert.True(result.IsValid);
        Assert.Equal(60, result.DiscountAmount);
        Assert.Equal(240, result.FinalAmount);
        Assert.NotNull(result.Coupon);
        Assert.Equal("SAVE20", result.Coupon.Code);
    }

    [Fact]
    public async Task ValidateAsync_returns_discount_for_fixed_coupon()
    {
        await using var db = CreateDb();
        var coupon = SeedCoupon(db, code: "FLAT50", discountPercentage: null, discountAmount: 50);
        await db.SaveChangesAsync();
        var service = CreateCouponService(db);

        var result = await service.ValidateAsync(new ValidateCouponRequest("FLAT50", 300), CancellationToken.None);

        Assert.True(result.IsValid);
        Assert.Equal(50, result.DiscountAmount);
        Assert.Equal(250, result.FinalAmount);
        Assert.NotNull(result.Coupon);
        Assert.Equal("FLAT50", result.Coupon.Code);
    }

    [Fact]
    public async Task ValidateAsync_rejects_expired_coupon()
    {
        await using var db = CreateDb();
        var coupon = SeedCoupon(db, code: "EXPIRED", discountPercentage: 10, discountAmount: null);
        coupon.ValidUntil = DateTime.UtcNow.AddDays(-1);
        await db.SaveChangesAsync();
        var service = CreateCouponService(db);

        var result = await service.ValidateAsync(new ValidateCouponRequest("EXPIRED", 200), CancellationToken.None);

        Assert.False(result.IsValid);
    }

    [Fact]
    public async Task ValidateAsync_rejects_not_yet_valid_coupon()
    {
        await using var db = CreateDb();
        var coupon = SeedCoupon(db, code: "FUTURE", discountPercentage: 10, discountAmount: null);
        coupon.ValidFrom = DateTime.UtcNow.AddDays(1);
        await db.SaveChangesAsync();
        var service = CreateCouponService(db);

        var result = await service.ValidateAsync(new ValidateCouponRequest("FUTURE", 200), CancellationToken.None);

        Assert.False(result.IsValid);
    }

    [Fact]
    public async Task ValidateAsync_rejects_usage_limit_exceeded()
    {
        await using var db = CreateDb();
        var coupon = SeedCoupon(db, code: "USEDUP", discountPercentage: 10, discountAmount: null, usageLimit: 5, usageCount: 5);
        await db.SaveChangesAsync();
        var service = CreateCouponService(db);

        var result = await service.ValidateAsync(new ValidateCouponRequest("USEDUP", 200), CancellationToken.None);

        Assert.False(result.IsValid);
    }

    [Fact]
    public async Task ValidateAsync_rejects_unknown_code()
    {
        await using var db = CreateDb();
        var service = CreateCouponService(db);

        var result = await service.ValidateAsync(new ValidateCouponRequest("NOEXIST", 200), CancellationToken.None);

        Assert.False(result.IsValid);
    }

    [Fact]
    public async Task ValidateAsync_rejects_min_order_not_met()
    {
        await using var db = CreateDb();
        var coupon = SeedCoupon(db, code: "MIN500", discountPercentage: 10, discountAmount: null, minOrderAmount: 500);
        await db.SaveChangesAsync();
        var service = CreateCouponService(db);

        var result = await service.ValidateAsync(new ValidateCouponRequest("MIN500", 200), CancellationToken.None);

        Assert.False(result.IsValid);
    }

    private static AppDbContext CreateDb()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .ConfigureWarnings(warnings => warnings.Ignore(Microsoft.EntityFrameworkCore.Diagnostics.InMemoryEventId.TransactionIgnoredWarning))
            .Options;
        return new AppDbContext(options);
    }

    private static Coupon SeedCoupon(
        AppDbContext db,
        string code,
        decimal? discountPercentage,
        decimal? discountAmount,
        decimal? minOrderAmount = null,
        int usageLimit = 100,
        int usageCount = 0)
    {
        var coupon = new Coupon
        {
            Code = code,
            Description = "Test coupon",
            DiscountAmount = discountAmount,
            DiscountPercentage = discountPercentage,
            MinOrderAmount = minOrderAmount,
            MaxDiscountAmount = null,
            ValidFrom = DateTime.UtcNow.AddDays(-1),
            ValidUntil = DateTime.UtcNow.AddDays(1),
            UsageLimit = usageLimit,
            UsageCount = usageCount,
            IsActive = true
        };
        db.Coupons.Add(coupon);
        return coupon;
    }

    private static CouponService CreateCouponService(AppDbContext db)
    {
        return new CouponService(db);
    }
}
