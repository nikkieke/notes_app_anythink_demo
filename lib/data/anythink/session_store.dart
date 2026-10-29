import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'anythink_session.dart';

abstract class SessionStore {
  Future<AnythinkSession?> read();

  Future<void> write(AnythinkSession session);

  Future<void> clear();
}

/// Encrypted with a Keystore-held key on Android; private to this app.
class SecureSessionStore implements SessionStore {
  SecureSessionStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'anythink_session';
  final FlutterSecureStorage _storage;

  @override
  Future<AnythinkSession?> read() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null) return null;
      return AnythinkSession.fromStorage(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Unreadable (e.g. Keystore reset after restore): treat as signed out.
      await clear();
      return null;
    }
  }

  @override
  Future<void> write(AnythinkSession session) =>
      _storage.write(key: _key, value: jsonEncode(session.toStorage()));

  @override
  Future<void> clear() => _storage.delete(key: _key);
}

class MemorySessionStore implements SessionStore {
  AnythinkSession? _session;

  @override
  Future<AnythinkSession?> read() async => _session;

  @override
  Future<void> write(AnythinkSession session) async => _session = session;

  @override
  Future<void> clear() async => _session = null;
}
