class TtsVoiceOption {
  const TtsVoiceOption({
    required this.key,
    required this.name,
    required this.locale,
    required this.settings,
    required this.networkRequired,
  });

  final String key;
  final String name;
  final String locale;
  final Map<String, String> settings;

  /// Null means the engine supplied no recognized network metadata.
  final bool? networkRequired;

  static bool? parseNetworkRequired(Object? value) => switch (value) {
    true || 1 || '1' || 'true' => true,
    false || 0 || '0' || 'false' => false,
    _ => null,
  };

  String get networkUseLabel => switch (networkRequired) {
    true => 'Internet required',
    false => 'Device reports no network needed; offline unverified',
    null => 'Network use unknown',
  };

  String get label => locale.isEmpty ? name : '$name ($locale)';
}

/// Platform-neutral narration operations used by the Bible reader.
abstract interface class BibleAudioService {
  AudioPlaybackSnapshot get playback;

  bool get supportsPause;

  void addPlaybackListener(void Function() listener);

  void removePlaybackListener(void Function() listener);

  Future<List<TtsVoiceOption>> getVoices();

  Future<void> setVoice(TtsVoiceOption voice);

  Future<void> setRate(double rate);

  Future<void> speak(String text);

  Future<void> pause();

  Future<void> resume();

  Future<void> stop();
}

enum AudioPlaybackState { idle, loading, playing, paused, stopped, error }

class AudioPlaybackSnapshot {
  const AudioPlaybackSnapshot(this.state, {this.message});

  final AudioPlaybackState state;
  final String? message;

  bool get isActive =>
      state == AudioPlaybackState.loading ||
      state == AudioPlaybackState.playing;
}
