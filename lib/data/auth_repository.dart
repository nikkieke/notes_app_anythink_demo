import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/env.dart';
import '../models/app_user.dart';
import 'anythink/anythink_auth_repository.dart';
import 'anythink/anythink_client.dart';
import 'mock/mock_auth_repository.dart';

abstract class AuthRepository {
  AppUser? get currentUser;

  /// Emits the current user immediately, then on every sign-in / sign-out.
  Stream<AppUser?> authStateChanges();

  /// Restores any saved session. Call once before the router first runs.
  Future<void> init();

  /// Returns null when the user cancels the Google account picker.
  Future<AppUser?> signInWithGoogle();

  Future<void> signOut();
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  switch (Env.backend) {
    case Backend.mock:
      return MockAuthRepository();
    case Backend.anythink:
      final repo = AnythinkAuthRepository(ref.watch(anythinkClientProvider));
      ref.onDispose(repo.dispose);
      return repo;
  }
});
