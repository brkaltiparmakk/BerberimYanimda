using BerberYanimda.Application.Interfaces;
using BerberYanimda.Domain;
using Microsoft.EntityFrameworkCore;

namespace BerberYanimda.Infrastructure.Persistence;

public sealed class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options), IAppDbContext
{
    public DbSet<User> Users => Set<User>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();
    public DbSet<OtpCode> OtpCodes => Set<OtpCode>();
    public DbSet<BarberShop> BarberShops => Set<BarberShop>();
    public DbSet<BarberShopImage> BarberShopImages => Set<BarberShopImage>();
    public DbSet<BarberService> BarberServices => Set<BarberService>();
    public DbSet<StaffMember> StaffMembers => Set<StaffMember>();
    public DbSet<StaffService> StaffServices => Set<StaffService>();
    public DbSet<WorkingHour> WorkingHours => Set<WorkingHour>();
    public DbSet<StaffBreak> StaffBreaks => Set<StaffBreak>();
    public DbSet<Appointment> Appointments => Set<Appointment>();
    public DbSet<AppointmentService> AppointmentServices => Set<AppointmentService>();
    public DbSet<Payment> Payments => Set<Payment>();
    public DbSet<FavoriteBarberShop> FavoriteBarberShops => Set<FavoriteBarberShop>();
    public DbSet<Notification> Notifications => Set<Notification>();
    public DbSet<AuditLog> AuditLogs => Set<AuditLog>();
    public DbSet<Review> Reviews => Set<Review>();
    public DbSet<DeviceToken> DeviceTokens => Set<DeviceToken>();
    public DbSet<Coupon> Coupons => Set<Coupon>();
    public DbSet<CouponUsage> CouponUsages => Set<CouponUsage>();
    public DbSet<SupportTicket> SupportTickets => Set<SupportTicket>();
    public DbSet<SupportTicketReply> SupportTicketReplies => Set<SupportTicketReply>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<User>(b =>
        {
            b.HasIndex(x => x.PhoneNumber).IsUnique();
            b.HasIndex(x => x.Email);
            b.HasIndex(x => x.Role);
            b.Property(x => x.Role).HasConversion<string>().HasMaxLength(50);
            b.Property(x => x.FullName).HasMaxLength(150);
            b.Property(x => x.PhoneNumber).HasMaxLength(30);
            b.Property(x => x.Email).HasMaxLength(150);
            b.Property(x => x.PasswordHash).HasMaxLength(500);
            b.Property(x => x.MfaSecret).HasMaxLength(200);
            b.Property(x => x.ProfileImageUrl).HasMaxLength(500);
            b.HasQueryFilter(x => x.DeletedAt == null);
        });

        modelBuilder.Entity<BarberShop>(b =>
        {
            b.HasIndex(x => new { x.City, x.District });
            b.HasIndex(x => x.IsApproved);
            b.HasIndex(x => x.AverageRating);
            b.Property(x => x.AverageRating).HasPrecision(3, 2);
            b.Property(x => x.StartingPrice).HasPrecision(18, 2);
            b.Property(x => x.Latitude).HasPrecision(10, 7);
            b.Property(x => x.Longitude).HasPrecision(10, 7);
            b.HasOne(x => x.OwnerUser).WithMany().HasForeignKey(x => x.OwnerUserId).OnDelete(DeleteBehavior.Restrict);
            b.HasQueryFilter(x => x.DeletedAt == null);
        });

        modelBuilder.Entity<BarberService>(b =>
        {
            b.Property(x => x.Price).HasPrecision(18, 2);
            b.HasOne(x => x.BarberShop).WithMany(x => x.Services).HasForeignKey(x => x.BarberShopId);
            b.HasQueryFilter(x => x.DeletedAt == null);
        });

        modelBuilder.Entity<StaffMember>(b =>
        {
            b.Property(x => x.AverageRating).HasPrecision(3, 2);
            b.HasOne(x => x.BarberShop).WithMany(x => x.StaffMembers).HasForeignKey(x => x.BarberShopId);
            b.HasOne(x => x.User).WithMany().HasForeignKey(x => x.UserId).OnDelete(DeleteBehavior.SetNull);
            b.HasQueryFilter(x => x.DeletedAt == null);
        });

