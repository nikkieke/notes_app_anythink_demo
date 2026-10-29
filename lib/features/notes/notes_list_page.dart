import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../data/auth_repository.dart';
import '../../models/app_user.dart';
import '../../shared/widgets/state_views.dart';
import '../../shared/widgets/user_avatar.dart';
import '../auth/auth_providers.dart';
import 'notes_providers.dart';
import 'widgets/note_tile.dart';

class NotesListPage extends ConsumerWidget {
  const NotesListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesListProvider);
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: [
          if (user != null) _AccountMenu(user: user),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'New note',
        onPressed: () => context.push(Routes.newNote),
        child: const Icon(Icons.add),
      ),
      body: notes.when(
        loading: () => const LoadingView(),
        error: (_, _) => ErrorView(
          onRetry: () => ref.read(notesListProvider.notifier).refresh(),
        ),
        data: (notes) {
          if (notes.isEmpty) {
            return const MessageView(
              icon: Icons.description_outlined,
              title: 'No notes yet',
              message: 'Tap + to write your first note.',
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(notesListProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 96),
              itemCount: notes.length,
              separatorBuilder: (_, _) => const Divider(indent: 20),
              itemBuilder: (context, i) => NoteTile(
                note: notes[i],
                onTap: () => context.push(Routes.note(notes[i].id)),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AccountMenu extends ConsumerWidget {
  const _AccountMenu({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return PopupMenuButton<void>(
      tooltip: 'Account',
      offset: const Offset(0, 44),
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                user.email,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          onTap: () => ref.read(authRepositoryProvider).signOut(),
          child: const Row(
            children: [
              Icon(Icons.logout, size: 18),
              SizedBox(width: 10),
              Text('Sign out'),
            ],
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: UserAvatar(user: user),
      ),
    );
  }
}
