import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../models/note.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/state_views.dart';
import 'notes_providers.dart';

class NoteEditorPage extends ConsumerStatefulWidget {
  const NoteEditorPage({super.key, this.noteId});

  final String? noteId;

  @override
  ConsumerState<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends ConsumerState<NoteEditorPage> {
  // Resolved once, so later list updates (save/delete) don't swap the editor.
  Note? _note;

  @override
  Widget build(BuildContext context) {
    final id = widget.noteId;
    if (id == null || _note != null) return _Editor(initial: _note);

    final notes = ref.watch(notesListProvider);
    return notes.when(
      loading: () => const Scaffold(body: LoadingView()),
      error: (_, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(
          onRetry: () => ref.read(notesListProvider.notifier).refresh(),
        ),
      ),
      data: (notes) {
        _note = notes.where((n) => n.id == id).firstOrNull;
        if (_note == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const MessageView(
              icon: Icons.search_off,
              title: 'Note not found',
              message: 'It may have been deleted.',
            ),
          );
        }
        return _Editor(initial: _note);
      },
    );
  }
}

class _Editor extends ConsumerStatefulWidget {
  const _Editor({required this.initial});

  final Note? initial;

  @override
  ConsumerState<_Editor> createState() => _EditorState();
}

class _EditorState extends ConsumerState<_Editor> {
  late final _title = TextEditingController(text: widget.initial?.title);
  late final _body = TextEditingController(text: widget.initial?.body);
  late Note? _note = widget.initial;
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  bool get _hasChanges {
    final note = _note;
    if (note == null) {
      return _title.text.trim().isNotEmpty || _body.text.trim().isNotEmpty;
    }
    return note.title != _title.text || note.body != _body.text;
  }

  Future<bool> _save() async {
    if (!_hasChanges) return true;
    final notifier = ref.read(notesListProvider.notifier);
    try {
      final note = _note;
      _note = note == null
          ? await notifier.create(title: _title.text, body: _body.text)
          : await notifier.save(
              note.copyWith(title: _title.text, body: _body.text));
      return true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't save note.")),
        );
      }
      return false;
    }
  }

  Future<void> _saveAndClose() async {
    if (_busy) return;
    setState(() => _busy = true);
    final ok = await _save();
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) context.pop();
  }

  Future<void> _delete() async {
    final note = _note;
    if (note == null || _busy) return;
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete note?',
      message: 'This note will be permanently deleted.',
    );
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref.read(notesListProvider.notifier).delete(note.id);
      if (mounted) context.pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't delete note.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final note = _note;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _saveAndClose();
      },
      child: Scaffold(
        appBar: AppBar(
          actions: [
            if (note != null)
              IconButton(
                tooltip: 'Delete',
                onPressed: _busy ? null : _delete,
                icon: const Icon(Icons.delete_outline),
              ),
            IconButton(
              tooltip: 'Done',
              onPressed: _busy ? null : _saveAndClose,
              icon: _busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _title,
                  autofocus: note == null,
                  maxLines: null,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.sentences,
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                  decoration: const InputDecoration(
                    hintText: 'Untitled',
                    isCollapsed: true,
                  ),
                ),
                if (note != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Edited ${formatRelative(note.updatedAt).toLowerCase()}',
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                ],
                const SizedBox(height: 16),
                Expanded(
                  child: TextField(
                    controller: _body,
                    expands: true,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    textAlignVertical: TextAlignVertical.top,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
                    decoration: const InputDecoration(
                      hintText: 'Start writing…',
                      isCollapsed: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
