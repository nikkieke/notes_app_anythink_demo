import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/env.dart';
import '../../models/app_user.dart';
import '../auth_repository.dart';
import 'anythink_client.dart';
import 'anythink_exception.dart';
import 'anythink_session.dart';

class AnythinkAuthRepository implements AuthRepository {
  AnythinkAuthRepository(this._client, {GoogleSignIn? google})
      : _google = google ?? GoogleSignIn.instance {
    _sub = _client.sessionChanges.listen((session) {
      _user = session?.user;
      _controller.add(_user);
    });
  }

  final AnythinkClient _client;
  final GoogleSignIn _google;
  final _controller = StreamController<AppUser?>.broadcast();
  late final StreamSubscription<AnythinkSession?> _sub;
  Future<void>? _googleReady;
  AppUser? _user;

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield _user;
    yield* _controller.stream;
  }

  @override
  Future<void> init() async {
    await _client.restoreSession();
    _user = _client.session?.user;
  }

  @override
  Future<AppUser?> signInWithGoogle() async {
    await (_googleReady ??=
        _google.initialize(serverClientId: Env.googleServerClientId));

    final GoogleSignInAccount account;
    try {
      account = await _google.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      throw AnythinkException(0, 'Google sign-in failed: ${e.description ?? e.code.name}');
    }

    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const AnythinkException(0, 'Google did not return an ID token');
    }

    final json = await _client.send(
      'POST',
      '/auth/v1/native/google',
      body: {'identity_token': idToken, 'user_identifier': account.id},
      authenticated: false,
    );
    if (kDebugMode) {
      debugPrint('[anythink] native/google response: ${jsonEncode(redactTokens(json))}');
    }

    var session = AnythinkSession.fromJson(json as Map<String, dynamic>);
    session = session.withUser(session.user ??
        AppUser(
          id: account.id,
          name: account.displayName ?? account.email,
          email: account.email,
          photoUrl: account.photoUrl,
        ));
    await _client.setSession(session);
    return session.user;
  }

  @override
  Future<void> signOut() async {
    final refreshToken = _client.session?.refreshToken;
    if (refreshToken != null) {
      try {
        await _client.send('POST', '/auth/v1/logout',
            body: {'refresh_token': refreshToken});
      } catch (e) {
        debugPrint('[anythink] logout failed (ignored): $e');
      }
    }
    try {
      await _google.signOut();
    } catch (_) {}
    await _client.setSession(null);
  }

  void dispose() {
    _sub.cancel();
    _controller.close();
  }
}
