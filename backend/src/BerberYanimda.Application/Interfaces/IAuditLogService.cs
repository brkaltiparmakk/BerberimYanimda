namespace BerberYanimda.Application.Interfaces;

public interface IAuditLogService
{
    Task LogAsync(
        Guid? userId,
        string action,
        string? entityName = null,
        string? entityId = null,
        string? oldValue = null,
        string? newValue = null,
        string? ipAddress = null,
        string? userAgent = null,
        CancellationToken ct = default);
}

public interface IEncryptionService
{
    string Encrypt(string plainText);
    string Decrypt(string cipherText);
}

public interface ITotpService
{
    string GenerateSecret();
    string GenerateQrCodeUri(string label, string secret, string issuer);
    bool Verify(string secret, string code);
}
