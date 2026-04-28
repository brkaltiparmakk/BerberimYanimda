using System.Security.Claims;
using BerberYanimda.Application.Common;
using BerberYanimda.Domain;

namespace BerberYanimda.Api.Extensions;

public static class ClaimsPrincipalExtensions
{
    public static Guid GetUserId(this ClaimsPrincipal user)
    {
        var value = user.FindFirstValue(ClaimTypes.NameIdentifier);
        return Guid.TryParse(value, out var userId)
            ? userId
            : throw new AppException("Geçersiz kullanıcı tokenı.", 401);
    }

    public static UserRole GetRole(this ClaimsPrincipal user)
    {
        var value = user.FindFirstValue(ClaimTypes.Role);
        return Enum.TryParse<UserRole>(value, out var role)
            ? role
            : throw new AppException("Geçersiz kullanıcı rolü.", 401);
    }
}
