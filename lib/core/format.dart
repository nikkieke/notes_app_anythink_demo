import 'package:intl/intl.dart';

String formatRelative(DateTime time, {DateTime? now}) {
  now ??= DateTime.now();
  final diff = now.difference(time);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays < 2) return 'Yesterday';
  if (time.year == now.year) return DateFormat('MMM d').format(time);
  return DateFormat('MMM d, y').format(time);
}
