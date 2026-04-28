using BerberYanimda.Application.Interfaces;
using BerberYanimda.Application.Services;
using Microsoft.Extensions.DependencyInjection;

namespace BerberYanimda.Application;

public static class DependencyInjection
{
    public static IServiceCollection AddApplication(this IServiceCollection services)
    {
        services.AddScoped<AuthService>();
        services.AddScoped<UserService>();
        services.AddScoped<CatalogService>();
        services.AddScoped<AvailabilityService>();
        services.AddScoped<BookingService>();
        services.AddScoped<PaymentService>();
        services.AddScoped<FavoriteService>();
        services.AddScoped<NotificationService>();
        services.AddScoped<AdminService>();
        services.AddScoped<ReviewService>();
        services.AddScoped<BarberOwnerService>();
        services.AddScoped<CouponService>();
        services.AddScoped<SupportTicketService>();
        services.AddScoped<AuditLogService>();
        services.AddScoped<IAuditLogService>(sp => sp.GetRequiredService<AuditLogService>());
        return services;
    }
}
