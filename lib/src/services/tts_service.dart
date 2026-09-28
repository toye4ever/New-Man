import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../features/word/audio/application/bible_audio_service.dart';

class TtsService implements BibleAudioService {
  final FlutterTts _tts = FlutterTts();

  bool _configured = false;
  bool _isSpeaking = false;
  double _speechRate = 0.45;
  Process? _windowsSpeechProcess;
  int _nextSessionId = 0;
  int? _activeSessionId;
  String? _windowsVoiceName;
  AudioPlaybackSnapshot _playback = const AudioPlaybackSnapshot(AudioPlaybackState.idle);

  bool get isSpeaking => _isSpeaking;

  @override
  AudioPlaybackSnapshot get playback => _playback;

  @override
  // flutter_tts exposes pause on some platforms but no reliable corresponding
  // resume operation for the active utterance. Do not promise false parity.
  bool get supportsPause => false;

  final _PlaybackNotifier _playbackNotifier = _PlaybackNotifier();

  void _setPlayback(AudioPlaybackSnapshot value) {
    _playback = value;
    _playbackNotifier.notifyPlaybackChanged();
  }

  @override
  void addPlaybackListener(void Function() listener) =>
      _playbackNotifier.addListener(listener);

  @override
  void removePlaybackListener(void Function() listener) =>
      _playbackNotifier.removeListener(listener);

  Future<void> _configure() async {
    if (_configured) return;

    // flutter_tts has a known Windows 11 crash in its native stop() path.
    // Windows therefore uses an isolated System.Speech process below, while
    // Android and the remaining supported platforms keep using flutter_tts.
    if (!Platform.isWindows) {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(_speechRate);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true);
    }

