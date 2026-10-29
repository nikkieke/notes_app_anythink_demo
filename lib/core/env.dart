enum Backend { mock, anythink }

abstract final class Env {
  /// Select with `--dart-define=BACKEND=anythink`; defaults to the mocks.
  static final backend = Backend.values.byName(
    const String.fromEnvironment('BACKEND', defaultValue: 'mock'),
  );

  static const anythinkBaseUrl =
      'https://api.uk01-lon.anythink.cloud/org/70535616';

  /// Web OAuth client. On Android, Google issues ID tokens for this audience.
  static const googleServerClientId =
      '663727194323-o2fsgl5p8l4riajgrl5472hg798mh48e.apps.googleusercontent.com';
}
