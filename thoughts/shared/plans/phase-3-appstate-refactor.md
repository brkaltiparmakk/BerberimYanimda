# Phase 3: AppState Refactor Plan

> Architect: Solution Architect | Date: 2026-04-27
> Input: Code Analyzer Report — AppState God Object (899 lines)
> Pattern: Riverpod 3.x Notifier/AsyncNotifierProvider

## Target Providers

### 1. AuthProvider (en kritik, en bağımsız)
**File**: `lib/src/state/providers/auth_provider.dart`
**State**: UserProfile?, isLoggedIn, isInitialized, isBusy, errorMessage
**Methods**: initialize, login, register, verifyOtp, logout, _registerFcmToken, _unregisterFcmToken
**Dependencies**: ApiClient, AuthRepository, ProfileRepository, FcmTokenRepository, NotificationService

### 2. CatalogProvider
**File**: `lib/src/state/providers/catalog_provider.dart`
**State**: List<Barber>, Barber? selectedBarber
**Methods**: loadBarbers, loadBarberDetail, selectBarber, _upsertBarber, _findBarber

### 3. BookingProvider (customer booking flow)
**File**: `lib/src/state/providers/booking_provider.dart`
**State**: selectedServiceIds, selectedStaff, selectedDate, slots, selectedSlot, lastCreatedAppointment, paymentSessionId, isOnlinePayment
**Methods**: toggleService, selectStaff, selectDate, loadSlots, selectSlot, createPayAtBarberAppointment, createOnlinePaymentSession, sandboxCompletePayment, setPaymentMethod

### 4. AppointmentProvider
**File**: `lib/src/state/providers/appointment_provider.dart`
**State**: List<Appointment>, AppointmentFilter
**Methods**: loadAppointments, cancelAppointment, setFilter, filteredAppointments

### 5. FavoritesProvider
**File**: `lib/src/state/providers/favorites_provider.dart`
**State**: List<Barber> favorites
**Methods**: loadFavorites, toggleFavorite

### 6. NotificationProvider
**File**: `lib/src/state/providers/notification_provider.dart`
**State**: List<AppNotification>, unreadCount
**Methods**: loadNotifications, markRead, markAllRead

### 7. ProfileProvider
**File**: `lib/src/state/providers/profile_provider.dart`
**State**: (uses AuthProvider state)
**Methods**: updateProfile, uploadProfileImage, changePassword, deleteAccount, exportUserData

### 8. BarberOwnerProvider
**File**: `lib/src/state/providers/barber_owner_provider.dart`
**State**: shopAppointments, workingHours, shopServices, shopStaff, filters
**Methods**: loadShopAppointments, confirm/complete/reject, loadWorkingHours, updateWorkingHours, CRUD services, CRUD staff, assignStaffServices

### 9. CouponProvider
**File**: `lib/src/state/providers/coupon_provider.dart`
**State**: CouponValidationResult?, appliedCouponCode
**Methods**: validateCoupon, clearCoupon

### 10. ReviewProvider
**File**: `lib/src/state/providers/review_provider.dart`
**State**: List<Review>, ReviewSummary?
**Methods**: createReview, loadReviews, loadReviewSummary

### 11. SupportProvider
**File**: `lib/src/state/providers/support_provider.dart`
**Methods**: createSupportTicket

### Utility: launchPhoneCall, launchMapDirections, shareBarberInfo → app_utils.dart

## Implementation Phases

### Phase 3A — Create provider files (bugün)
1. Create `lib/src/state/providers/` directory
2. Create all 11 provider files with full implementations
3. Create `app_state_refactored.dart` that composes all providers via Riverpod
4. Keep old `app_state.dart` untouched (backward compatible)
5. Verify: `flutter analyze`

### Phase 3B — Migrate screens (1-2 gün)
Screen-by-screen migration from `appStateProvider` to new providers

### Phase 3C — Remove old AppState (1 gün)
Delete old `app_state.dart`, clean up imports

### Phase 3D — Verification (2-3 saat)
Flutter analyze, flutter test, manual smoke test
