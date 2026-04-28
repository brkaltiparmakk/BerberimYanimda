import 'package:berber_yanimda/src/core/theme/app_theme.dart';
import 'package:berber_yanimda/src/data/models.dart';
import 'package:berber_yanimda/src/features/auth/splash_screen.dart';
import 'package:berber_yanimda/src/features/auth/onboarding_screen.dart';
import 'package:berber_yanimda/src/features/auth/login_screen.dart';
import 'package:berber_yanimda/src/features/auth/register_screen.dart';
import 'package:berber_yanimda/src/features/auth/otp_screen.dart';
import 'package:berber_yanimda/src/features/barber/barber_dashboard_screen.dart';
import 'package:berber_yanimda/src/features/barber/barber_appointments_screen.dart';
import 'package:berber_yanimda/src/features/barber/barber_working_hours_screen.dart';
import 'package:berber_yanimda/src/features/barber/barber_services_screen.dart';
import 'package:berber_yanimda/src/features/barber/barber_staff_screen.dart';
import 'package:berber_yanimda/src/features/appointments/appointments_screen.dart';
import 'package:berber_yanimda/src/features/appointments/review_screen.dart';
import 'package:berber_yanimda/src/features/booking/appointment_success_screen.dart';
import 'package:berber_yanimda/src/features/booking/appointment_summary_screen.dart';
import 'package:berber_yanimda/src/features/booking/date_time_selection_screen.dart';
import 'package:berber_yanimda/src/features/booking/payment_screen.dart';
import 'package:berber_yanimda/src/features/booking/service_selection_screen.dart';
import 'package:berber_yanimda/src/features/booking/staff_selection_screen.dart';
import 'package:berber_yanimda/src/features/home/home_screen.dart';
import 'package:berber_yanimda/src/features/barber/barber_list_screen.dart';
import 'package:berber_yanimda/src/features/barber/barber_detail_screen.dart';
import 'package:berber_yanimda/src/features/favorites/favorites_screen.dart';
import 'package:berber_yanimda/src/features/notifications/notifications_screen.dart';
import 'package:berber_yanimda/src/features/profile/profile_screen.dart';
import 'package:berber_yanimda/src/features/barber/map_screen.dart';
import 'package:berber_yanimda/src/features/appointments/appointment_detail_screen.dart';
import 'package:berber_yanimda/src/features/profile/settings_screen.dart';
import 'package:berber_yanimda/src/features/profile/support_screen.dart';
import 'package:berber_yanimda/src/features/profile/edit_profile_screen.dart';
import 'package:berber_yanimda/src/state/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:berber_yanimda/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class BerberYanimdaApp extends ConsumerStatefulWidget {
  const BerberYanimdaApp({super.key});

  @override
  ConsumerState<BerberYanimdaApp> createState() => _BerberYanimdaAppState();
}

class _BerberYanimdaAppState extends ConsumerState<BerberYanimdaApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      initialLocation: '/splash',
      redirect: (context, state) {
        final auth = ref.read(authProvider);
        final path = state.uri.path;
        if (!auth.isInitialized && path != '/splash') {
          return '/splash';
        }
        if (auth.isInitialized &&
            !auth.isLoggedIn &&
            _isProtected(path)) {
          return '/login';
        }
        if (auth.isInitialized && auth.isLoggedIn && _isAuthPath(path)) {
          return auth.isBarber ? '/barber/dashboard' : '/home';
        }
        if (auth.isLoggedIn &&
            !auth.isBarber &&
            path.startsWith('/barber')) {
          return '/home';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/otp',
          builder: (context, state) {
            final extra = state.extra;
            if (extra is Map<String, String>) {
              return OtpScreen(
                phoneNumber: extra['phone'] ?? '+905551112233',
                password: extra['password'],
              );
            }
            return OtpScreen(phoneNumber: extra as String? ?? '+905551112233');
          },
        ),
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/barbers',
          builder: (context, state) => const BarberListScreen(),
        ),
        GoRoute(
          path: '/barber/:id',
          builder: (context, state) =>
              BarberDetailScreen(barberId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/booking/services',
          builder: (context, state) => const ServiceSelectionScreen(),
        ),
        GoRoute(
          path: '/booking/staff',
          builder: (context, state) => const StaffSelectionScreen(),
        ),
        GoRoute(
          path: '/booking/time',
          builder: (context, state) => const DateTimeSelectionScreen(),
        ),
        GoRoute(
          path: '/booking/summary',
          builder: (context, state) => const AppointmentSummaryScreen(),
        ),
        GoRoute(
          path: '/payment',
          builder: (context, state) => const PaymentScreen(),
        ),
        GoRoute(
          path: '/success',
          builder: (context, state) => const AppointmentSuccessScreen(),
        ),
        GoRoute(
          path: '/appointments',
          builder: (context, state) => const AppointmentsScreen(),
        ),
        GoRoute(
          path: '/review',
          builder: (context, state) {
            final appointment = state.extra as Appointment?;
            if (appointment == null) {
              return const Scaffold(
                body: Center(child: Text('Yorum yapılacak randevu bulunamadı')),
              );
            }
            return ReviewScreen(appointment: appointment);
          },
        ),
        GoRoute(
          path: '/favorites',
          builder: (context, state) => const FavoritesScreen(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/profile/edit',
          builder: (context, state) => const EditProfileScreen(),
        ),
        GoRoute(path: '/map', builder: (context, state) => const MapScreen()),
        GoRoute(
          path: '/appointment/:id',
          builder: (context, state) {
            final appointment = state.extra as Appointment?;
            if (appointment == null) {
              return const Scaffold(
                body: Center(child: Text('Randevu bulunamadı')),
              );
            }
            return AppointmentDetailScreen(appointment: appointment);
          },
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/support',
          builder: (context, state) => const SupportScreen(),
        ),
        GoRoute(
          path: '/barber/dashboard',
          builder: (context, state) => const BarberDashboardScreen(),
        ),
        GoRoute(
          path: '/barber/appointments',
          builder: (context, state) => const BarberAppointmentsScreen(),
        ),
        GoRoute(
          path: '/barber/working-hours',
          builder: (context, state) => const BarberWorkingHoursScreen(),
        ),
        GoRoute(
          path: '/barber/services',
          builder: (context, state) => const BarberServicesScreen(),
        ),
        GoRoute(
          path: '/barber/staff',
          builder: (context, state) => const BarberStaffScreen(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Berber Yanimda',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      darkTheme: AppTheme.dark(),
      theme: AppTheme.light(),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: _router,
    );
  }
}

bool _isProtected(String path) {
  return path.startsWith('/booking') ||
      path == '/payment' ||
      path == '/success' ||
      path == '/appointments' ||
      path.startsWith('/appointment/') ||
      path == '/review' ||
      path == '/favorites' ||
      path == '/notifications' ||
      path == '/profile' ||
      path == '/profile/edit' ||
      path == '/map' ||
      path == '/settings' ||
      path == '/support' ||
      path.startsWith('/barber/') ||
      path == '/barbers';
}

bool _isAuthPath(String path) {
  return path == '/onboarding' ||
      path == '/login' ||
      path == '/register' ||
      path == '/otp';
}
