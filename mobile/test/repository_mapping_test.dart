import 'dart:convert';

import 'package:berber_yanimda/src/data/api_client.dart';
import 'package:berber_yanimda/src/data/repositories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('catalog repository maps barber detail from api contract', () async {
    final repository = CatalogRepository(
      _client((request) async {
        expect(request.url.path, '/api/v1/barbers/shop-1');
        return _ok({
          'id': 'shop-1',
          'name': 'Modern Barber',
          'district': 'Kadikoy',
          'city': 'Istanbul',
          'address': 'Moda Cd.',
          'rating': 4.8,
          'reviewCount': 12,
          'startingPrice': 250,
          'coverImageUrl': '/cover.jpg',
          'isFavorite': true,
          'services': [
            {
              'id': 'service-1',
              'name': 'Sac',
              'durationMinutes': 30,
              'price': 250,
            },
          ],
          'staff': [
            {
              'id': 'staff-1',
              'fullName': 'Mehmet Usta',
              'expertise': 'Sac',
              'averageRating': 4.9,
              'isAvailableToday': true,
            },
          ],
        });
      }),
    );

    final barber = await repository.getBarber('shop-1');

    expect(barber.id, 'shop-1');
    expect(barber.services.single.id, 'service-1');
    expect(barber.staff.single.name, 'Mehmet Usta');
    expect(barber.isFavorite, isTrue);
  });

  test(
    'booking repository maps availability and appointment responses',
    () async {
      final repository = BookingRepository(
        _client((request) async {
          if (request.url.path.endsWith('/availability')) {
            expect(request.url.queryParameters['staffMemberId'], isNull);
            return _ok([
              {'startTime': '09:00', 'endTime': '09:30', 'isAvailable': true},
            ]);
          }

          return _ok({
            'id': 'appointment-1',
            'barberName': 'Modern Barber',
            'barberImageUrl': '',
            'appointmentDate': '2026-04-27',
            'startTime': '09:00',
            'endTime': '09:30',
            'staffName': null,
            'services': [
              {'serviceName': 'Sac'},
            ],
            'totalPrice': 250,
            'status': 'Confirmed',
          });
        }),
      );

      final slots = await repository.getAvailability(
        barberShopId: 'shop-1',
        staffMemberId: null,
        serviceIds: ['service-1'],
        date: DateTime(2026, 4, 27),
      );
      final appointment = await repository.createAppointment(
        barberShopId: 'shop-1',
        staffMemberId: null,
        date: DateTime(2026, 4, 27),
        startTime: '09:00',
        serviceIds: ['service-1'],
      );

      expect(slots.single.isAvailable, isTrue);
      expect(appointment.id, 'appointment-1');
      expect(appointment.services, ['Sac']);
    },
  );
}

ApiClient _client(Future<http.Response> Function(http.Request) handler) {
  return ApiClient(
    baseUrl: 'http://localhost/api/v1',
    tokenStore: MemoryTokenStore(),
    httpClient: MockClient(handler),
  );
}

http.Response _ok(Object data) {
  return http.Response(
    jsonEncode({'success': true, 'data': data}),
    200,
    headers: {'content-type': 'application/json'},
  );
}
