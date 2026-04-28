using BerberYanimda.Domain;

namespace BerberYanimda.Application.DTOs;

public sealed record CreateAppointmentRequest(
    Guid BarberShopId,
    Guid? StaffMemberId,
    DateOnly AppointmentDate,
    TimeOnly StartTime,
    IReadOnlyList<Guid> ServiceIds,
    string? CustomerNote);

public sealed record CancelAppointmentRequest(string? Reason);

public sealed record RejectAppointmentRequest(string? Reason);

public sealed record ShopAppointmentsQuery(
    DateOnly? Date,
    AppointmentStatus? Status,
    int Page = 1,
    int PageSize = 20);

public sealed record AppointmentDto(
    Guid Id,
    Guid BarberShopId,
    string BarberName,
    string? BarberImageUrl,
    string? BarberPhoneNumber,
    string? BarberAddress,
    decimal? Latitude,
    decimal? Longitude,
    Guid? StaffMemberId,
    string? StaffName,
    DateOnly AppointmentDate,
    string StartTime,
    string EndTime,
    int TotalDurationMinutes,
    decimal TotalPrice,
    AppointmentStatus Status,
    IReadOnlyList<AppointmentServiceDto> Services,
    string? CustomerNote,
    string? CustomerName,
    string? RejectionReason);

public sealed record AppointmentServiceDto(Guid BarberServiceId, string ServiceName, int DurationMinutes, decimal Price);

public sealed record PayAtBarberRequest(Guid AppointmentId);

public sealed record CreatePaymentSessionRequest(Guid AppointmentId);

public sealed record PaymentSessionDto(
    string SessionId,
    string RedirectUrl,
    decimal Amount,
    string Currency);

public sealed record PaymentDto(
    Guid Id,
    Guid AppointmentId,
    PaymentMethod PaymentMethod,
    PaymentStatus Status,
    decimal Amount,
    string Currency);

public sealed record FavoriteDto(Guid BarberShopId, string Name, string District, string City, string? CoverImageUrl, decimal Rating);

public sealed record NotificationDto(Guid Id, string Title, string Message, NotificationType Type, bool IsRead, DateTime CreatedAt);
