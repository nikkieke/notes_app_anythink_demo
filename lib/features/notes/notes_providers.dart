import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/notes_repository.dart';
import '../../models/note.dart';
import '../auth/auth_providers.dart';

final notesListProvider =
    AsyncNotifierProvider<NotesListNotifier, List<Note>>(NotesListNotifier.new);

class NotesListNotifier extends AsyncNotifier<List<Note>> {
  NotesRepository get _repo => ref.read(notesRepositoryProvider);

  @override
  Future<List<Note>> build() async {
    // Reload whenever the signed-in user changes.
    ref.watch(authStateProvider.select((s) => s.value?.id));
    final notes = await ref.watch(notesRepositoryProvider).fetchNotes();
    return _sorted(notes);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<Note> create({required String title, required String body}) async {
    final note = await _repo.createNote(title: title, body: body);
    state = AsyncData(_sorted([note, ...?state.value]));
    return note;
  }

  Future<Note> save(Note note) async {
    final updated = await _repo.updateNote(note);
    state = AsyncData(_sorted([
      for (final n in state.value ?? const <Note>[])
        if (n.id == updated.id) updated else n,
    ]));
    return updated;
  }

  Future<void> delete(String id) async {
    await _repo.deleteNote(id);
    state = AsyncData([
      for (final n in state.value ?? const <Note>[])
        if (n.id != id) n,
    ]);
  }

  static List<Note> _sorted(List<Note> notes) =>
      [...notes]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
}
