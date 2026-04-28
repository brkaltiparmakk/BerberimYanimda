import 'dart:convert';

import 'package:berber_yanimda/src/app.dart';
import 'package:berber_yanimda/src/data/api_client.dart';
import 'package:berber_yanimda/src/state/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('shows splash branding', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(
            ApiClient(
              baseUrl: 'http://localhost/api/v1',
              tokenStore: MemoryTokenStore(),
              httpClient: MockClient(
                (_) async => http.Response(
                  jsonEncode({
                    'success': true,
                    'data': {
                      'items': [],
                      'page': 1,
                      'pageSize': 20,
                      'totalCount': 0,
                      'totalPages': 0,
                    },
                  }),
                  200,
                ),
              ),
            ),
          ),
        ],
        child: const BerberYanimdaApp(),
      ),
    );

    expect(find.text('BERBER'), findsOneWidget);
    expect(find.text('YANIMDA'), findsOneWidget);
  });
}
