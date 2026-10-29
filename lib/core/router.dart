import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/auth_repository.dart';
import '../features/auth/sign_in_page.dart';
import '../features/notes/note_editor_page.dart';
import '../features/notes/notes_list_page.dart';

abstract final class Routes {
  static const signIn = '/sign-in';
  static const notes = '/notes';
  static const newNote = '/notes/new';
  static String note(String id) => '/notes/$id';
}

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  final refresh = _StreamListenable(auth.authStateChanges());

  final router = GoRouter(
    initialLocation: Routes.notes,
    refreshListenable: refresh,
    redirect: (context, state) {
      final signedIn = auth.currentUser != null;
      final atSignIn = state.matchedLocation == Routes.signIn;
      if (!signedIn) return atSignIn ? null : Routes.signIn;
      if (atSignIn) return Routes.notes;
      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (_, _) => Routes.notes),
      GoRoute(
        path: Routes.signIn,
        builder: (context, state) => const SignInPage(),
      ),
      GoRoute(
        path: Routes.notes,
        builder: (context, state) => const NotesListPage(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const NoteEditorPage(),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) =>
                NoteEditorPage(noteId: state.pathParameters['id']),
          ),
        ],
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

class _StreamListenable extends ChangeNotifier {
  _StreamListenable(Stream<Object?> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<Object?> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
