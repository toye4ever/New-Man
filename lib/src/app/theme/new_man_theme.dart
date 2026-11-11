import 'package:flutter/material.dart';
import '../../features/settings/domain/appearance_preferences.dart';

abstract final class NewManTheme {
  static ThemeData get light => build(Brightness.light, AccentColor.blue);
  static ThemeData get dark => build(Brightness.dark, AccentColor.blue);

  static Color buttonColor(AccentColor accent, Brightness brightness) =>
      switch ((accent, brightness)) {
        (AccentColor.blue, Brightness.light) => const Color(0xFF155EEF),
        (AccentColor.blue, Brightness.dark) => const Color(0xFF3169C8),
        (AccentColor.green, Brightness.light) => const Color(0xFF177348),
        (AccentColor.green, Brightness.dark) => const Color(0xFF2B7653),
        (AccentColor.brown, Brightness.light) => const Color(0xFFA45134),
        (AccentColor.brown, Brightness.dark) => const Color(0xFF82503C),
      };

  static ThemeData build(Brightness brightness, AccentColor accent) {
    final dark = brightness == Brightness.dark;
    final button = buttonColor(accent, brightness);
    final foregroundAccent = dark
        ? switch (accent) {
            AccentColor.blue => const Color(0xFF8DB5FF),
            AccentColor.green => const Color(0xFF8ED5AD),
            AccentColor.brown => const Color(0xFFD4A48E),
          }
        : button;
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: button,
          brightness: brightness,
        ).copyWith(
          primary: foregroundAccent,
          onPrimary: dark ? Colors.black : Colors.white,
          surface: dark ? Colors.black : Colors.white,
          onSurface: dark ? Colors.white : Colors.black,
          onSurfaceVariant: dark
              ? const Color(0xFFCACACA)
              : const Color(0xFF494949),
          surfaceContainerLowest: dark ? Colors.black : Colors.white,
          surfaceContainerLow: dark
              ? const Color(0xFF101010)
              : const Color(0xFFFAFAFA),
          surfaceContainer: dark
              ? const Color(0xFF181818)
              : const Color(0xFFF4F4F4),
          surfaceContainerHigh: dark
              ? const Color(0xFF242424)
              : const Color(0xFFEEEEEE),
          surfaceContainerHighest: dark
              ? const Color(0xFF303030)
              : const Color(0xFFE5E5E5),
          surfaceTint: Colors.transparent,
        );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: colorScheme.surface,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: button,
          foregroundColor: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: button,
          foregroundColor: Colors.white,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
      cardTheme: const CardThemeData(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        minWidth: 80,
        groupAlignment: -0.65,
      ),
    );
  }
}
