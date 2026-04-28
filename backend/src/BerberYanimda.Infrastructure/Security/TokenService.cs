using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using BerberYanimda.Application.Interfaces;
using BerberYanimda.Domain;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;

namespace BerberYanimda.Infrastructure.Security;

public sealed class TokenService(IConfiguration configuration) : ITokenService
{
    private const string DevFallbackSecret = "DEV_ONLY_SECRET_REPLACE_FOR_PRODUCTION_123456789";

    public TokenIssueResult IssueAccessToken(User user)
    {
        var issuer = configuration["Jwt:Issuer"] ?? "BerberYanimda";
        var audience = configuration["Jwt:Audience"] ?? "BerberYanimdaMobile";
        var secret = configuration["Jwt:Secret"];
        if (string.IsNullOrWhiteSpace(secret))
        {
            secret = DevFallbackSecret;
        }

        var minutes = int.TryParse(configuration["Jwt:AccessTokenMinutes"], out var parsed) ? parsed : 60;
        var expires = DateTime.UtcNow.AddMinutes(minutes);

        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
            new(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new(ClaimTypes.Name, user.FullName),
            new(ClaimTypes.MobilePhone, user.PhoneNumber),
            new(ClaimTypes.Role, user.Role.ToString())
        };

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secret));
        var token = new JwtSecurityToken(
            issuer,
            audience,
            claims,
            expires: expires,
            signingCredentials: new SigningCredentials(key, SecurityAlgorithms.HmacSha256));

        return new TokenIssueResult(new JwtSecurityTokenHandler().WriteToken(token), minutes * 60);
    }

    public string GenerateRefreshToken()
    {
        var bytes = RandomNumberGenerator.GetBytes(64);
        return Convert.ToBase64String(bytes);
    }

    public string IssueMfaTempToken(User user)
    {
        var issuer = configuration["Jwt:Issuer"] ?? "BerberYanimda";
        var audience = configuration["Jwt:Audience"] ?? "BerberYanimdaMobile";
        var secret = configuration["Jwt:Secret"];
        if (string.IsNullOrWhiteSpace(secret))
        {
            secret = DevFallbackSecret;
        }

        var expires = DateTime.UtcNow.AddMinutes(5);

        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
            new(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new(ClaimTypes.Role, user.Role.ToString()),
            new("type", "mfa_temp")
        };

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secret));
        var token = new JwtSecurityToken(
            issuer,
            audience,
            claims,
            expires: expires,
            signingCredentials: new SigningCredentials(key, SecurityAlgorithms.HmacSha256));

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    public ClaimsPrincipal ValidateMfaTempToken(string token)
    {
        var issuer = configuration["Jwt:Issuer"] ?? "BerberYanimda";
        var audience = configuration["Jwt:Audience"] ?? "BerberYanimdaMobile";
        var secret = configuration["Jwt:Secret"];
        if (string.IsNullOrWhiteSpace(secret))
        {
            secret = DevFallbackSecret;
        }

        var tokenHandler = new JwtSecurityTokenHandler();
        var validationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = issuer,
            ValidAudience = audience,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secret)),
            ClockSkew = TimeSpan.Zero
        };

        var principal = tokenHandler.ValidateToken(token, validationParameters, out _);
        var typeClaim = principal.FindFirst("type");
        if (typeClaim?.Value != "mfa_temp")
        {
            throw new SecurityTokenException("Geçersiz token tipi.");
        }

        return principal;
    }
}
