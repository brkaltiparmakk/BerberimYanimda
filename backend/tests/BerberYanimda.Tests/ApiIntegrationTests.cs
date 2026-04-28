using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using BerberYanimda.Application.Interfaces;
using BerberYanimda.Domain;
using BerberYanimda.Infrastructure.Persistence;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace BerberYanimda.Tests;

public sealed class ApiIntegrationTests
{
    [Fact]
    public async Task Customer_can_complete_real_booking_flow_through_http_api()
    {
        await using var app = CreateFactory();
        using var client = app.CreateClient();

        var token = await LoginAsync(client, "+905551112233", "Test1234!");
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

        var me = await GetDataAsync(await client.GetAsync("/api/v1/users/me"));
        Assert.Equal("+905551112233", me.GetProperty("phoneNumber").GetString());

        var barbers = await GetDataAsync(await client.GetAsync("/api/v1/barbers?page=1&pageSize=5"));
        var barber = barbers.GetProperty("items").EnumerateArray().First();
        var barberId = barber.GetProperty("id").GetString()!;

        var detail = await GetDataAsync(await client.GetAsync($"/api/v1/barbers/{barberId}"));
        var serviceId = detail.GetProperty("services")[0].GetProperty("id").GetString()!;
        var staffId = detail.GetProperty("staff")[0].GetProperty("id").GetString()!;
        var date = DateOnly.FromDateTime(DateTime.UtcNow.AddDays(3)).ToString("yyyy-MM-dd");

        var availability = await GetDataAsync(await client.GetAsync($"/api/v1/availability?barberShopId={barberId}&staffMemberId={staffId}&serviceIds={serviceId}&date={date}"));
        var slot = availability.EnumerateArray().First(x => x.GetProperty("isAvailable").GetBoolean());
        var startTime = slot.GetProperty("startTime").GetString()!;

        var createResponse = await client.PostAsJsonAsync("/api/v1/appointments", new
        {
            barberShopId = barberId,
            staffMemberId = staffId,
            appointmentDate = date,
            startTime,
            serviceIds = new[] { serviceId },
            customerNote = "Integration test"
        });
        var appointment = await GetDataAsync(createResponse);
        var appointmentId = appointment.GetProperty("id").GetString()!;
        Assert.Equal("Pending", appointment.GetProperty("status").GetString());

        var payment = await GetDataAsync(await client.PostAsJsonAsync("/api/v1/payments/pay-at-barber", new { appointmentId }));
        Assert.Equal("PayAtBarber", payment.GetProperty("paymentMethod").GetString());

        var mine = await GetDataAsync(await client.GetAsync("/api/v1/appointments/my"));
        Assert.Contains(mine.EnumerateArray(), x => x.GetProperty("id").GetString() == appointmentId);

        var cancelled = await GetDataAsync(await client.PostAsJsonAsync($"/api/v1/appointments/{appointmentId}/cancel", new { reason = "Plan değişti" }));
        Assert.Equal("Cancelled", cancelled.GetProperty("status").GetString());
    }

    [Fact]
    public async Task Customer_cannot_read_another_customers_appointment()
    {
        await using var app = CreateFactory();
        using var client = app.CreateClient();

        var ownerToken = await LoginAsync(client, "+905551112233", "Test1234!");
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", ownerToken);

        var mine = await GetDataAsync(await client.GetAsync("/api/v1/appointments/my"));
        var appointmentId = mine.EnumerateArray().First().GetProperty("id").GetString()!;

        await AddSecondCustomerAsync(app);
        var secondToken = await LoginAsync(client, "+905559999999", "Other123!");
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", secondToken);

        var forbidden = await client.GetAsync($"/api/v1/appointments/{appointmentId}");
        Assert.Equal(HttpStatusCode.Forbidden, forbidden.StatusCode);
    }

    private static BerberApiFactory CreateFactory() => new();

    private static async Task<string> LoginAsync(HttpClient client, string phoneNumber, string password)
    {
        var data = await GetDataAsync(await client.PostAsJsonAsync("/api/v1/auth/login", new { phoneNumber, password }));
        var tokens = data.GetProperty("tokens");
        return tokens.GetProperty("accessToken").GetString()!;
    }

    private static async Task<JsonElement> GetDataAsync(HttpResponseMessage response)
    {
        var content = await response.Content.ReadAsStringAsync();
        if (string.IsNullOrWhiteSpace(content))
        {
            throw new Xunit.Sdk.XunitException($"Expected JSON response, got {(int)response.StatusCode} {response.ReasonPhrase} with empty body. Headers: {string.Join("; ", response.Headers.Select(x => $"{x.Key}={string.Join(",", x.Value)}"))}");
        }

        using var document = JsonDocument.Parse(content);
        if (!response.IsSuccessStatusCode)
        {
            throw new Xunit.Sdk.XunitException($"Expected success, got {(int)response.StatusCode}: {content}");
        }

        var root = document.RootElement.Clone();
        Assert.True(root.GetProperty("success").GetBoolean());
        return root.GetProperty("data");
    }

    private static async Task AddSecondCustomerAsync(WebApplicationFactory<Program> app)
    {
        using var scope = app.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var passwordService = scope.ServiceProvider.GetRequiredService<IPasswordService>();
        if (db.Users.Any(x => x.PhoneNumber == "+905559999999"))
        {
            return;
        }

        var user = new User
        {
            FullName = "Other Customer",
            PhoneNumber = "+905559999999",
            IsPhoneVerified = true,
            Role = UserRole.Customer
        };
        user.PasswordHash = passwordService.HashPassword(user, "Other123!");
        db.Users.Add(user);
        await db.SaveChangesAsync();
    }
}

public sealed class BerberApiFactory : WebApplicationFactory<Program>
{
    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Testing");
        builder.ConfigureAppConfiguration((_, config) =>
        {
            config.AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Database:Provider"] = "InMemory",
                ["Database:Name"] = $"BerberYanimdaTests-{Guid.NewGuid()}",
                ["Jwt:Issuer"] = "BerberYanimda",
                ["Jwt:Audience"] = "BerberYanimdaMobile",
                ["Jwt:Secret"] = "DEV_ONLY_SECRET_REPLACE_FOR_PRODUCTION_123456789",
                ["Sms:Provider"] = "Mock"
            });
        });

        builder.ConfigureServices(services =>
        {
            services.AddDbContext<AppDbContext>((_, options) =>
            {
                options.UseInMemoryDatabase($"BerberYanimdaTests-{Guid.NewGuid()}");
                options.ConfigureWarnings(warnings => warnings.Ignore(Microsoft.EntityFrameworkCore.Diagnostics.InMemoryEventId.TransactionIgnoredWarning));
            });
            services.AddSingleton<IPushNotificationService, NoOpPushNotificationService>();
        });
    }
}
