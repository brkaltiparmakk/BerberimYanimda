using BerberYanimda.Domain;

namespace BerberYanimda.Application.DTOs;

public sealed record RegisterRequest(string FullName, string PhoneNumber, string? Email, string Password);
public sealed record LoginRequest(string PhoneNumber, string Password);
public sealed record VerifyOtpRequest(string PhoneNumber, string Code);
public sealed record RefreshTokenRequest(string RefreshToken);
public sealed record LogoutRequest(string RefreshToken);

public sealed record UserSummaryDto(Guid Id, string FullName, string PhoneNumber, string? Email, UserRole Role);

public sealed record TokenResponse(
    string AccessToken,
    string RefreshToken,
    int ExpiresIn,
    UserSummaryDto User);

public sealed record UserProfileDto(
    Guid Id,
    string FullName,
    string PhoneNumber,
    string? Email,
    string? ProfileImageUrl,
    DateOnly? BirthDate,
    UserRole Role,
    bool IsPhoneVerified);

public sealed record UpdateProfileRequest(string FullName, string? Email, DateOnly? BirthDate);

public sealed record ChangePasswordRequest(string CurrentPassword, string NewPassword);

public sealed record DeleteAccountRequest(string Password);

public sealed record UserDataExportDto(
    UserProfileDto UserProfile,
    DateTime CreatedAt,
    IReadOnlyList<AppointmentDto> Appointments,
    IReadOnlyList<PaymentDto> Payments,
    IReadOnlyList<ReviewDto> Reviews);
