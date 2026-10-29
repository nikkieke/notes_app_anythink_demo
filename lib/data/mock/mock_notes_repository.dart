import '../../models/note.dart';
import '../notes_repository.dart';

class MockNotesRepository implements NotesRepository {
  MockNotesRepository({
    this.latency = const Duration(milliseconds: 400),
    List<Note>? seed,
  }) : _notes = {for (final n in seed ?? _defaultSeed()) n.id: n};

  final Duration latency;
  final Map<String, Note> _notes;
  int _nextId = 0;

  @override
  Future<List<Note>> fetchNotes() async {
    await Future<void>.delayed(latency);
    return _notes.values.toList();
  }

  @override
  Future<Note?> fetchNote(String id) async {
    await Future<void>.delayed(latency);
    return _notes[id];
  }

  @override
  Future<Note> createNote({required String title, required String body}) async {
    await Future<void>.delayed(latency);
    final now = DateTime.now();
    final note = Note(
      id: 'local-${_nextId++}-${now.microsecondsSinceEpoch}',
      title: title,
      body: body,
      createdAt: now,
      updatedAt: now,
    );
    _notes[note.id] = note;
    return note;
  }

  @override
  Future<Note> updateNote(Note note) async {
    await Future<void>.delayed(latency);
    final updated = note.copyWith(updatedAt: DateTime.now());
    _notes[note.id] = updated;
    return updated;
  }

  @override
  Future<void> deleteNote(String id) async {
    await Future<void>.delayed(latency);
    _notes.remove(id);
  }

  static List<Note> _defaultSeed() {
    final now = DateTime.now();
    Note note(String id, String title, String body, Duration ago) => Note(
          id: id,
          title: title,
          body: body,
          createdAt: now.subtract(ago),
          updatedAt: now.subtract(ago),
        );
    return [
      note('seed-1', 'Welcome to Notes',
          'A simple place for your thoughts. Tap a note to edit it, or tap + to start a new one.',
          const Duration(minutes: 5)),
      note('seed-2', 'Groceries', 'Eggs\nBread\nCoffee beans\nSpinach',
          const Duration(hours: 3)),
      note('seed-3', 'Ideas', 'Weekend hike, try the new ramen place, call Mum.',
          const Duration(days: 4)),
    ];
  }
}
