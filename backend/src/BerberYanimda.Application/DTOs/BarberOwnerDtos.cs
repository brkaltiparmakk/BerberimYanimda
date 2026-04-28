namespace BerberYanimda.Application.DTOs;

public sealed record CreateBarberShopRequest(
    string Name,
    string? Description,
    string PhoneNumber,
    string City,
    string District,
    string Address,
    decimal? Latitude,
    decimal? Longitude);

public sealed record UpdateBarberShopRequest(
    string Name,
    string? Description,
    string PhoneNumber,
    string City,
    string District,
    string Address,
    decimal? Latitude,
    decimal? Longitude);

public sealed record BarberShopDetailDto(
    Guid Id,
    string Name,
    string? Description,
    string PhoneNumber,
    string? Email,
    string City,
    string District,
    string Address,
    decimal? Latitude,
    decimal? Longitude,
    string? CoverImageUrl,
    string? LogoUrl,
    bool IsApproved,
    bool IsActive,
    DateTime CreatedAt);

public sealed record CreateServiceRequest(
    string Name,
    string? Description,
    int DurationMinutes,
    decimal Price);

public sealed record UpdateServiceRequest(
    string Name,
    string? Description,
    int DurationMinutes,
    decimal Price);

public sealed record OwnerServiceDto(
    Guid Id,
    string Name,
    string? Description,
    int DurationMinutes,
    decimal Price,
    bool IsActive,
    DateTime CreatedAt);

public sealed record CreateStaffRequest(
    string FullName,
    string? Expertise,
    string? Bio);

public sealed record UpdateStaffRequest(
    string FullName,
    string? Expertise,
    string? Bio);

public sealed record OwnerStaffDto(
    Guid Id,
    string FullName,
    string? Expertise,
    string? Bio,
    string? AvatarUrl,
    decimal AverageRating,
    bool IsActive,
    IReadOnlyList<OwnerServiceDto> Services);

public sealed record UpdateWorkingHoursRequest(
    IReadOnlyList<WorkingHourEntryDto> WorkingHours);

public sealed record WorkingHourEntryDto(
    int DayOfWeek,
    TimeOnly StartTime,
    TimeOnly EndTime,
    bool IsClosed);

public sealed record OwnerWorkingHourDto(
    Guid Id,
    int DayOfWeek,
    TimeOnly StartTime,
    TimeOnly EndTime,
    bool IsClosed);

public sealed record OwnerAppointmentDto(
    Guid Id,
    Guid CustomerUserId,
    string CustomerName,
    string? CustomerPhone,
    Guid? StaffMemberId,
    string? StaffName,
    DateOnly AppointmentDate,
    string StartTime,
    string EndTime,
    int TotalDurationMinutes,
    decimal TotalPrice,
    string Status,
    IReadOnlyList<AppointmentServiceDto> Services,
    string? CustomerNote);

public sealed record DashboardDto(
    int TotalAppointments,
    int TodayAppointments,
    int PendingAppointments,
    int CompletedAppointments,
    decimal TotalRevenue,
    decimal TodayRevenue,
    int TotalReviews,
    decimal AverageRating);

public sealed record AssignStaffServicesRequest(IReadOnlyList<Guid> ServiceIds);
