namespace BerberYanimda.Application.DTOs;

public sealed record BarberListItemDto(
    Guid Id,
    string Name,
    string District,
    string City,
    decimal Rating,
    int ReviewCount,
    decimal? DistanceKm,
    decimal StartingPrice,
    bool IsAvailableToday,
    string? CoverImageUrl,
    bool IsFavorite);

public sealed record BarberDetailDto(
    Guid Id,
    string Name,
    string? Description,
    string District,
    string City,
    string Address,
    string PhoneNumber,
    decimal? Latitude,
    decimal? Longitude,
    decimal Rating,
    int ReviewCount,
    decimal StartingPrice,
    string? CoverImageUrl,
    string? LogoUrl,
    bool IsFavorite,
    IReadOnlyList<BarberServiceDto> Services,
    IReadOnlyList<StaffDto> Staff);

public sealed record BarberServiceDto(Guid Id, string Name, string? Description, int DurationMinutes, decimal Price);

public sealed record StaffDto(
    Guid Id,
    string FullName,
    string? Expertise,
    string? Bio,
    string? AvatarUrl,
    decimal AverageRating,
    bool IsAvailableToday);

public sealed record AvailabilitySlotDto(string StartTime, string EndTime, bool IsAvailable);

public sealed record AddBarberImageRequest(string ImageUrl, int SortOrder);

public sealed record UpdateStaffAvatarRequest(string AvatarUrl);
