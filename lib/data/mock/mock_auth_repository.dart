import 'dart:async';

import '../../models/app_user.dart';
import '../auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  MockAuthRepository({this.delay = const Duration(milliseconds: 800)});

  final Duration delay;
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _user;

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield _user;
    yield* _controller.stream;
  }

  @override
  Future<void> init() async {}

  @override
  Future<AppUser?> signInWithGoogle() async {
    await Future<void>.delayed(delay);
    final user = const AppUser(
      id: 'mock-user',
      name: 'Demo User',
      email: 'demo@example.com',
    );
    _user = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }
}
