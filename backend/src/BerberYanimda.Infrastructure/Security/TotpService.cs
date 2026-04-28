using BerberYanimda.Application.Interfaces;
using OtpNet;

namespace BerberYanimda.Infrastructure.Security;

public sealed class TotpService : ITotpService
{
    public string GenerateSecret()
    {
        var key = KeyGeneration.GenerateRandomKey(20);
        return Base32Encoding.ToString(key);
    }

    public string GenerateQrCodeUri(string label, string secret, string issuer)
    {
        return new OtpUri(OtpType.Totp, secret, label, issuer).ToString();
    }

    public bool Verify(string secret, string code)
    {
        var key = Base32Encoding.ToBytes(secret);
        var totp = new Totp(key);
        return totp.VerifyTotp(code, out _, VerificationWindow.RfcSpecifiedNetworkDelay);
    }
}
