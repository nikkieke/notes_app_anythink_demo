import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/env.dart';
import '../models/note.dart';
import 'anythink/anythink_client.dart';
import 'anythink/anythink_notes_repository.dart';
import 'mock/mock_notes_repository.dart';

abstract class NotesRepository {
  Future<List<Note>> fetchNotes();

  Future<Note?> fetchNote(String id);

  Future<Note> createNote({required String title, required String body});

  Future<Note> updateNote(Note note);

  Future<void> deleteNote(String id);
}

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  return switch (Env.backend) {
    Backend.mock => MockNotesRepository(),
    Backend.anythink => AnythinkNotesRepository(ref.watch(anythinkClientProvider)),
  };
});