        modelBuilder.Entity<StaffService>(b =>
        {
            b.HasIndex(x => new { x.StaffMemberId, x.BarberServiceId }).IsUnique();
            b.HasOne(x => x.StaffMember).WithMany(x => x.StaffServices).HasForeignKey(x => x.StaffMemberId).OnDelete(DeleteBehavior.NoAction);
            b.HasOne(x => x.BarberService).WithMany(x => x.StaffServices).HasForeignKey(x => x.BarberServiceId).OnDelete(DeleteBehavior.NoAction);
        });

        modelBuilder.Entity<WorkingHour>(b =>
        {
            b.HasIndex(x => new { x.BarberShopId, x.StaffMemberId, x.DayOfWeek }).IsUnique();
            b.HasOne(x => x.BarberShop).WithMany(x => x.WorkingHours).HasForeignKey(x => x.BarberShopId);
            b.HasOne(x => x.StaffMember).WithMany().HasForeignKey(x => x.StaffMemberId).OnDelete(DeleteBehavior.NoAction);
        });

        modelBuilder.Entity<Appointment>(b =>
        {
            b.HasIndex(x => x.CustomerUserId);
            b.HasIndex(x => x.BarberShopId);
            b.HasIndex(x => new { x.StaffMemberId, x.AppointmentDate });
            b.HasIndex(x => x.Status);
            b.Property(x => x.Status).HasConversion<string>().HasMaxLength(50);
            b.Property(x => x.TotalPrice).HasPrecision(18, 2);
            b.HasOne(x => x.CustomerUser).WithMany().HasForeignKey(x => x.CustomerUserId).OnDelete(DeleteBehavior.Restrict);
            b.HasOne(x => x.BarberShop).WithMany().HasForeignKey(x => x.BarberShopId).OnDelete(DeleteBehavior.Restrict);
            b.HasOne(x => x.StaffMember).WithMany().HasForeignKey(x => x.StaffMemberId).OnDelete(DeleteBehavior.SetNull);
            b.HasQueryFilter(x => x.DeletedAt == null);
        });

