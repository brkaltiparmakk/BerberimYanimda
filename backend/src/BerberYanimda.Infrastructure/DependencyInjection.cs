using BerberYanimda.Application.Interfaces;
using BerberYanimda.Infrastructure.Caching;
using BerberYanimda.Infrastructure.Persistence;
using BerberYanimda.Infrastructure.Payments;
using BerberYanimda.Infrastructure.Security;
using BerberYanimda.Infrastructure.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace BerberYanimda.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        var provider = configuration["Database:Provider"] ?? "InMemory";
        if (provider.Equals("Postgres", StringComparison.OrdinalIgnoreCase) ||
            provider.Equals("PostgreSQL", StringComparison.OrdinalIgnoreCase))
        {
            services.AddDbContext<AppDbContext>(options =>
                options.UseNpgsql(configuration.GetConnectionString("DefaultConnection")));
        }
        else if (provider.Equals("SqlServer", StringComparison.OrdinalIgnoreCase) ||
                 provider.Equals("MSSQL", StringComparison.OrdinalIgnoreCase))
        {
            services.AddDbContext<AppDbContext>(options =>
                options.UseSqlServer(configuration.GetConnectionString("DefaultConnection")));
        }
        else
        {
            var databaseName = configuration["Database:Name"] ?? "BerberYanimdaDev";
            services.AddDbContext<AppDbContext>(options =>
                options.UseInMemoryDatabase(databaseName)
                       .ConfigureWarnings(warnings => warnings.Ignore(Microsoft.EntityFrameworkCore.Diagnostics.InMemoryEventId.TransactionIgnoredWarning)));
        }

        services.AddScoped<IAppDbContext>(sp => sp.GetRequiredService<AppDbContext>());
        services.AddScoped<IPasswordService, PasswordService>();
        services.AddScoped<ISecureHasher, SecureHasher>();
        services.AddScoped<ITokenService, TokenService>();
        var smsProvider = configuration["Sms:Provider"] ?? "Mock";
        if (smsProvider.Equals("Mock", StringComparison.OrdinalIgnoreCase))
        {
            services.AddScoped<ISmsSender, MockSmsSender>();
        }
        else
        {
            services.AddScoped<ISmsSender>(sp => new HttpSmsSender(
                new HttpClient(),
                sp.GetRequiredService<IConfiguration>(),
                sp.GetRequiredService<ILogger<HttpSmsSender>>()));
        }

        var firebaseProjectId = configuration["Firebase:ProjectId"];
        if (!string.IsNullOrWhiteSpace(firebaseProjectId))
        {
            services.AddScoped<IPushNotificationService, FirebasePushNotificationService>();
        }
        else
        {
            services.AddScoped<IPushNotificationService, MockPushNotificationService>();
        }

        services.AddSingleton<IDateTimeProvider, SystemDateTimeProvider>();
        services.AddSingleton<IPaymentProviderFactory, PaymentProviderFactory>();

        services.AddHttpClient<IyzicoPaymentProvider>();

        var mfaKey = configuration["Mfa:EncryptionKey"];
        if (!string.IsNullOrWhiteSpace(mfaKey))
        {
            services.AddSingleton<IEncryptionService>(new AesEncryptionService(mfaKey));
        }
        else
        {
            // Development fallback - NOT for production
            var fallbackKey = Convert.ToBase64String(System.Security.Cryptography.RandomNumberGenerator.GetBytes(32));
            services.AddSingleton<IEncryptionService>(new AesEncryptionService(fallbackKey));
        }
        services.AddSingleton<ITotpService, TotpService>();
        services.AddSingleton<ICacheService, MemoryCacheService>();

        return services;
    }
}
