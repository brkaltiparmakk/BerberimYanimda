namespace BerberYanimda.Api.Extensions;

public static class StartupValidation
{
    private const string DevelopmentSecret = "DEV_ONLY_SECRET_REPLACE_FOR_PRODUCTION_123456789";

    public static void ValidateProductionSafety(this WebApplicationBuilder builder)
    {
        if (builder.Environment.IsDevelopment() || builder.Environment.IsEnvironment("Testing"))
        {
            return;
        }

        var databaseProvider = builder.Configuration["Database:Provider"];
        if (!string.Equals(databaseProvider, "Postgres", StringComparison.OrdinalIgnoreCase) &&
            !string.Equals(databaseProvider, "PostgreSQL", StringComparison.OrdinalIgnoreCase) &&
            !string.Equals(databaseProvider, "SqlServer", StringComparison.OrdinalIgnoreCase) &&
            !string.Equals(databaseProvider, "MSSQL", StringComparison.OrdinalIgnoreCase))
        {
            throw new InvalidOperationException("Staging/Production ortamında PostgreSQL veya SQL Server zorunludur.");
        }

        var jwtSecret = builder.Configuration["Jwt:Secret"];
        if (string.IsNullOrWhiteSpace(jwtSecret) || jwtSecret == DevelopmentSecret || jwtSecret.Length < 32)
        {
            throw new InvalidOperationException("Staging/Production ortamında güçlü Jwt:Secret zorunludur.");
        }

        var hmacKey = builder.Configuration["Hmac:Key"];
        if (string.IsNullOrWhiteSpace(hmacKey) || hmacKey.Length < 32)
        {
            throw new InvalidOperationException("Staging/Production ortamında güçlü Hmac:Key zorunludur (en az 32 karakter).");
        }

        var smsProvider = builder.Configuration["Sms:Provider"];
        if (string.IsNullOrWhiteSpace(smsProvider) || smsProvider.Equals("Mock", StringComparison.OrdinalIgnoreCase))
        {
            throw new InvalidOperationException("Staging/Production ortamında mock SMS provider kullanılamaz.");
        }

        if (string.IsNullOrWhiteSpace(builder.Configuration["Sms:Endpoint"]) ||
            string.IsNullOrWhiteSpace(builder.Configuration["Sms:ApiKey"]))
        {
            throw new InvalidOperationException("Staging/Production ortamında Sms:Endpoint ve Sms:ApiKey zorunludur.");
        }

        var origins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>();
        if (origins is null || origins.Length == 0)
        {
            throw new InvalidOperationException("Staging/Production ortamında Cors:AllowedOrigins zorunludur.");
        }
    }
}
