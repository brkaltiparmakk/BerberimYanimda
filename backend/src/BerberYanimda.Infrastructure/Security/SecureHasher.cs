using System.Security.Cryptography;
using System.Text;
using BerberYanimda.Application.Interfaces;
using Microsoft.Extensions.Configuration;

namespace BerberYanimda.Infrastructure.Security;

public sealed class SecureHasher : ISecureHasher
{
    private const string DevFallbackKey = "DEV_ONLY_HMAC_KEY_REPLACE_FOR_PRODUCTION_123456789";
    private readonly byte[] _key;

    public SecureHasher(IConfiguration configuration)
    {
        var key = configuration["Hmac:Key"];
        if (string.IsNullOrWhiteSpace(key))
        {
            key = DevFallbackKey;
        }

        _key = Encoding.UTF8.GetBytes(key);
    }

    public string Hash(string value)
    {
        using var hmac = new HMACSHA256(_key);
        return Convert.ToBase64String(hmac.ComputeHash(Encoding.UTF8.GetBytes(value)));
    }

    public bool Verify(string value, string hash)
    {
        var left = Convert.FromBase64String(Hash(value));
        var right = Convert.FromBase64String(hash);
        return left.Length == right.Length && CryptographicOperations.FixedTimeEquals(left, right);
    }
}
