import 'package:drift/drift.dart' as drift;

import '../../../../core/database/app_database.dart';
import '../application/audio_preferences_repository.dart';

class DriftAudioPreferencesRepository implements AudioPreferencesRepository {
  const DriftAudioPreferencesRepository(this.database);

  final AppDatabase database;

  @override
  Future<AudioPreferences> load() async {
    final row = await (database.select(database.wordAudioPreferences)
          ..where((table) => table.id.equals('reader')))
        .getSingleOrNull();
    if (row == null) return const AudioPreferences();
    return AudioPreferences(voiceKey: row.voiceKey, playbackRate: row.playbackRate);
  }

  @override
  Future<void> save(AudioPreferences preferences) => database.into(
    database.wordAudioPreferences,
  ).insertOnConflictUpdate(
    WordAudioPreferencesCompanion.insert(
      id: 'reader',
      voiceKey: drift.Value(preferences.voiceKey),
      playbackRate: preferences.playbackRate,
    ),
  );
}
