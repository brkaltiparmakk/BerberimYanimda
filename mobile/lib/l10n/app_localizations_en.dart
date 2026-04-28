// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Berber Yanimda';

  @override
  String get appSubtitle => 'Appointment';

  @override
  String get welcome => 'Welcome';

  @override
  String get login => 'Log In';

  @override
  String get register => 'Sign Up';

  @override
  String get logout => 'Log Out';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get password => 'Password';

  @override
  String get verify => 'Verify';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get loading => 'Loading...';

  @override
  String get errorOccurred => 'An error occurred.';

  @override
  String get retry => 'Retry';

  @override
  String get noData => 'No data found';

  @override
  String get search => 'Search';

  @override
  String get favorites => 'Favorites';

  @override
  String get appointments => 'My Appointments';

  @override
  String get notifications => 'Notifications';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get home => 'Home';

  @override
  String get barbers => 'Barbers';

  @override
  String get booking => 'Book Appointment';

  @override
  String get serviceSelection => 'Select Services';

  @override
  String get staffSelection => 'Select Staff';

  @override
  String get dateTimeSelection => 'Date & Time';

  @override
  String get summary => 'Summary';

  @override
  String get payment => 'Payment';

  @override
  String get success => 'Success';

  @override
  String get next => 'Continue';

  @override
  String get back => 'Back';

  @override
  String get select => 'Select';

  @override
  String get selected => 'Selected';

  @override
  String get all => 'All';

  @override
  String get upcoming => 'Upcoming';

  @override
  String get past => 'Past';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get workHours => 'Working Hours';

  @override
  String get services => 'Services';

  @override
  String get staff => 'Staff';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get confirmAppointment => 'Confirm Appointment';

  @override
  String get completeAppointment => 'Complete Appointment';

  @override
  String get rejectAppointment => 'Reject Appointment';

  @override
  String get createService => 'Add Service';

  @override
  String get updateService => 'Update Service';

  @override
  String get createStaff => 'Add Staff';

  @override
  String get updateStaff => 'Update Staff';

  @override
  String get changePassword => 'Change Password';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get exportData => 'Export My Data';

  @override
  String get support => 'Support';

  @override
  String get submit => 'Submit';

  @override
  String get coupon => 'Coupon Code';

  @override
  String get apply => 'Apply';

  @override
  String get payAtBarber => 'Pay at Barber';

  @override
  String get payOnline => 'Pay Online';

  @override
  String get review => 'Write Review';

  @override
  String get rating => 'Rating';

  @override
  String get comment => 'Comment';

  @override
  String get markAllRead => 'Mark All Read';

  @override
  String get noNotifications => 'No notifications';

  @override
  String get noAppointments => 'No appointments';

  @override
  String get noFavorites => 'No favorites yet';

  @override
  String get guest => 'Guest';

  @override
  String get unverifiedPhone =>
      'Enter the verification code sent via SMS to verify your account.';

  @override
  String get loggingIn => 'Logging in...';

  @override
  String get registering => 'Creating account...';

  @override
  String get verifying => 'Verifying...';

  @override
  String get dontHaveAccount => 'Don\'t have an account? Sign Up';

  @override
  String get alreadyHaveAccount => 'Already have an account? Log In';

  @override
  String get fullName => 'Full Name';

  @override
  String get email => 'Email';

  @override
  String get phone => 'Phone';

  @override
  String get exploreNearby => 'Discover nearby barbers';

  @override
  String get nearbyBarbers => 'Nearby Barbers';

  @override
  String get viewAll => 'View All';

  @override
  String get popular => 'Popular';

  @override
  String get maleBarber => 'Men\'s Haircut';

  @override
  String get beard => 'Beard';

  @override
  String get skinCare => 'Skin Care';

  @override
  String get myFavorites => 'My Favorites';

  @override
  String get myProfile => 'My Profile';

  @override
  String get explore => 'Explore';

  @override
  String get map => 'Map';

  @override
  String get nearMe => 'Near Me';

  @override
  String get highestRated => 'Highest Rated';

  @override
  String get availableNow => 'Available Now';

  @override
  String get bestPrice => 'Best Price';

  @override
  String get currentPassword => 'Current Password';

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmNewPassword => 'Confirm New Password';

  @override
  String get passwordsDontMatch => 'Passwords don\'t match';

  @override
  String get passwordChanged => 'Password changed';

  @override
  String get deleteAccountWarning =>
      'This action cannot be undone. Your account and all data will be permanently deleted.';

  @override
  String get enterYourPassword => 'Enter your password';

  @override
  String get preparingData => 'Preparing your data...';

  @override
  String get dataDownloadFailed => 'Data could not be downloaded.';

  @override
  String get noAppointmentsInCategory =>
      'No appointments found in this category.';

  @override
  String get noBarbersFound => 'No barbers found.';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get profilePhoto => 'Profile photo';

  @override
  String helloUser(String userName) {
    return 'Hello $userName 👋';
  }
}
