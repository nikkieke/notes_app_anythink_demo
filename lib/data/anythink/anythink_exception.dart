import 'dart:convert';

/// An error from the Anythink API, normalised from either of its two shapes:
/// RFC 9110 problem details (`{title, errors, traceId}`) or a bare JSON string.
class AnythinkException implements Exception {
  const AnythinkException(
    this.statusCode,
    this.message, {
    this.fieldErrors = const {},
    this.traceId,
  });

  /// 0 when the request never got a response.
  final int statusCode;
  final String message;
  final Map<String, List<String>> fieldErrors;
  final String? traceId;

  bool get isUnauthorized => statusCode == 401;
  bool get isNotFound => statusCode == 404;

  factory AnythinkException.fromResponse(int statusCode, String body) {
    Object? decoded;
    try {
      decoded = body.isEmpty ? null : jsonDecode(body);
    } on FormatException {
      decoded = body;
    }

    if (decoded is Map<String, dynamic>) {
      final errors = <String, List<String>>{
        for (final e in (decoded['errors'] as Map<String, dynamic>? ?? {}).entries)
          e.key: [for (final m in e.value as List) m.toString()],
      };
      final firstError = errors.values.expand((m) => m).firstOrNull;
      return AnythinkException(
        statusCode,
        firstError ?? decoded['title'] as String? ?? 'Request failed',
        fieldErrors: errors,
        traceId: decoded['traceId'] as String?,
      );
    }
    final text = decoded?.toString() ?? '';
    return AnythinkException(statusCode, text.isEmpty ? 'Request failed' : text);
  }

  @override
  String toString() => 'AnythinkException($statusCode): $message';
}
