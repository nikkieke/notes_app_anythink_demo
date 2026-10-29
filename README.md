# Notes (Flutter + Anythink)

A simple notes app with Google sign-in, using [Anythink](https://anythink.cloud) as the backend.

Requires Flutter 3.38+.

## Run

```bash
flutter pub get
flutter run
```

This uses mock data (fake sign-in, in-memory notes). Same as:

```bash
flutter run --dart-define=BACKEND=mock
```

## Run with Anythink

```bash
flutter run --dart-define=BACKEND=anythink
```

## Test

```bash
flutter test
```