        modelBuilder.Entity<AppointmentService>(b =>
        {
            b.Property(x => x.Price).HasPrecision(18, 2);
            b.HasOne(x => x.Appointment).WithMany(x => x.Services).HasForeignKey(x => x.AppointmentId);
            b.HasOne(x => x.BarberService).WithMany().HasForeignKey(x => x.BarberServiceId).OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<Payment>(b =>
        {
            b.Property(x => x.PaymentMethod).HasConversion<string>().HasMaxLength(50);
            b.Property(x => x.Status).HasConversion<string>().HasMaxLength(50);
            b.Property(x => x.Amount).HasPrecision(18, 2);
            b.HasIndex(x => x.AppointmentId).IsUnique();
        });

        modelBuilder.Entity<FavoriteBarberShop>(b =>
        {
            b.HasIndex(x => new { x.UserId, x.BarberShopId }).IsUnique();
            b.HasOne(x => x.User).WithMany().HasForeignKey(x => x.UserId).OnDelete(DeleteBehavior.Cascade);
            b.HasOne(x => x.BarberShop).WithMany().HasForeignKey(x => x.BarberShopId).OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<Notification>(b =>
        {
            b.Property(x => x.Type).HasConversion<string>().HasMaxLength(50);
            b.HasIndex(x => new { x.UserId, x.IsRead });
        });

        modelBuilder.Entity<RefreshToken>().HasIndex(x => x.TokenHash).IsUnique();
        modelBuilder.Entity<OtpCode>().HasIndex(x => new { x.PhoneNumber, x.SentAt });

        modelBuilder.Entity<Review>(b =>
        {
            b.HasIndex(x => x.AppointmentId).IsUnique();
            b.HasIndex(x => x.BarberShopId);
            b.HasIndex(x => x.CustomerUserId);
            b.HasIndex(x => new { x.BarberShopId, x.IsApproved });
            b.Property(x => x.Rating).IsRequired();
            b.Property(x => x.Comment).HasMaxLength(1000);
            b.HasOne(x => x.Appointment).WithMany().HasForeignKey(x => x.AppointmentId).OnDelete(DeleteBehavior.Restrict);
            b.HasOne(x => x.CustomerUser).WithMany().HasForeignKey(x => x.CustomerUserId).OnDelete(DeleteBehavior.Restrict);
            b.HasOne(x => x.BarberShop).WithMany().HasForeignKey(x => x.BarberShopId).OnDelete(DeleteBehavior.Restrict);
            b.HasOne(x => x.StaffMember).WithMany().HasForeignKey(x => x.StaffMemberId).OnDelete(DeleteBehavior.SetNull);
            b.HasQueryFilter(x => x.DeletedAt == null);
        });

        modelBuilder.Entity<DeviceToken>(b =>
        {
            b.HasIndex(x => new { x.UserId, x.Token }).IsUnique();
            b.HasIndex(x => x.IsActive);
            b.Property(x => x.Token).HasMaxLength(500);
            b.Property(x => x.Platform).HasMaxLength(20);
            b.HasOne(x => x.User).WithMany().HasForeignKey(x => x.UserId).OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<Coupon>(b =>
        {
            b.HasIndex(x => x.Code).IsUnique();
            b.Property(x => x.Code).HasMaxLength(50);
            b.Property(x => x.DiscountAmount).HasPrecision(18, 2);
            b.Property(x => x.DiscountPercentage).HasPrecision(5, 2);
            b.Property(x => x.MinOrderAmount).HasPrecision(18, 2);
            b.Property(x => x.MaxDiscountAmount).HasPrecision(18, 2);
            b.ToTable(t => t.HasCheckConstraint(
                "CK_Coupon_DiscountExclusive",
                "(\"DiscountAmount\" IS NULL AND \"DiscountPercentage\" IS NOT NULL) OR (\"DiscountAmount\" IS NOT NULL AND \"DiscountPercentage\" IS NULL)"));
            b.ToTable(t => t.HasCheckConstraint(
                "CK_Coupon_DiscountPercentage",
                "\"DiscountPercentage\" IS NULL OR (\"DiscountPercentage\" >= 0 AND \"DiscountPercentage\" <= 100)"));
            b.ToTable(t => t.HasCheckConstraint(
                "CK_Coupon_MinOrderAmount",
                "\"MinOrderAmount\" IS NULL OR \"MinOrderAmount\" >= 0"));
            b.HasQueryFilter(x => x.DeletedAt == null);
        });

        modelBuilder.Entity<CouponUsage>(b =>
        {
            b.HasIndex(x => new { x.CouponId, x.UserId }).IsUnique();
            b.Property(x => x.DiscountApplied).HasPrecision(18, 2);
            b.HasOne(x => x.Coupon).WithMany().HasForeignKey(x => x.CouponId).OnDelete(DeleteBehavior.Cascade);
            b.HasOne(x => x.User).WithMany().HasForeignKey(x => x.UserId).OnDelete(DeleteBehavior.Cascade);
            b.HasOne(x => x.Appointment).WithMany().HasForeignKey(x => x.AppointmentId).OnDelete(DeleteBehavior.SetNull);
        });

        modelBuilder.Entity<SupportTicket>(b =>
        {
            b.HasIndex(x => x.UserId);
            b.HasIndex(x => x.Status);
            b.Property(x => x.Status).HasConversion<string>().HasMaxLength(50);
            b.Property(x => x.Subject).HasMaxLength(200);
            b.HasOne(x => x.User).WithMany().HasForeignKey(x => x.UserId).OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<SupportTicketReply>(b =>
        {
            b.HasIndex(x => x.SupportTicketId);
            b.HasOne(x => x.SupportTicket).WithMany(x => x.Replies).HasForeignKey(x => x.SupportTicketId).OnDelete(DeleteBehavior.Cascade);
            b.HasOne(x => x.User).WithMany().HasForeignKey(x => x.UserId).OnDelete(DeleteBehavior.NoAction);
        });
    }
}
