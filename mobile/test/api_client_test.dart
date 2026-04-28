import 'dart:convert';

import 'package:berber_yanimda/src/data/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('attaches bearer token and decodes successful responses', () async {
    final store = MemoryTokenStore();
    await store.write('accessToken', 'access-token');
    final client = ApiClient(
      baseUrl: 'http://localhost/api/v1',
      tokenStore: store,
      httpClient: MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer access-token');
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {'id': 'user-1'},
          }),
          200,
        );
      }),
    );

    final response = await client.get('/users/me');

    expect((response['data'] as Map<String, dynamic>)['id'], 'user-1');
  });

  test('refreshes token once after unauthorized response', () async {
    final store = MemoryTokenStore();
    await store.write('accessToken', 'expired-token');
    await store.write('refreshToken', 'refresh-token');
    var usersMeCalls = 0;
    final client = ApiClient(
      baseUrl: 'http://localhost/api/v1',
      tokenStore: store,
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/auth/refresh-token')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'accessToken': 'new-token',
                'refreshToken': 'new-refresh-token',
              },
            }),
            200,
          );
        }

        usersMeCalls++;
        if (usersMeCalls == 1) {
          expect(request.headers['Authorization'], 'Bearer expired-token');
          return http.Response(
            jsonEncode({'success': false, 'message': 'Unauthorized'}),
            401,
          );
        }

        expect(request.headers['Authorization'], 'Bearer new-token');
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {'fullName': 'Test User'},
          }),
          200,
        );
      }),
    );

    final response = await client.get('/users/me');

    expect((response['data'] as Map<String, dynamic>)['fullName'], 'Test User');
    expect(await store.read('accessToken'), 'new-token');
    expect(usersMeCalls, 2);
  });

  test('throws ApiException for unsuccessful api response', () async {
    final client = ApiClient(
      baseUrl: 'http://localhost/api/v1',
      tokenStore: MemoryTokenStore(),
      httpClient: MockClient(
        (_) async => http.Response(
          jsonEncode({'success': false, 'message': 'Bad request'}),
          400,
        ),
      ),
    );

    expect(
      () => client.get('/barbers'),
      throwsA(
        isA<ApiException>()
            .having((error) => error.message, 'message', 'Bad request')
            .having((error) => error.statusCode, 'statusCode', 400),
      ),
    );
  });
}
