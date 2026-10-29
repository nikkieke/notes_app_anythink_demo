import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../core/env.dart';
import 'anythink_exception.dart';
import 'anythink_session.dart';
import 'session_store.dart';

/// Thin REST client: JSON in/out, bearer auth, one refresh-and-retry on 401.
class AnythinkClient {
  AnythinkClient({
    http.Client? httpClient,
    SessionStore? store,
    this.baseUrl = Env.anythinkBaseUrl,
  })  : _http = httpClient ?? http.Client(),
        _store = store ?? SecureSessionStore();

  final String baseUrl;
  final http.Client _http;
  final SessionStore _store;
  final _sessionChanges = StreamController<AnythinkSession?>.broadcast();
  Future<bool>? _refreshing;

  AnythinkSession? _session;
  AnythinkSession? get session => _session;

  /// Emits on sign-in, sign-out, token refresh and forced sign-out.
  Stream<AnythinkSession?> get sessionChanges => _sessionChanges.stream;

  Future<void> restoreSession() async => _session = await _store.read();

  Future<void> setSession(AnythinkSession? session) async {
    _session = session;
    session == null ? await _store.clear() : await _store.write(session);
    _sessionChanges.add(session);
  }

  /// Sends a request and returns the decoded JSON body (null when empty).
  Future<Object?> send(
    String method,
    String path, {
    Object? body,
    bool authenticated = true,
  }) async {
    final token = authenticated ? _session?.accessToken : null;
    var response = await _send(method, path, body, token);

    if (response.statusCode == 401 && token != null) {
      // Another request may already have refreshed while this one was in flight.
      final current = _session?.accessToken;
      final refreshed =
          current != null && (current != token || await _refreshOnce());
      if (refreshed) {
        response = await _send(method, path, body, _session?.accessToken);
      }
    }

    if (response.statusCode >= 400) {
      throw AnythinkException.fromResponse(response.statusCode, response.body);
    }
    return response.body.isEmpty ? null : jsonDecode(response.body);
  }

  Future<http.Response> _send(
      String method, String path, Object? body, String? token) async {
    final request = http.Request(method, Uri.parse('$baseUrl$path'))
      ..headers['Accept'] = 'application/json';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    try {
      return await http.Response.fromStream(await _http.send(request));
    } on http.ClientException catch (e) {
      throw AnythinkException(0, 'Network error: ${e.message}');
    }
  }

  /// Concurrent 401s share a single refresh.
  Future<bool> _refreshOnce() =>
      _refreshing ??= _refresh().whenComplete(() => _refreshing = null);

  Future<bool> _refresh() async {
    final current = _session;
    final refreshToken = current?.refreshToken;
    if (current == null || refreshToken == null) {
      await setSession(null);
      return false;
    }
    try {
      final json = await send('POST', '/auth/v1/refresh',
          body: {'refresh_token': refreshToken}, authenticated: false);
      var next = AnythinkSession.fromJson(json as Map<String, dynamic>,
          previousRefreshToken: refreshToken);
      if (next.user == null && current.user != null) {
        next = next.withUser(current.user!);
      }
      await setSession(next);
      return true;
    } catch (e) {
      debugPrint('[anythink] refresh failed, signing out: $e');
      await setSession(null);
      return false;
    }
  }

  void dispose() {
    _sessionChanges.close();
    _http.close();
  }
}

final anythinkClientProvider = Provider<AnythinkClient>((ref) {
  final client = AnythinkClient();
  ref.onDispose(client.dispose);
  return client;
});

/// For debug logs: replaces any `*token*` value with `<redacted>`.
Object? redactTokens(Object? json) => switch (json) {
      Map() => {
          for (final e in json.entries)
            e.key: '${e.key}'.toLowerCase().contains('token')
                ? '<redacted>'
                : redactTokens(e.value),
        },
      List() => [for (final v in json) redactTokens(v)],
      _ => json,
    };
