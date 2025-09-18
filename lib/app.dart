import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/appointments/my_appointments_page.dart';
import 'features/auth/login_page.dart';
import 'features/auth/profile_page.dart';
import 'features/auth/register_page.dart';
import 'features/booking/confirm_page.dart';
import 'features/booking/select_datetime_page.dart';
import 'features/booking/select_service_page.dart';
import 'features/business/calendar_page.dart';
import 'features/business/campaign_page.dart';
import 'features/business/customer_history_page.dart';
import 'features/business/dashboard_page.dart';
import 'features/business/reports_page.dart';
import 'features/business/requests_page.dart';
import 'features/business/service_manage_page.dart';
import 'features/business/staff_manage_page.dart';
import 'features/business_detail/business_detail_page.dart';
import 'features/explore/explore_page.dart';
import 'features/explore/map_page.dart';
import 'features/payments/payment_page.dart';
import 'features/promotions/promotions_page.dart';
import 'features/reviews/rate_service_page.dart';
import 'widgets/atoms/primary_button.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Berberim Yanımda',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              onPressed: () => context.go('/explore'),
              label: 'Uygulamaya Başla',
            ),
          ],
        ),
      ),
    );
  }
}

class AppRouter {
  AppRouter._();

  static GoRouter createRouter() {
    return GoRouter(
      initialLocation: '/splash',
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashPage(),
        ),
        GoRoute(
          path: '/auth/login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: '/auth/register',
          builder: (context, state) => const RegisterPage(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfilePage(),
        ),
        GoRoute(
          path: '/explore',
          builder: (context, state) => const ExplorePage(),
        ),
        GoRoute(
          path: '/explore/map',
          builder: (context, state) => const MapPage(),
        ),
        GoRoute(
          path: '/business/:id',
          builder: (context, state) => BusinessDetailPage(businessId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/booking/services/:businessId',
          builder: (context, state) => SelectServicePage(businessId: state.pathParameters['businessId']!),
        ),
        GoRoute(
          path: '/booking/datetime/:businessId',
          builder: (context, state) => SelectDateTimePage(businessId: state.pathParameters['businessId']!),
        ),
        GoRoute(
          path: '/booking/confirm',
          builder: (context, state) => const ConfirmBookingPage(),
        ),
        GoRoute(
          path: '/appointments',
          builder: (context, state) => const MyAppointmentsPage(),
        ),
        GoRoute(
          path: '/rate/:appointmentId',
          builder: (context, state) => RateServicePage(appointmentId: state.pathParameters['appointmentId']!),
        ),
        GoRoute(
          path: '/promotions',
          builder: (context, state) => const PromotionsPage(),
        ),
        GoRoute(
          path: '/payments/checkout',
          builder: (context, state) => const PaymentPage(),
        ),
        GoRoute(
          path: '/business/dashboard',
          builder: (context, state) => const BusinessDashboardPage(),
        ),
        GoRoute(
          path: '/business/calendar',
          builder: (context, state) => const BusinessCalendarPage(),
        ),
        GoRoute(
          path: '/business/requests',
          builder: (context, state) => const BusinessRequestsPage(),
        ),
        GoRoute(
          path: '/business/services',
          builder: (context, state) => const ServiceManagePage(),
        ),
        GoRoute(
          path: '/business/campaigns',
          builder: (context, state) => const CampaignPage(),
        ),
        GoRoute(
          path: '/business/reports',
          builder: (context, state) => const ReportsPage(),
        ),
        GoRoute(
          path: '/business/customers/:customerId',
          builder: (context, state) => CustomerHistoryPage(customerId: state.pathParameters['customerId']!),
        ),
        GoRoute(
          path: '/business/staff',
          builder: (context, state) => const StaffManagePage(),
        ),
      ],
    );
  }
}
