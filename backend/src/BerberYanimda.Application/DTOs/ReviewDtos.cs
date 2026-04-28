namespace BerberYanimda.Application.DTOs;

public sealed record CreateReviewRequest(Guid AppointmentId, int Rating, string? Comment);

public sealed record ReviewDto(
    Guid Id,
    Guid AppointmentId,
    Guid CustomerUserId,
    string CustomerName,
    Guid BarberShopId,
    Guid? StaffMemberId,
    string? StaffName,
    int Rating,
    string? Comment,
    bool IsApproved,
    DateTime CreatedAt);

public sealed record ReviewSummaryDto(decimal AverageRating, int ReviewCount);
