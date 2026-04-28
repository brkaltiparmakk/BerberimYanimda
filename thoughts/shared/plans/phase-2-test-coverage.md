# Phase 2: Test Coverage Plan — AuthService, PaymentService, CouponService

> Architect: Solution Architect | Date: 2026-04-27
> Input: Code Analyzer Report — No tests for security-critical services

## Target Services

### AuthService (320 lines, 7 public methods)
Dependencies: IAppDbContext, IPasswordService, ISecureHasher, ITokenService, ISmsSender, IDateTimeProvider, IEncryptionService, ITotpService

Test cases:
1. RegisterAsync — success (valid input)
2. RegisterAsync — password too short (<8 chars) → 422
3. RegisterAsync — password without upper/lower/digit → 422
4. RegisterAsync — duplicate phone → 409
5. RegisterAsync — empty phone/name → 422 validation
6. LoginAsync — success returns tokens + user
7. LoginAsync — wrong password → 401
8. LoginAsync — unverified phone → 403
9. LoginAsync — non-existent user → 401
10. VerifyOtpAsync — success verifies phone
11. VerifyOtpAsync — wrong code → 422
12. VerifyOtpAsync — expired OTP → 422
13. VerifyOtpAsync — too many attempts → locked → 422
14. RefreshTokenAsync — success rotates tokens
15. RefreshTokenAsync — revoked token → 401
16. LogoutAsync — success revokes all refresh tokens

### PaymentService
Test cases:
1. PayAtBarberAsync — success transitions to Confirmed
2. PayAtBarberAsync — already paid → 422
3. PayAtBarberAsync — invalid appointment → 404
4. CreateOnlinePaymentSessionAsync — success
5. HandleWebhookAsync — paid webhook → transitions payment + appointment

### CouponService
Test cases:
1. ValidateAsync — valid coupon returns discount
2. ValidateAsync — expired coupon → 422
3. ValidateAsync — usage limit reached → 422
4. ValidateAsync — minimum order not met → 422
5. ValidateAsync — invalid code → 404

## Test Doubles Needed (add to TestDoubles.cs)
- NoOpSmsSender : ISmsSender
- NoOpTokenService : ITokenService
- StubTokenService : ITokenService (returns predictable tokens)
- FixedPasswordService : IPasswordService (returns known hash)
- StubSecureHasher : ISecureHasher (returns known hash)
- FixedEncryptionService : IEncryptionService
- FixedTotpService : ITotpService

## File Structure
```
tests/BerberYanimda.Tests/
├── AuthServiceTests.cs    (NEW)
├── PaymentServiceTests.cs  (NEW)
├── CouponServiceTests.cs   (NEW)
├── TestDoubles.cs          (EXTEND)
└── BookingTests.cs         (reference pattern)
```

## Pattern Reference
Follow BookingTests.cs pattern:
- `CreateDb()` → InMemory database per test
- `SeedMinimalAsync()` → seed users, shops, services
- Service instantiation with test doubles
- Assert patterns: `Assert.ThrowsAsync<AppException>`
