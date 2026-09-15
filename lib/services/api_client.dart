import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ApiClient {
  final http.Client? _httpClient;
  final AuthService _authService;

  static final ApiClient _defaultInstance = ApiClient._internal();
  static Completer<String?>? _refreshCompleter;

  ApiClient({this._httpClient, AuthService? authService})
      : _authService = authService ?? AuthService();

  ApiClient._internal()
      : _httpClient = null,
        _authService = AuthService();

  static ApiClient get instance => _defaultInstance;

  /// Check if the JWT token is expired or within [bufferSeconds] of expiring.
  bool _isTokenExpiringSoon(String token, {int bufferSeconds = 30}) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;
      final normalized = base64Url.normalize(parts[1]);
      final payloadString = utf8.decode(base64Url.decode(normalized));
      final Map<String, dynamic> payload = jsonDecode(payloadString);
      final exp = payload['exp'];
      if (exp is int) {
        final expiryTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
        return expiryTime.isBefore(DateTime.now().add(Duration(seconds: bufferSeconds)));
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Thread-safe deduplicated token refresh using a shared Completer.
  Future<String?> _refreshTokenWithLock() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    final completer = Completer<String?>();
    _refreshCompleter = completer;

    try {
      final res = await _authService.refreshToken();
      if (res['success'] == true && res['token'] != null) {
        final newToken = res['token'] as String;
        completer.complete(newToken);
        return newToken;
      } else {
        AuthService.broadcastSessionExpired();
        completer.complete(null);
        return null;
      }
    } catch (e) {
      AuthService.broadcastSessionExpired();
      completer.complete(null);
      return null;
    } finally {
      _refreshCompleter = null;
    }
  }

  /// Core executor with proactive expiry check and 401 automatic retry.
  Future<http.Response> _sendWithAuth(
    Future<http.Response> Function(String token) sendRequest, {
    String? explicitToken,
  }) async {
    String? token = explicitToken ?? await _authService.getToken();

    // 1. Proactive Refresh: check if token exists, is a JWT, and is expiring in < 30 seconds
    if (token != null && token.isNotEmpty && _isTokenExpiringSoon(token)) {
      final refreshed = await _refreshTokenWithLock();
      if (refreshed != null && refreshed.isNotEmpty) {
        token = refreshed;
      }
    }

    // 2. Perform Request
    var response = await sendRequest(token ?? '');

    // 3. Reactive Refresh: If 401 Unauthorized, refresh token and retry request once
    if (response.statusCode == 401) {
      final refreshed = await _refreshTokenWithLock();
      if (refreshed != null && refreshed.isNotEmpty) {
        response = await sendRequest(refreshed);
      }
    }

    return response;
  }

  Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
    String? token,
  }) {
    return _sendWithAuth((currentToken) {
      final effectiveHeaders = {
        'Content-Type': 'application/json',
        if (currentToken.isNotEmpty) 'Authorization': 'Bearer $currentToken',
        ...?headers,
      };
      final client = _httpClient;
      if (client != null) {
        return client.get(url, headers: effectiveHeaders);
      }
      return http.get(url, headers: effectiveHeaders);
    }, explicitToken: token);
  }

  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    String? token,
  }) {
    return _sendWithAuth((currentToken) {
      final effectiveHeaders = {
        'Content-Type': 'application/json',
        if (currentToken.isNotEmpty) 'Authorization': 'Bearer $currentToken',
        ...?headers,
      };
      final client = _httpClient;
      if (client != null) {
        return client.post(url, headers: effectiveHeaders, body: body);
      }
      return http.post(url, headers: effectiveHeaders, body: body);
    }, explicitToken: token);
  }

  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    String? token,
  }) {
    return _sendWithAuth((currentToken) {
      final effectiveHeaders = {
        'Content-Type': 'application/json',
        if (currentToken.isNotEmpty) 'Authorization': 'Bearer $currentToken',
        ...?headers,
      };
      final client = _httpClient;
      if (client != null) {
        return client.put(url, headers: effectiveHeaders, body: body);
      }
      return http.put(url, headers: effectiveHeaders, body: body);
    }, explicitToken: token);
  }

  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    String? token,
  }) {
    return _sendWithAuth((currentToken) {
      final effectiveHeaders = {
        'Content-Type': 'application/json',
        if (currentToken.isNotEmpty) 'Authorization': 'Bearer $currentToken',
        ...?headers,
      };
      final client = _httpClient;
      if (client != null) {
        return client.delete(url, headers: effectiveHeaders, body: body);
      }
      return http.delete(url, headers: effectiveHeaders, body: body);
    }, explicitToken: token);
  }
}
