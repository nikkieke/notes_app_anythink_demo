import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:notes_app_anythink_demo/data/anythink/anythink_client.dart';
import 'package:notes_app_anythink_demo/data/anythink/anythink_exception.dart';
import 'package:notes_app_anythink_demo/data/anythink/anythink_notes_repository.dart';
import 'package:notes_app_anythink_demo/data/anythink/anythink_session.dart';
import 'package:notes_app_anythink_demo/data/anythink/session_store.dart';

const base = 'https://api.test/org/1';

http.Response json(Object? body, [int status = 200]) => http.Response(
    jsonEncode(body), status,
    headers: {'content-type': 'application/json'});

Map<String, dynamic> noteJson(int id, String title) => {
      'locked': false,
      'id': id,
      'created_at': '2026-10-29T19:44:30.634996Z',
      'updated_at': '2026-10-29T19:44:30.634996Z',
      'title': title,
      'body': 'body $id',
      '__name': title,
    };

Future<AnythinkClient> clientWith(
  Future<http.Response> Function(http.Request) handler, {
  AnythinkSession? session,
}) async {
  final store = MemorySessionStore();
  if (session != null) await store.write(session);
  final client =
      AnythinkClient(httpClient: MockClient(handler), store: store, baseUrl: base);
  await client.restoreSession();
  return client;
}

void main() {
  group('AnythinkSession.fromJson', () {
    test('reads snake_case tokens and expiry', () {
      final s = AnythinkSession.fromJson(
          {'access_token': 'a', 'refresh_token': 'r', 'expires_in': 60});
      expect(s.accessToken, 'a');
      expect(s.refreshToken, 'r');
      expect(s.expiresAt!.isAfter(DateTime.now()), isTrue);
    });

    test('reads camelCase tokens and a nested user', () {
      final s = AnythinkSession.fromJson({
        'accessToken': 'a',
        'user': {'id': 7, 'first_name': 'Ada', 'last_name': 'L', 'email': 'a@x.io'},
      });
      expect(s.accessToken, 'a');
      expect(s.user!.name, 'Ada L');
      expect(s.user!.id, '7');
    });

    test('keeps the previous refresh token when none is returned', () {
      final s = AnythinkSession.fromJson({'token': 'a'}, previousRefreshToken: 'old');
      expect(s.refreshToken, 'old');
    });

    test('fails clearly on an unknown shape', () {
      expect(() => AnythinkSession.fromJson({'foo': 1}), throwsFormatException);
    });
  });

  group('AnythinkException.fromResponse', () {
    test('problem details: first field error wins', () {
      final e = AnythinkException.fromResponse(400, jsonEncode({
        'title': 'One or more validation errors occurred.',
        'errors': {'Email': ['The Email field is required.']},
        'traceId': 't-1',
      }));
      expect(e.message, 'The Email field is required.');
      expect(e.fieldErrors['Email'], ['The Email field is required.']);
      expect(e.traceId, 't-1');
    });

    test('bare string body', () {
      final e = AnythinkException.fromResponse(400, jsonEncode('Default role not found'));
      expect(e.message, 'Default role not found');
    });
  });

  group('AnythinkClient', () {
    test('attaches the bearer token', () async {
      String? auth;
      final client = await clientWith((r) async {
        auth = r.headers['Authorization'];
        return json([]);
      }, session: const AnythinkSession(accessToken: 'tok'));
      await client.send('GET', '/x');
      expect(auth, 'Bearer tok');
    });

    test('on 401 refreshes once, then retries with the new token', () async {
      var refreshes = 0;
      final client = await clientWith((r) async {
        if (r.url.path.endsWith('/auth/v1/refresh')) {
          refreshes++;
          expect(jsonDecode(r.body), {'refresh_token': 'r1'});
          return json({'access_token': 'new', 'refresh_token': 'r2'});
        }
        return r.headers['Authorization'] == 'Bearer new'
            ? json({'ok': true})
            : json('expired', 401);
      }, session: const AnythinkSession(accessToken: 'old', refreshToken: 'r1'));

      final results = await Future.wait([client.send('GET', '/a'), client.send('GET', '/b')]);
      expect(results, everyElement({'ok': true}));
      expect(refreshes, 1);
      expect(client.session!.refreshToken, 'r2');
    });

    test('signs out when refresh fails', () async {
      final client = await clientWith((r) async => json('nope', 401),
          session: const AnythinkSession(accessToken: 'old', refreshToken: 'r1'));
      final changes = <AnythinkSession?>[];
      client.sessionChanges.listen(changes.add);

      await expectLater(client.send('GET', '/a'),
          throwsA(isA<AnythinkException>().having((e) => e.statusCode, 'status', 401)));
      await Future<void>.delayed(Duration.zero);
      expect(client.session, isNull);
      expect(changes, [null]);
    });
  });

  group('AnythinkNotesRepository', () {
    test('pages through the list', () async {
      final pages = <String>[];
      final client = await clientWith((r) async {
        pages.add(r.url.query);
        final page = int.parse(r.url.queryParameters['page']!);
        return json(page == 1
            ? List.generate(100, (i) => noteJson(i, 'n$i'))
            : [noteJson(100, 'last')]);
      }, session: const AnythinkSession(accessToken: 't'));

      final notes = await AnythinkNotesRepository(client).fetchNotes();
      expect(notes, hasLength(101));
      expect(notes.first.id, '0');
      expect(pages, ['page=1&limit=100', 'page=2&limit=100']);
    });

    test('accepts a wrapped list', () async {
      final client = await clientWith(
          (r) async => json({'items': [noteJson(1, 'a')], 'total': 1}),
          session: const AnythinkSession(accessToken: 't'));
      expect(await AnythinkNotesRepository(client).fetchNotes(), hasLength(1));
    });

    test('create / update / delete hit the right routes', () async {
      final calls = <String>[];
      final client = await clientWith((r) async {
        calls.add('${r.method} ${r.url.path} ${r.body}');
        return switch (r.method) {
          'DELETE' => http.Response('', 204),
          _ => json(noteJson(5, 'T')),
        };
      }, session: const AnythinkSession(accessToken: 't'));
      final repo = AnythinkNotesRepository(client);

      final created = await repo.createNote(title: 'T', body: 'B');
      await repo.updateNote(created.copyWith(title: 'T2'));
      await repo.deleteNote(created.id);

      expect(calls, [
        'POST /org/1/entities/notes/items {"title":"T","body":"B"}',
        'PUT /org/1/entities/notes/items/5 {"title":"T2","body":"body 5"}',
        'DELETE /org/1/entities/notes/items/5 ',
      ]);
    });

    test('fetchNote returns null on 404', () async {
      final client = await clientWith((r) async => json('Not found', 404),
          session: const AnythinkSession(accessToken: 't'));
      expect(await AnythinkNotesRepository(client).fetchNote('9'), isNull);
    });
  });
}
