using System.Text;
using System.Text.Json.Serialization;
using System.Security.Claims;
using System.Threading.RateLimiting;
using BerberYanimda.Api.Extensions;
using BerberYanimda.Api.Json;
using BerberYanimda.Api.Middlewares;
using BerberYanimda.Application;
using BerberYanimda.Application.Common;
using BerberYanimda.Infrastructure;
using BerberYanimda.Infrastructure.Jobs;
using BerberYanimda.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.Data.SqlClient;
using Microsoft.IdentityModel.Tokens;

var builder = WebApplication.CreateBuilder(args);
builder.ValidateProductionSafety();

builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter());
        options.JsonSerializerOptions.Converters.Add(new FlexibleTimeOnlyJsonConverter());
    });
builder.Services.Configure<ApiBehaviorOptions>(options =>
{
    options.InvalidModelStateResponseFactory = context =>
    {
        var errors = context.ModelState
            .SelectMany(item => item.Value?.Errors.Select(error => new ApiError(item.Key, error.ErrorMessage)) ?? [])
            .ToList();
        return new BadRequestObjectResult(ApiResponse<object>.Fail("Validation failed.", errors));
    };
});
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddApplication();
builder.Services.AddInfrastructure(builder.Configuration);
builder.Services.AddCors(options =>
{
    options.AddPolicy("MobileClient", policy =>
    {
        if (builder.Environment.IsDevelopment() || builder.Environment.IsEnvironment("Testing"))
        {
            policy.AllowAnyHeader().AllowAnyMethod().AllowAnyOrigin();
            return;
        }

        var origins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>() ?? [];
        policy.WithOrigins(origins).AllowAnyHeader().AllowAnyMethod();
    });
});

var jwtSecret = builder.Configuration["Jwt:Secret"] ?? "DEV_ONLY_SECRET_REPLACE_FOR_PRODUCTION_123456789"; // Dev fallback - production'da StartupValidation tarafından engellenir
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = builder.Configuration["Jwt:Issuer"] ?? "BerberYanimda",
            ValidAudience = builder.Configuration["Jwt:Audience"] ?? "BerberYanimdaMobile",
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSecret)),
            ClockSkew = TimeSpan.FromSeconds(30)
        };
    });

builder.Services.AddAuthorization();
builder.Services.AddHealthChecks();
builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    options.AddPolicy("Auth", context =>
    {
        var key = $"auth:{GetClientIp(context)}";
        return RateLimitPartition.GetFixedWindowLimiter(key, _ => new FixedWindowRateLimiterOptions
        {
            PermitLimit = 5,
            Window = TimeSpan.FromMinutes(1),
            QueueLimit = 0
        });
    });
    options.AddPolicy("Appointment", context =>
    {
        var key = $"appointment:{GetUserOrIp(context)}";
        return RateLimitPartition.GetFixedWindowLimiter(key, _ => new FixedWindowRateLimiterOptions
        {
            PermitLimit = 5,
            Window = TimeSpan.FromMinutes(1),
            QueueLimit = 0
        });
    });
    options.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(context =>
    {
        var isAuthenticated = context.User.Identity?.IsAuthenticated == true;
        var key = $"global:{GetUserOrIp(context)}";
        return RateLimitPartition.GetFixedWindowLimiter(key, _ => new FixedWindowRateLimiterOptions
        {
            PermitLimit = isAuthenticated ? 300 : 100,
            Window = TimeSpan.FromMinutes(1),
            QueueLimit = 0
        });
    });
});

var app = builder.Build();

using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    var databaseProvider = app.Configuration["Database:Provider"];
    if (app.Environment.IsDevelopment() && IsSqlServer(databaseProvider))
    {
        await EnsureDevelopmentSqlServerCreatedAsync(db);
    }
    else if (db.Database.IsRelational())
    {
        await db.Database.MigrateAsync();
    }
}

await SeedData.InitializeAsync(app.Services);

app.UseMiddleware<GlobalExceptionMiddleware>();

app.MapHealthChecks("/health", new HealthCheckOptions
{
    ResponseWriter = async (context, report) =>
    {
        context.Response.ContentType = "application/json";
        var result = new
        {
            status = report.Status.ToString(),
            checks = report.Entries.Select(e => new
            {
                name = e.Key,
                status = e.Value.Status.ToString(),
                description = e.Value.Description,
                duration = e.Value.Duration
            }),
            totalDuration = report.TotalDuration
        };
        await context.Response.WriteAsync(System.Text.Json.JsonSerializer.Serialize(result));
    }
});

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

if (!app.Environment.IsEnvironment("Testing"))
{
    app.UseHttpsRedirection();
}
app.UseStaticFiles();
app.UseCors("MobileClient");
app.UseAuthentication();
app.UseRateLimiter();
app.UseAuthorization();
app.MapControllers();

if (!app.Environment.IsEnvironment("Testing"))
{
    var logger = app.Services.GetRequiredService<ILogger<Program>>();

    _ = Task.Run(async () =>
    {
        await Task.Delay(TimeSpan.FromMinutes(1));
        while (true)
        {
            try
            {
                await CleanupJobs.CleanupExpiredOtpsAsync(app.Services, logger);
                await CleanupJobs.CleanupRevokedTokensAsync(app.Services, logger);
                await CleanupJobs.CompleteExpiredAppointmentsAsync(app.Services, logger);
                await CleanupJobs.CleanupOldNotificationsAsync(app.Services, logger);
                await CleanupJobs.CleanupInactiveDeviceTokensAsync(app.Services, logger);
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Background cleanup job hatası");
            }

            await Task.Delay(TimeSpan.FromHours(1));
        }
    });
}

app.Run();

static bool IsSqlServer(string? provider) =>
    string.Equals(provider, "SqlServer", StringComparison.OrdinalIgnoreCase) ||
    string.Equals(provider, "MSSQL", StringComparison.OrdinalIgnoreCase);

static async Task EnsureDevelopmentSqlServerCreatedAsync(AppDbContext db)
{
    try
    {
        await db.Database.EnsureCreatedAsync();
        _ = await db.Users.AnyAsync();
        _ = await db.BarberShops.AnyAsync();
        _ = await db.StaffServices.AnyAsync();
        _ = await db.WorkingHours.AnyAsync();
        _ = await db.SupportTicketReplies.AnyAsync();
    }
    catch (SqlException ex) when (IsDevelopmentSchemaError(ex))
    {
        await db.Database.EnsureDeletedAsync();
        await db.Database.EnsureCreatedAsync();
    }
}

static bool IsDevelopmentSchemaError(SqlException ex) =>
    ex.Message.Contains("Invalid object name", StringComparison.OrdinalIgnoreCase) ||
    ex.Message.Contains("Could not create constraint", StringComparison.OrdinalIgnoreCase);

static string GetClientIp(HttpContext context) =>
    context.Connection.RemoteIpAddress?.ToString() ?? "unknown";

static string GetUserOrIp(HttpContext context) =>
    context.User.FindFirstValue(ClaimTypes.NameIdentifier) ?? GetClientIp(context);

public partial class Program;