    _configured = true;
  }

  @override
  Future<List<TtsVoiceOption>> getVoices() async {
    await _configure();
    if (Platform.isWindows) return _getWindowsVoices();

    final raw = await _tts.getVoices;
    if (raw is! List) return const <TtsVoiceOption>[];

    final voices = <TtsVoiceOption>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final map = <String, String>{
        for (final entry in item.entries)
          if (entry.value != null) '${entry.key}': '${entry.value}',
      };
      final name = map['name'] ?? map['identifier'] ?? 'System voice';
      final locale = map['locale'] ?? '';
      final identifier = map['identifier'];
      final settings = <String, String>{
        if (map['name'] != null) 'name': map['name']!,
        if (locale.isNotEmpty) 'locale': locale,
        'identifier': ?identifier,
      };
      voices.add(
        TtsVoiceOption(
          key: identifier ?? '$name|$locale',
          name: name,
          locale: locale,
          settings: settings,
          networkRequired: map['network_required'] == 'true',
        ),
      );
    }
    voices.sort((left, right) => left.label.compareTo(right.label));
    return voices;
  }

  Future<List<TtsVoiceOption>> _getWindowsVoices() async {
    const script = r'''
Add-Type -AssemblyName System.Speech
$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
try {
  $voices = @($synth.GetInstalledVoices() | ForEach-Object {
    $info = $_.VoiceInfo
    [PSCustomObject]@{
      name = $info.Name
      locale = $info.Culture.Name
      identifier = $info.Name
      network_required = 'false'
    }
  })
  ConvertTo-Json -InputObject $voices -Compress
}
finally {
  $synth.Dispose()
}
''';

    final result = await Process.run('powershell.exe', const <String>[
      '-NoProfile',
      '-NonInteractive',
      '-Command',
      script,
    ], runInShell: false);

    if (result.exitCode != 0) return const <TtsVoiceOption>[];
    final output = '${result.stdout}'.trim();
    if (output.isEmpty) return const <TtsVoiceOption>[];

    try {
      final decoded = jsonDecode(output);
      final entries = decoded is List ? decoded : <dynamic>[decoded];
      final voices = <TtsVoiceOption>[];
      for (final entry in entries) {
        if (entry is! Map) continue;
        final name = '${entry['name'] ?? 'Windows voice'}';
        final locale = '${entry['locale'] ?? ''}';
        voices.add(
          TtsVoiceOption(
            key: name,
            name: name,
            locale: locale,
            settings: <String, String>{
              'name': name,
              if (locale.isNotEmpty) 'locale': locale,
              'identifier': name,
            },
            networkRequired: false,
          ),
        );
      }
      voices.sort((left, right) => left.label.compareTo(right.label));
      return voices;
    } catch (_) {
      return const <TtsVoiceOption>[];
    }
  }

  @override
  Future<void> setVoice(TtsVoiceOption voice) async {
    await _configure();
    if (Platform.isWindows) {
      _windowsVoiceName = voice.name;
      return;
    }
    await _tts.setVoice(voice.settings);
  }

  @override
  Future<void> speak(String text) async {
    await _configure();
    final normalized = text.trim();
    if (normalized.isEmpty) return;

    if (_isSpeaking) await stop();
    final sessionId = ++_nextSessionId;
    _activeSessionId = sessionId;
    _setPlayback(const AudioPlaybackSnapshot(AudioPlaybackState.loading));
    _isSpeaking = true;

    try {
      _setPlayback(const AudioPlaybackSnapshot(AudioPlaybackState.playing));
      if (Platform.isWindows) {
        await _speakWithWindowsSystemVoice(normalized, sessionId);
      } else {
        await _tts.speak(normalized);
      }
    } catch (_) {
      if (_activeSessionId == sessionId) {
        _setPlayback(const AudioPlaybackSnapshot(AudioPlaybackState.error));
      }
      rethrow;
    } finally {
      if (_activeSessionId == sessionId) {
        _isSpeaking = false;
        _activeSessionId = null;
      }
      if (_activeSessionId == null && _playback.state != AudioPlaybackState.error) {
        _setPlayback(const AudioPlaybackSnapshot(AudioPlaybackState.stopped));
      }
    }
  }

  @override
  Future<void> pause() async {
    throw UnsupportedError('Pause is not supported by this TTS platform.');
  }

  @override
  Future<void> resume() async {
    if (!supportsPause || _playback.state != AudioPlaybackState.paused) return;
    throw UnsupportedError('Resume is not supported by this TTS platform.');
  }

  Future<void> _speakWithWindowsSystemVoice(String text, int sessionId) async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'scripture_planner_tts_',
    );
    final textFile = File('${tempDirectory.path}\\reading.txt');
    final scriptFile = File('${tempDirectory.path}\\speak.ps1');

    await textFile.writeAsString(text, encoding: utf8, flush: true);
    await scriptFile.writeAsString(
      _windowsSpeechScript,
      encoding: utf8,
      flush: true,
    );

    final windowsRate = ((_speechRate - 0.45) * 20).round().clamp(-10, 10);
    final arguments = <String>[
      '-NoProfile',
      '-NonInteractive',
      '-ExecutionPolicy',
      'Bypass',
      '-File',
      scriptFile.path,
      '-TextPath',
      textFile.path,
      '-Rate',
      '$windowsRate',
      if (_windowsVoiceName != null) ...<String>[
        '-VoiceName',
        _windowsVoiceName!,
      ],
    ];

    final process = await Process.start(
      'powershell.exe',
      arguments,
      runInShell: false,
    );
    if (_activeSessionId != sessionId) { process.kill(); await process.exitCode; return; }
    _windowsSpeechProcess = process;

    final errorFuture = process.stderr.transform(utf8.decoder).join();
    await process.stdout.drain();
    final exitCode = await process.exitCode;
    final errorOutput = (await errorFuture).trim();
    final wasStopped = !identical(_windowsSpeechProcess, process);

    if (_activeSessionId == sessionId && identical(_windowsSpeechProcess, process)) {
      _windowsSpeechProcess = null;
    }

    try {
      await tempDirectory.delete(recursive: true);
    } catch (_) {
      // Windows can briefly retain a file handle after process exit.
    }

    if (exitCode != 0 && !wasStopped) {
      throw StateError(
        errorOutput.isEmpty
            ? 'Windows narration failed with exit code $exitCode.'
            : errorOutput,
      );
    }
  }

  @override
  Future<void> stop() async {
    if (!_isSpeaking) {
      _setPlayback(const AudioPlaybackSnapshot(AudioPlaybackState.stopped));
      return;
    }

    if (Platform.isWindows) {
      final process = _windowsSpeechProcess;
      final sessionId = _activeSessionId;
      _windowsSpeechProcess = null;
      process?.kill();
      if (process != null) await process.exitCode;
      if (_activeSessionId == sessionId) {
        _isSpeaking = false;
        _activeSessionId = null;
        _setPlayback(const AudioPlaybackSnapshot(AudioPlaybackState.stopped));
      }
      return;
    }

    try {
      await _tts.stop();
    } finally {
      _isSpeaking = false;
      _activeSessionId = null;
      _setPlayback(const AudioPlaybackSnapshot(AudioPlaybackState.stopped));
    }
  }

  @override
  Future<void> setRate(double rate) async {
    _speechRate = rate;
    await _configure();
    if (!Platform.isWindows) {
      await _tts.setSpeechRate(rate);
    }
  }
}

class _PlaybackNotifier extends ChangeNotifier {
  void notifyPlaybackChanged() => notifyListeners();
}

const String _windowsSpeechScript = r'''
param(
  [Parameter(Mandatory = $true)]
  [string]$TextPath,

  [int]$Rate = 0,

  [string]$VoiceName = ''
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Speech

$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
try {
  if (-not [string]::IsNullOrWhiteSpace($VoiceName)) {
    $synth.SelectVoice($VoiceName)
  }

  $synth.Rate = [Math]::Max(-10, [Math]::Min(10, $Rate))
  $text = [System.IO.File]::ReadAllText(
    $TextPath,
    [System.Text.Encoding]::UTF8
  )
  $synth.Speak($text)
}
finally {
  $synth.Dispose()
}
''';
