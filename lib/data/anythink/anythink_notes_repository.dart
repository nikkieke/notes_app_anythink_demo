import '../../models/note.dart';
import '../notes_repository.dart';
import 'anythink_client.dart';
import 'anythink_exception.dart';

class AnythinkNotesRepository implements NotesRepository {
  AnythinkNotesRepository(this._client);

  static const _path = '/entities/notes/items';
  static const _pageSize = 100;
  final AnythinkClient _client;

  @override
  Future<List<Note>> fetchNotes() async {
    final notes = <Note>[];
    for (var page = 1;; page++) {
      final items =
          _items(await _client.send('GET', '$_path?page=$page&limit=$_pageSize'));
      notes.addAll(items.map(Note.fromJson));
      if (items.length < _pageSize) return notes;
    }
  }

  @override
  Future<Note?> fetchNote(String id) async {
    try {
      return Note.fromJson(await _client.send('GET', '$_path/$id') as Map<String, dynamic>);
    } on AnythinkException catch (e) {
      if (e.isNotFound) return null;
      rethrow;
    }
  }

  @override
  Future<Note> createNote({required String title, required String body}) async {
    final json =
        await _client.send('POST', _path, body: {'title': title, 'body': body});
    return Note.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<Note> updateNote(Note note) async {
    final json = await _client.send('PUT', '$_path/${note.id}',
        body: {'title': note.title, 'body': note.body});
    return json is Map<String, dynamic>
        ? Note.fromJson(json)
        : note.copyWith(updatedAt: DateTime.now());
  }

  @override
  Future<void> deleteNote(String id) => _client.send('DELETE', '$_path/$id');

  /// The list is a bare array via MCP; accept a paged wrapper too.
  static List<Map<String, dynamic>> _items(Object? json) {
    final list = switch (json) {
      List() => json,
      Map() => (json['items'] ?? json['data'] ?? json['results'] ?? const []) as List,
      _ => const [],
    };
    return list.cast<Map<String, dynamic>>();
  }
}
