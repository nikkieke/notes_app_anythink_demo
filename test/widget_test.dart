import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app_anythink_demo/app.dart';
import 'package:notes_app_anythink_demo/data/auth_repository.dart';
import 'package:notes_app_anythink_demo/data/mock/mock_auth_repository.dart';
import 'package:notes_app_anythink_demo/data/mock/mock_notes_repository.dart';
import 'package:notes_app_anythink_demo/data/notes_repository.dart';
import 'package:notes_app_anythink_demo/models/note.dart';

Future<void> pumpApp(WidgetTester tester, {List<Note>? seed}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider
            .overrideWithValue(MockAuthRepository(delay: Duration.zero)),
        notesRepositoryProvider.overrideWithValue(
            MockNotesRepository(latency: Duration.zero, seed: seed)),
      ],
      child: const NotesApp(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> signIn(WidgetTester tester) async {
  await tester.tap(find.text('Continue with Google'));
  await tester.pumpAndSettle();
}

Note seedNote(String id, String title, String body) {
  final now = DateTime.now();
  return Note(id: id, title: title, body: body, createdAt: now, updatedAt: now);
}

void main() {
  testWidgets('starts on sign in and lands on notes after signing in',
      (tester) async {
    await pumpApp(tester, seed: [seedNote('1', 'Groceries', 'Eggs')]);
    expect(find.text('Continue with Google'), findsOneWidget);

    await signIn(tester);
    expect(find.text('Groceries'), findsOneWidget);
  });

  testWidgets('shows empty state when there are no notes', (tester) async {
    await pumpApp(tester, seed: []);
    await signIn(tester);
    expect(find.text('No notes yet'), findsOneWidget);
  });

  testWidgets('creates a note and shows it in the list', (tester) async {
    await pumpApp(tester, seed: []);
    await signIn(tester);

    await tester.tap(find.byTooltip('New note'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'My first note');
    await tester.enterText(find.byType(TextField).last, 'Hello world');
    await tester.tap(find.byTooltip('Done'));
    await tester.pumpAndSettle();

    expect(find.text('My first note'), findsOneWidget);
    expect(find.text('Hello world'), findsOneWidget);
  });

  testWidgets('back button auto-saves edits', (tester) async {
    await pumpApp(tester, seed: [seedNote('1', 'Draft', 'Body')]);
    await signIn(tester);

    await tester.tap(find.text('Draft'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Final');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Final'), findsOneWidget);
    expect(find.text('Draft'), findsNothing);
  });

  testWidgets('deletes a note after confirming', (tester) async {
    await pumpApp(tester, seed: [seedNote('1', 'Old note', 'Bye')]);
    await signIn(tester);

    await tester.tap(find.text('Old note'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Old note'), findsNothing);
    expect(find.text('No notes yet'), findsOneWidget);
  });

  testWidgets('signing out returns to sign in', (tester) async {
    await pumpApp(tester, seed: []);
    await signIn(tester);

    await tester.tap(find.byTooltip('Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(find.text('Continue with Google'), findsOneWidget);
  });
}
