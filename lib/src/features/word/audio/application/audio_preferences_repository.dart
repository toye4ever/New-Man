class AudioPreferences {
  const AudioPreferences({this.voiceKey, this.playbackRate = 0.45});

  final String? voiceKey;
  final double playbackRate;
}

abstract interface class AudioPreferencesRepository {
  Future<AudioPreferences> load();
  Future<void> save(AudioPreferences preferences);
}

class VolatileAudioPreferencesRepository implements AudioPreferencesRepository {
  AudioPreferences _value = const AudioPreferences();

  @override
  Future<AudioPreferences> load() async => _value;

  @override
  Future<void> save(AudioPreferences preferences) async {
    _value = preferences;
  }
}
