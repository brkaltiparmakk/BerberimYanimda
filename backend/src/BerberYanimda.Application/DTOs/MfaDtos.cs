namespace BerberYanimda.Application.DTOs;

public sealed record LoginResult(bool MfaRequired, string? TempToken, TokenResponse? Tokens);

public sealed record MfaSetupResponse(string SecretUri, string ManualEntryKey);

public sealed record MfaVerifyRequest(string TempToken, string Code);

public sealed record MfaDisableRequest(string Password, string Code);
