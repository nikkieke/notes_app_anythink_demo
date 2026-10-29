import '../../models/app_user.dart';

class AnythinkSession {
  const AnythinkSession({
    required this.accessToken,
    this.refreshToken,
    this.expiresAt,
    this.user,
  });

  final String accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;
  final AppUser? user;

  /// Parses an auth response (`/auth/v1/native/google`, `/auth/v1/refresh`).
  ///
  /// The success shape hasn't been observed yet, so this accepts the likely
  /// key spellings. Tighten it once a real response has been seen.
  factory AnythinkSession.fromJson(
    Map<String, dynamic> json, {
    String? previousRefreshToken,
  }) {
    final access = _firstString(json, ['access_token', 'accessToken', 'token', 'jwt']);
    if (access == null) {
      throw FormatException(
          'Unrecognised Anythink auth response, keys: ${json.keys.toList()}');
    }
    final expiresIn = json['expires_in'] ?? json['expiresIn'];
    final expiresAt = json['expires_at'] ?? json['expiresAt'];
    final user = json['user'];
    return AnythinkSession(
      accessToken: access,
      refreshToken: _firstString(json, ['refresh_token', 'refreshToken']) ??
          previousRefreshToken,
      expiresAt: expiresIn is num
          ? DateTime.now().add(Duration(seconds: expiresIn.toInt()))
          : expiresAt is String
              ? DateTime.tryParse(expiresAt)
              : null,
      user: user is Map<String, dynamic> ? AppUser.fromJson(user) : null,
    );
  }

  AnythinkSession withUser(AppUser user) => AnythinkSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresAt: expiresAt,
        user: user,
      );

  /// Storage format, independent of the API's response shape.
  factory AnythinkSession.fromStorage(Map<String, dynamic> json) {
    final user = json['user'];
    return AnythinkSession(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String?,
      expiresAt: DateTime.tryParse(json['expires_at'] as String? ?? ''),
      user: user is Map<String, dynamic> ? AppUser.fromJson(user) : null,
    );
  }

  Map<String, dynamic> toStorage() => {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'expires_at': expiresAt?.toIso8601String(),
        'user': user?.toJson(),
      };

  static String? _firstString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.isNotEmpty) return value;
    }
    return null;
  }
}
