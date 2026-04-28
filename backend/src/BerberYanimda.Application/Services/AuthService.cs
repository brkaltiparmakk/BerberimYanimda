using System.Security.Cryptography;
using BerberYanimda.Application.Common;
using BerberYanimda.Application.DTOs;
using BerberYanimda.Application.Interfaces;
using BerberYanimda.Domain;
using Microsoft.EntityFrameworkCore;

namespace BerberYanimda.Application.Services;

public sealed class AuthService(
    IAppDbContext db,
    IPasswordService passwordService,
    ISecureHasher secureHasher,
    ITokenService tokenService,
    ISmsSender smsSender,
    IDateTimeProvider clock,
    IEncryptionService encryptionService,
    ITotpService totpService)
{
    public async Task RegisterAsync(RegisterRequest request, CancellationToken ct)
    {
        ValidateRequired(request.FullName, nameof(request.FullName));
        ValidateRequired(request.PhoneNumber, nameof(request.PhoneNumber));
        ValidateRequired(request.Password, nameof(request.Password));

        var phone = NormalizePhone(request.PhoneNumber);
        if (request.Password.Length < 8)
        {
            throw new AppException("Şifre minimum 8 karakter olmalıdır.", 422);
        }

        if (!request.Password.Any(char.IsUpper) || !request.Password.Any(char.IsLower) || !request.Password.Any(char.IsDigit))
        {
            throw new AppException("Şifre en az 1 büyük harf, 1 küçük harf ve 1 rakam içermelidir.", 422);
        }

        if (await db.Users.AnyAsync(x => x.PhoneNumber == phone, ct))
        {
            throw new AppException("Bu telefon numarası ile kayıt zaten mevcut.", 409);
        }

        var user = new User
        {
            FullName = request.FullName.Trim(),
            PhoneNumber = phone,
            Email = string.IsNullOrWhiteSpace(request.Email) ? null : request.Email.Trim(),
            Role = UserRole.Customer,
            IsPhoneVerified = false,
            CreatedAt = clock.UtcNow
        };
        user.PasswordHash = passwordService.HashPassword(user, request.Password);

        db.Users.Add(user);
        await CreateOtpAsync(phone, ct);
        await db.SaveChangesAsync(ct);
    }

    public async Task<LoginResult> LoginAsync(LoginRequest request, string? ipAddress, string? userAgent, CancellationToken ct)
    {
        var phone = NormalizePhone(request.PhoneNumber);
        var user = await db.Users.FirstOrDefaultAsync(x => x.PhoneNumber == phone && x.IsActive, ct);
        if (user is null || !passwordService.VerifyPassword(user, request.Password))
        {
            throw new AppException("Telefon numarası veya şifre hatalı.", 401);
        }

        if (!user.IsPhoneVerified)
        {
            throw new AppException("Telefon doğrulaması gerekli.", 403);
        }

        if (user.Role == UserRole.Admin && user.MfaEnabled && !string.IsNullOrWhiteSpace(user.MfaSecret))
        {
            var tempToken = tokenService.IssueMfaTempToken(user);
            return new LoginResult(true, tempToken, null);
        }

        var tokens = await IssueTokensAsync(user, ipAddress, userAgent, ct);
        return new LoginResult(false, null, tokens);
    }

    public async Task<TokenResponse> VerifyMfaAsync(MfaVerifyRequest request, string? ipAddress, string? userAgent, CancellationToken ct)
    {
        var principal = tokenService.ValidateMfaTempToken(request.TempToken);
        var userId = Guid.Parse(principal.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value
            ?? throw new AppException("Geçersiz token.", 401));

        var user = await db.Users.FirstOrDefaultAsync(x => x.Id == userId && x.IsActive, ct)
            ?? throw new AppException("Kullanıcı bulunamadı.", 401);

        if (!user.MfaEnabled || string.IsNullOrWhiteSpace(user.MfaSecret))
        {
            throw new AppException("MFA aktif değil.", 400);
        }

        var decryptedSecret = encryptionService.Decrypt(user.MfaSecret);
        if (!totpService.Verify(decryptedSecret, request.Code.Trim()))
        {
            throw new AppException("Geçersiz MFA kodu.", 401);
        }

        return await IssueTokensAsync(user, ipAddress, userAgent, ct);
    }

    public async Task<MfaSetupResponse> SetupMfaAsync(Guid userId, CancellationToken ct)
    {
        var user = await db.Users.FirstOrDefaultAsync(x => x.Id == userId && x.IsActive, ct)
            ?? throw new AppException("Kullanıcı bulunamadı.", 404);

        if (user.Role != UserRole.Admin)
        {
            throw new AppException("MFA sadece admin kullanıcılar için desteklenir.", 403);
        }

        var secret = totpService.GenerateSecret();
        user.MfaSecret = encryptionService.Encrypt(secret);
        user.MfaEnabled = false;
        user.UpdatedAt = clock.UtcNow;
        await db.SaveChangesAsync(ct);

        var uri = totpService.GenerateQrCodeUri(user.PhoneNumber, secret, "BerberYanimda");
        return new MfaSetupResponse(uri, secret);
    }

    public async Task VerifyMfaSetupAsync(Guid userId, string code, CancellationToken ct)
    {
        var user = await db.Users.FirstOrDefaultAsync(x => x.Id == userId && x.IsActive, ct)
            ?? throw new AppException("Kullanıcı bulunamadı.", 404);

        if (string.IsNullOrWhiteSpace(user.MfaSecret))
        {
            throw new AppException("MFA kurulumu başlatılmamış.", 400);
        }

        var decryptedSecret = encryptionService.Decrypt(user.MfaSecret);
        if (!totpService.Verify(decryptedSecret, code.Trim()))
        {
            throw new AppException("Geçersiz MFA kodu.", 422);
        }

        user.MfaEnabled = true;
        user.MfaVerifiedAt = clock.UtcNow;
        user.UpdatedAt = clock.UtcNow;
        await db.SaveChangesAsync(ct);
    }

    public async Task DisableMfaAsync(Guid userId, MfaDisableRequest request, CancellationToken ct)
    {
        var user = await db.Users.FirstOrDefaultAsync(x => x.Id == userId && x.IsActive, ct)
            ?? throw new AppException("Kullanıcı bulunamadı.", 404);

        if (!user.MfaEnabled || string.IsNullOrWhiteSpace(user.MfaSecret))
        {
            throw new AppException("MFA aktif değil.", 400);
        }

        if (!passwordService.VerifyPassword(user, request.Password))
        {
            throw new AppException("Şifre hatalı.", 401);
        }

        var decryptedSecret = encryptionService.Decrypt(user.MfaSecret);
        if (!totpService.Verify(decryptedSecret, request.Code.Trim()))
        {
            throw new AppException("Geçersiz MFA kodu.", 401);
        }

        user.MfaSecret = null;
        user.MfaEnabled = false;
        user.MfaDisabledAt = clock.UtcNow;
        user.MfaVerifiedAt = null;
        user.UpdatedAt = clock.UtcNow;
        await db.SaveChangesAsync(ct);
    }

    public async Task VerifyOtpAsync(VerifyOtpRequest request, CancellationToken ct)
    {
        var phone = NormalizePhone(request.PhoneNumber);
        var otp = await db.OtpCodes
            .Where(x => x.PhoneNumber == phone && x.VerifiedAt == null)
            .OrderByDescending(x => x.SentAt)
            .FirstOrDefaultAsync(ct);

        if (otp is null)
        {
            throw new AppException("Geçerli doğrulama kodu bulunamadı.", 404);
        }

        if (otp.LockedUntil is not null && otp.LockedUntil > clock.UtcNow)
        {
            throw new AppException("Çok fazla hatalı deneme yapıldı. Lütfen daha sonra tekrar deneyin.", 429);
        }

        if (otp.ExpiresAt <= clock.UtcNow)
        {
            throw new AppException("Doğrulama kodunun süresi doldu.", 422);
        }

        if (!secureHasher.Verify(request.Code.Trim(), otp.CodeHash))
        {
            otp.AttemptCount++;
            if (otp.AttemptCount >= 5)
            {
                otp.LockedUntil = clock.UtcNow.AddMinutes(10);
            }

            await db.SaveChangesAsync(ct);
            throw new AppException("Doğrulama kodu hatalı.", 422);
        }

        otp.VerifiedAt = clock.UtcNow;
        var user = await db.Users.FirstOrDefaultAsync(x => x.PhoneNumber == phone, ct);
        if (user is not null)
        {
            user.IsPhoneVerified = true;
            user.UpdatedAt = clock.UtcNow;
        }

        await db.SaveChangesAsync(ct);
    }

    public async Task<TokenResponse> RefreshAsync(RefreshTokenRequest request, string? ipAddress, string? userAgent, CancellationToken ct)
    {
        var hash = secureHasher.Hash(request.RefreshToken);
        var token = await db.RefreshTokens.Include(x => x.User)
            .FirstOrDefaultAsync(x => x.TokenHash == hash, ct);

        if (token?.User is null || token.RevokedAt is not null || token.ExpiresAt <= clock.UtcNow || !token.User.IsActive)
        {
            throw new AppException("Refresh token geçersiz.", 401);
        }

        token.RevokedAt = clock.UtcNow;
        return await IssueTokensAsync(token.User, ipAddress, userAgent, ct);
    }

    public async Task LogoutAsync(LogoutRequest request, CancellationToken ct)
    {
        var hash = secureHasher.Hash(request.RefreshToken);
        var token = await db.RefreshTokens.FirstOrDefaultAsync(x => x.TokenHash == hash && x.RevokedAt == null, ct);
        if (token is not null)
        {
            token.RevokedAt = clock.UtcNow;

            var userTokens = await db.RefreshTokens
                .Where(x => x.UserId == token.UserId && x.RevokedAt == null)
                .ToListAsync(ct);

            foreach (var userToken in userTokens)
            {
                userToken.RevokedAt = clock.UtcNow;
            }

            await db.SaveChangesAsync(ct);
        }
    }

    private async Task<TokenResponse> IssueTokensAsync(User user, string? ipAddress, string? userAgent, CancellationToken ct)
    {
        var accessToken = tokenService.IssueAccessToken(user);
        var refreshToken = tokenService.GenerateRefreshToken();
        db.RefreshTokens.Add(new RefreshToken
        {
            UserId = user.Id,
            TokenHash = secureHasher.Hash(refreshToken),
            ExpiresAt = clock.UtcNow.AddDays(30),
            CreatedAt = clock.UtcNow,
            IpAddress = ipAddress,
            UserAgent = userAgent
        });
        await db.SaveChangesAsync(ct);

        return new TokenResponse(
            accessToken.AccessToken,
            refreshToken,
            accessToken.ExpiresIn,
            new UserSummaryDto(user.Id, user.FullName, user.PhoneNumber, user.Email, user.Role));
    }

    private async Task CreateOtpAsync(string phone, CancellationToken ct)
    {
        var lastOtp = await db.OtpCodes
            .Where(x => x.PhoneNumber == phone)
            .OrderByDescending(x => x.SentAt)
            .FirstOrDefaultAsync(ct);

        if (lastOtp is not null && lastOtp.SentAt.AddSeconds(45) > clock.UtcNow)
        {
            throw new AppException("Yeni kod göndermek için 45 saniye beklemelisiniz.", 429);
        }

        var dailyOtpCount = await db.OtpCodes
            .CountAsync(x => x.PhoneNumber == phone && x.SentAt >= clock.UtcNow.AddDays(-1), ct);

        if (dailyOtpCount >= 10)
        {
            throw new AppException("Günlük OTP gönderim limitine ulaştınız.", 429);
        }

        var code = RandomNumberGenerator.GetInt32(100000, 999999).ToString();
        db.OtpCodes.Add(new OtpCode
        {
            PhoneNumber = phone,
            CodeHash = secureHasher.Hash(code),
            ExpiresAt = clock.UtcNow.AddMinutes(3),
            SentAt = clock.UtcNow
        });
        await smsSender.SendOtpAsync(phone, code, ct);
    }

    private static string NormalizePhone(string phone) => phone.Trim().Replace(" ", string.Empty);

    private static void ValidateRequired(string? value, string field)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            throw new AppException("Zorunlu alan eksik.", 422, [new ApiError(field, "Bu alan zorunludur.")]);
        }
    }
}
