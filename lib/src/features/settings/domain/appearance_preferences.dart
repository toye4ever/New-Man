enum AppearanceMode { system, light, dark }

enum AccentColor { blue, green, brown }

class AppearancePreferences {
  const AppearancePreferences({
    this.mode = AppearanceMode.system,
    this.accent = AccentColor.blue,
  });

  final AppearanceMode mode;
  final AccentColor accent;

  AppearancePreferences copyWith({AppearanceMode? mode, AccentColor? accent}) =>
      AppearancePreferences(
        mode: mode ?? this.mode,
        accent: accent ?? this.accent,
      );
}
