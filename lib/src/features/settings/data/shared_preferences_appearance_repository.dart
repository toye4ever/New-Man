import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../application/appearance_preferences_repository.dart';
import '../domain/appearance_preferences.dart';

class SharedPreferencesAppearanceRepository
    implements AppearancePreferencesRepository {
  SharedPreferencesAppearanceRepository({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const storageKey = 'new_man.appearance.v1';
  final SharedPreferencesAsync _preferences;

  @override
  Future<AppearancePreferences> load() async {
    final raw = await _preferences.getString(storageKey);
    if (raw == null) return const AppearancePreferences();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return const AppearancePreferences();
      }
      return AppearancePreferences(
        mode: AppearanceMode.values.firstWhere(
          (value) => value.name == decoded['mode'],
          orElse: () => AppearanceMode.system,
        ),
        accent: AccentColor.values.firstWhere(
          (value) => value.name == decoded['accent'],
          orElse: () => AccentColor.blue,
        ),
      );
    } on FormatException {
      return const AppearancePreferences();
    }
  }

  @override
  Future<void> save(AppearancePreferences preferences) =>
      _preferences.setString(
        storageKey,
        jsonEncode({
          'mode': preferences.mode.name,
          'accent': preferences.accent.name,
        }),
      );
}
