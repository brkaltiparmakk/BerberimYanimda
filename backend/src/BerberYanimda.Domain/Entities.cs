namespace BerberYanimda.Domain;

public abstract class Entity
{
    public Guid Id { get; set; } = Guid.NewGuid();
}

public sealed class User : Entity
{
    public string FullName { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string? PasswordHash { get; set; }
    public UserRole Role { get; set; } = UserRole.Customer;
    public bool IsPhoneVerified { get; set; }
    public bool IsEmailVerified { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime? DeletedAt { get; set; }
    public string? ProfileImageUrl { get; set; }
    public DateOnly? BirthDate { get; set; }
    public string? MfaSecret { get; set; }
    public bool MfaEnabled { get; set; }
    public DateTime? MfaVerifiedAt { get; set; }
    public DateTime? MfaDisabledAt { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }
}

public sealed class RefreshToken : Entity
{
    public Guid UserId { get; set; }
    public User? User { get; set; }
    public string TokenHash { get; set; } = string.Empty;
    public DateTime ExpiresAt { get; set; }
    public DateTime? RevokedAt { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public string? IpAddress { get; set; }
    public string? UserAgent { get; set; }
}

public sealed class OtpCode : Entity
{
    public string PhoneNumber { get; set; } = string.Empty;
    public string CodeHash { get; set; } = string.Empty;
    public string Purpose { get; set; } = "PhoneVerification";
    public int AttemptCount { get; set; }
    public DateTime SentAt { get; set; } = DateTime.UtcNow;
    public DateTime ExpiresAt { get; set; }
    public DateTime? LockedUntil { get; set; }
    public DateTime? VerifiedAt { get; set; }
}

public sealed class BarberShop : Entity
{
    public Guid OwnerUserId { get; set; }
    public User? OwnerUser { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? PhoneNumber { get; set; }
    public string? Email { get; set; }
    public string City { get; set; } = string.Empty;
    public string District { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public decimal? Latitude { get; set; }
    public decimal? Longitude { get; set; }
    public string? CoverImageUrl { get; set; }
    public string? LogoUrl { get; set; }
    public decimal AverageRating { get; set; }
    public int ReviewCount { get; set; }
    public decimal StartingPrice { get; set; }
    public bool IsApproved { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime? DeletedAt { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }
    public List<BarberService> Services { get; set; } = [];
    public List<StaffMember> StaffMembers { get; set; } = [];
    public List<WorkingHour> WorkingHours { get; set; } = [];
}

public sealed class BarberShopImage : Entity
{
    public Guid BarberShopId { get; set; }
    public BarberShop? BarberShop { get; set; }
    public string ImageUrl { get; set; } = string.Empty;
    public int SortOrder { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

public sealed class BarberService : Entity
{
    public Guid BarberShopId { get; set; }
    public BarberShop? BarberShop { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public int DurationMinutes { get; set; }
    public decimal Price { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime? DeletedAt { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }
    public List<StaffService> StaffServices { get; set; } = [];
}

public sealed class StaffMember : Entity
{
    public Guid BarberShopId { get; set; }
    public BarberShop? BarberShop { get; set; }
    public Guid? UserId { get; set; }
    public User? User { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string? Expertise { get; set; }
    public string? Bio { get; set; }
    public string? AvatarUrl { get; set; }
    public decimal AverageRating { get; set; }
    public int ReviewCount { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime? DeletedAt { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }
    public List<StaffService> StaffServices { get; set; } = [];
}

public sealed class StaffService : Entity
{
    public Guid StaffMemberId { get; set; }
    public StaffMember? StaffMember { get; set; }
    public Guid BarberServiceId { get; set; }
    public BarberService? BarberService { get; set; }
}

public sealed class WorkingHour : Entity
{
    public Guid BarberShopId { get; set; }
    public BarberShop? BarberShop { get; set; }
    public Guid? StaffMemberId { get; set; }
    public StaffMember? StaffMember { get; set; }
    public int DayOfWeek { get; set; }
    public TimeOnly StartTime { get; set; }
    public TimeOnly EndTime { get; set; }
    public bool IsClosed { get; set; }
}

public sealed class StaffBreak : Entity
{
    public Guid StaffMemberId { get; set; }
    public StaffMember? StaffMember { get; set; }
    public DateOnly BreakDate { get; set; }
    public TimeOnly StartTime { get; set; }
    public TimeOnly EndTime { get; set; }
    public string? Reason { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

public sealed class Appointment : Entity
{
    public Guid CustomerUserId { get; set; }
    public User? CustomerUser { get; set; }
    public Guid BarberShopId { get; set; }
    public BarberShop? BarberShop { get; set; }
    public Guid? StaffMemberId { get; set; }
    public StaffMember? StaffMember { get; set; }
    public DateOnly AppointmentDate { get; set; }
    public TimeOnly StartTime { get; set; }
    public TimeOnly EndTime { get; set; }
    public int TotalDurationMinutes { get; set; }
    public decimal TotalPrice { get; set; }
    public AppointmentStatus Status { get; set; } = AppointmentStatus.Pending;
    public string? CustomerNote { get; set; }
    public string? CancellationReason { get; set; }
    public DateTime? CancelledAt { get; set; }
    public DateTime? CompletedAt { get; set; }
    public string? RejectionReason { get; set; }
    public DateTime? RejectedAt { get; set; }
    public DateTime? DeletedAt { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }
    public List<AppointmentService> Services { get; set; } = [];
}

public sealed class AppointmentService : Entity
{
    public Guid AppointmentId { get; set; }
    public Appointment? Appointment { get; set; }
    public Guid BarberServiceId { get; set; }
    public BarberService? BarberService { get; set; }
    public string ServiceName { get; set; } = string.Empty;
    public int DurationMinutes { get; set; }
    public decimal Price { get; set; }
}

public sealed class Payment : Entity
{
    public Guid AppointmentId { get; set; }
    public Appointment? Appointment { get; set; }
    public Guid CustomerUserId { get; set; }
    public User? CustomerUser { get; set; }
    public PaymentMethod PaymentMethod { get; set; } = PaymentMethod.PayAtBarber;
    public string? PaymentProvider { get; set; }
    public string? ProviderTransactionId { get; set; }
    public decimal Amount { get; set; }
    public string Currency { get; set; } = "TRY";
    public PaymentStatus Status { get; set; } = PaymentStatus.Pending;
    public DateTime? PaidAt { get; set; }
    public string? FailedReason { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }
}

public sealed class FavoriteBarberShop : Entity
{
    public Guid UserId { get; set; }
    public User? User { get; set; }
    public Guid BarberShopId { get; set; }
    public BarberShop? BarberShop { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

public sealed class Notification : Entity
{
    public Guid UserId { get; set; }
    public User? User { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public NotificationType Type { get; set; } = NotificationType.System;
    public bool IsRead { get; set; }
    public string? DataJson { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

public sealed class AuditLog : Entity
{
    public Guid? UserId { get; set; }
    public string Action { get; set; } = string.Empty;
    public string? EntityName { get; set; }
    public string? EntityId { get; set; }
    public string? OldValue { get; set; }
    public string? NewValue { get; set; }
    public string? IpAddress { get; set; }
    public string? UserAgent { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

public sealed class Review : Entity
{
    public Guid AppointmentId { get; set; }
    public Appointment? Appointment { get; set; }
    public Guid CustomerUserId { get; set; }
    public User? CustomerUser { get; set; }
    public Guid BarberShopId { get; set; }
    public BarberShop? BarberShop { get; set; }
    public Guid? StaffMemberId { get; set; }
    public StaffMember? StaffMember { get; set; }
    public int Rating { get; set; }
    public string? Comment { get; set; }
    public bool IsApproved { get; set; }
    public DateTime? DeletedAt { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

public sealed class DeviceToken : Entity
{
    public Guid UserId { get; set; }
    public User? User { get; set; }
    public string Token { get; set; } = string.Empty;
    public string Platform { get; set; } = string.Empty;
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }
}

public sealed class Coupon : Entity
{
    public string Code { get; set; } = string.Empty;
    public string? Description { get; set; }
    public decimal? DiscountAmount { get; set; }
    public decimal? DiscountPercentage { get; set; }
    public decimal? MinOrderAmount { get; set; }
    public decimal? MaxDiscountAmount { get; set; }
    public DateTime ValidFrom { get; set; }
    public DateTime ValidUntil { get; set; }
    public int UsageLimit { get; set; }
    public int UsageCount { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime? DeletedAt { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }
}

public sealed class CouponUsage : Entity
{
    public Guid CouponId { get; set; }
    public Coupon? Coupon { get; set; }
    public Guid UserId { get; set; }
    public User? User { get; set; }
    public Guid? AppointmentId { get; set; }
    public Appointment? Appointment { get; set; }
    public decimal DiscountApplied { get; set; }
    public DateTime UsedAt { get; set; } = DateTime.UtcNow;
}

public sealed class SupportTicket : Entity
{
    public Guid UserId { get; set; }
    public User? User { get; set; }
    public string Subject { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public SupportTicketStatus Status { get; set; } = SupportTicketStatus.Open;
    public string? Category { get; set; }
    public string? Resolution { get; set; }
    public DateTime? ResolvedAt { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }
    public List<SupportTicketReply> Replies { get; set; } = [];
}

public sealed class SupportTicketReply : Entity
{
    public Guid SupportTicketId { get; set; }
    public SupportTicket? SupportTicket { get; set; }
    public Guid? UserId { get; set; }
    public User? User { get; set; }
    public string Message { get; set; } = string.Empty;
    public bool IsStaffReply { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
