import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

abstract class TokenStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> clear();
}

class SecureTokenStore implements TokenStore {
  SecureTokenStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> clear() => _storage.deleteAll();
}

class MemoryTokenStore implements TokenStore {
  final Map<String, String> _values = {};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> clear() async {
    _values.clear();
  }
}

class ApiClient {
  static const _defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5000/api/v1',
  );

  ApiClient({
    http.Client? httpClient,
    TokenStore? tokenStore,
    String? baseUrl,
  }) : _http = httpClient ?? http.Client(),
       _tokenStore = tokenStore ?? SecureTokenStore(),
       baseUrl = _normalizeBaseUrl(baseUrl ?? _defaultBaseUrl);

  final http.Client _http;
  final TokenStore _tokenStore;
  final String baseUrl;
  Completer<bool>? _refreshCompleter;

  static String _normalizeBaseUrl(String value) {
    final normalized = value.trim().replaceFirst(RegExp(r'/+$'), '');
    if (kReleaseMode && !normalized.startsWith('https://')) {
      throw StateError('Release API_BASE_URL must use HTTPS.');
    }

    return normalized;
  }

  Future<bool> hasAccessToken() async =>
      (await _tokenStore.read('accessToken'))?.isNotEmpty == true;

  Future<String?> getRefreshToken() async =>
      await _tokenStore.read('refreshToken');

  Future<Map<String, dynamic>> get(String path) => _send('GET', path);

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) =>
      _send('POST', path, body: body);

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) =>
      _send('PUT', path, body: body);

  Future<Map<String, dynamic>> delete(String path, {Map<String, dynamic>? body}) =>
      _send('DELETE', path, body: body);

  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) =>
      _send('PATCH', path, body: body);

  Future<Map<String, dynamic>> postMultipartFile(
    String path, {
    required String fieldName,
    required String filePath,
    bool retrying = false,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _headers();
    headers.remove('Content-Type');
    final request = http.MultipartRequest('POST', uri)..headers.addAll(headers);
    request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));
    final response = await http.Response.fromStream(await _http.send(request));

    if (response.statusCode == 401 && !retrying) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        return postMultipartFile(
          path,
          fieldName: fieldName,
          filePath: filePath,
          retrying: true,
        );
      }
      throw ApiException('Oturum süreniz doldu. Lütfen tekrar giriş yapın.', statusCode: 401);
    }

    return _decode(response);
  }

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _tokenStore.write('accessToken', accessToken);
    await _tokenStore.write('refreshToken', refreshToken);
  }

  Future<void> clearTokens() => _tokenStore.clear();

  static const _requestTimeout = Duration(seconds: 15);

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool retrying = false,
    int retryCount = 0,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _headers();

    http.Response response;
    try {
      response = await switch (method) {
        'GET' => _http.get(uri, headers: headers),
        'POST' => _http.post(
          uri,
          headers: headers,
          body: jsonEncode(body ?? {}),
        ),
        'PUT' => _http.put(
          uri,
          headers: headers,
          body: jsonEncode(body ?? {}),
        ),
        'PATCH' => _http.patch(
          uri,
          headers: headers,
          body: jsonEncode(body ?? {}),
        ),
        'DELETE' => _http.delete(
          uri,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        ),
        _ => throw ApiException('Invalid HTTP method.', statusCode: 0),
      }.timeout(_requestTimeout);
    } on TimeoutException {
      if (method == 'GET' && retryCount < 2) {
        final delay = Duration(seconds: [1, 2][retryCount]);
        if (kDebugMode) {
          debugPrint('API retry ${retryCount + 1}/2 after timeout: $method $path');
        }
        await Future.delayed(delay);
        return _send(method, path, body: body, retrying: retrying, retryCount: retryCount + 1);
      }
      rethrow;
    }

    if (response.statusCode == 401 && !retrying) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        return _send(method, path, body: body, retrying: true, retryCount: retryCount);
      }
      throw ApiException('Oturum süreniz doldu. Lütfen tekrar giriş yapın.', statusCode: 401);
    }

    if ((response.statusCode >= 500 || response.statusCode == 429) && method == 'GET' && retryCount < 2) {
      final retryAfter = response.statusCode == 429
          ? int.tryParse(response.headers['retry-after'] ?? '')
          : null;
      final delay = Duration(seconds: retryAfter ?? [1, 2][retryCount]);
      if (kDebugMode) {
        debugPrint('API retry ${retryCount + 1}/2 after HTTP ${response.statusCode}: $method $path');
      }
      await Future.delayed(delay);
      return _send(method, path, body: body, retrying: retrying, retryCount: retryCount + 1);
    }

    return _decode(response);
  }

  Future<bool> _refreshToken() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<bool>();
    try {
      final refreshToken = await _tokenStore.read('refreshToken');
      if (refreshToken == null || refreshToken.isEmpty) {
        _refreshCompleter!.complete(false);
        return false;
      }

      final response = await _http.post(
        Uri.parse('$baseUrl/auth/refresh-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode >= 400) {
        await clearTokens();
        _refreshCompleter!.complete(false);
        return false;
      }

      final json = _decode(response);
      final data = json['data'] as Map<String, dynamic>;
      await saveTokens(
        data['accessToken'] as String,
        data['refreshToken'] as String,
      );
      _refreshCompleter!.complete(true);
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Token refresh failed: $e');
      }
      await clearTokens();
      _refreshCompleter!.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<Map<String, String>> _headers() async {
    final token = await _tokenStore.read('accessToken');
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _decode(http.Response response) {
    final body = utf8.decode(response.bodyBytes);

    // Empty body handling
    if (body.trim().isEmpty) {
      if (response.statusCode >= 400) {
        throw ApiException(
          'Sunucu hatası (${response.statusCode}).',
          statusCode: response.statusCode,
        );
      }
      throw ApiException(
        'Sunucu boş yanıt döndürdü.',
        statusCode: response.statusCode,
      );
    }

    Map<String, dynamic> json;
    try {
      json = jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      if (kDebugMode) {
        debugPrint('API decode error: status=${response.statusCode}, body=$body');
      }
      throw ApiException(
        'Sunucu yanıtı okunamadı (${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode >= 400 || json['success'] == false) {
      throw ApiException(
        (json['message'] as String?) ?? 'İstek başarısız oldu.',
        statusCode: response.statusCode,
      );
    }

    return json;
  }
}

class ApiException implements Exception {
  ApiException(this.message, {required this.statusCode});

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}
