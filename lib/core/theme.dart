import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static final light = _build(
    brightness: Brightness.light,
    ink: const Color(0xFF191919),
    paper: Colors.white,
    muted: const Color(0xFF787774),
    border: const Color(0xFFE9E9E7),
    fill: const Color(0xFFF7F7F5),
  );

  static final dark = _build(
    brightness: Brightness.dark,
    ink: const Color(0xFFF0F0F0),
    paper: const Color(0xFF191919),
    muted: const Color(0xFF9B9B9B),
    border: const Color(0xFF2F2F2F),
    fill: const Color(0xFF252525),
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color ink,
    required Color paper,
    required Color muted,
    required Color border,
    required Color fill,
  }) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: ink,
      onPrimary: paper,
      secondary: ink,
      onSecondary: paper,
      error: ink,
      onError: paper,
      surface: paper,
      onSurface: ink,
      onSurfaceVariant: muted,
      outline: muted,
      outlineVariant: border,
      surfaceContainerHighest: fill,
    );

    final base = ThemeData(colorScheme: scheme, useMaterial3: true);
    final text = base.textTheme.apply(bodyColor: ink, displayColor: ink);
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(6));

    return base.copyWith(
      scaffoldBackgroundColor: paper,
      textTheme: text,
      splashFactory: NoSplash.splashFactory,
      highlightColor: fill,
      hoverColor: fill,
      appBarTheme: AppBarTheme(
        backgroundColor: paper,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        shape: Border(bottom: BorderSide(color: border)),
        titleTextStyle: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: ink,
        foregroundColor: paper,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          side: BorderSide(color: border),
          shape: shape,
          textStyle: text.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: ink, shape: shape),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: muted.withValues(alpha: 0.6)),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: ink,
        selectionColor: muted.withValues(alpha: 0.3),
        selectionHandleColor: ink,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: ink),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ink,
        contentTextStyle: TextStyle(color: paper),
        behavior: SnackBarBehavior.floating,
        shape: shape,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: paper,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: paper,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: border),
        ),
      ),
      iconTheme: IconThemeData(color: ink),
    );
  }
}
