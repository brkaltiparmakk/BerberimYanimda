using BerberYanimda.Domain;
using Microsoft.EntityFrameworkCore;

namespace BerberYanimda.Application.Interfaces;

public interface IAppDbContext
{
    DbSet<User> Users { get; }
    DbSet<RefreshToken> RefreshTokens { get; }
    DbSet<OtpCode> OtpCodes { get; }
    DbSet<BarberShop> BarberShops { get; }
    DbSet<BarberShopImage> BarberShopImages { get; }
    DbSet<BarberService> BarberServices { get; }
    DbSet<StaffMember> StaffMembers { get; }
    DbSet<StaffService> StaffServices { get; }
    DbSet<WorkingHour> WorkingHours { get; }
    DbSet<StaffBreak> StaffBreaks { get; }
    DbSet<Appointment> Appointments { get; }
    DbSet<AppointmentService> AppointmentServices { get; }
    DbSet<Payment> Payments { get; }
    DbSet<FavoriteBarberShop> FavoriteBarberShops { get; }
    DbSet<Notification> Notifications { get; }
    DbSet<AuditLog> AuditLogs { get; }
    DbSet<Review> Reviews { get; }
    DbSet<DeviceToken> DeviceTokens { get; }
    DbSet<Coupon> Coupons { get; }
    DbSet<CouponUsage> CouponUsages { get; }
    DbSet<SupportTicket> SupportTickets { get; }
    DbSet<SupportTicketReply> SupportTicketReplies { get; }

    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
    Microsoft.EntityFrameworkCore.Infrastructure.DatabaseFacade Database { get; }
}

public interface IPasswordService
{
    string HashPassword(User user, string password);
    bool VerifyPassword(User user, string password);
}

public interface ISecureHasher
{
    string Hash(string value);
    bool Verify(string value, string hash);
}

public interface ITokenService
{
    TokenIssueResult IssueAccessToken(User user);
    string GenerateRefreshToken();
    string IssueMfaTempToken(User user);
    System.Security.Claims.ClaimsPrincipal ValidateMfaTempToken(string token);
}

public sealed record TokenIssueResult(string AccessToken, int ExpiresIn);

public interface ISmsSender
{
    Task SendOtpAsync(string phoneNumber, string code, CancellationToken cancellationToken);
}

public interface IPushNotificationService
{
    Task SendToUserAsync(Guid userId, string title, string body, Dictionary<string, string>? data = null, CancellationToken ct = default);
    Task SendToUsersAsync(IEnumerable<Guid> userIds, string title, string body, Dictionary<string, string>? data = null, CancellationToken ct = default);
    Task RegisterDeviceAsync(Guid userId, string token, string platform, CancellationToken ct = default);
    Task UnregisterDeviceAsync(string token, CancellationToken ct = default);
}

public interface IDateTimeProvider
{
    DateTime UtcNow { get; }
    DateOnly Today { get; }
}
