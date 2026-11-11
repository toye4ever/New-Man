import '../domain/appearance_preferences.dart';

abstract interface class AppearancePreferencesRepository {
  Future<AppearancePreferences> load();
  Future<void> save(AppearancePreferences preferences);
}

class VolatileAppearancePreferencesRepository
    implements AppearancePreferencesRepository {
  AppearancePreferences _preferences = const AppearancePreferences();

  @override
  Future<AppearancePreferences> load() async => _preferences;

  @override
  Future<void> save(AppearancePreferences preferences) async {
    _preferences = preferences;
  }
}
