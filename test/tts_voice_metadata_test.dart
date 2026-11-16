import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scripture_planner/src/features/word/audio/application/bible_audio_service.dart';
import 'package:scripture_planner/src/services/tts_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'voice network metadata preserves unknown and recognizes platform flags',
    () {
      for (final value in [true, 1, '1', 'true']) {
        expect(TtsVoiceOption.parseNetworkRequired(value), isTrue);
      }
      for (final value in [false, 0, '0', 'false']) {
        expect(TtsVoiceOption.parseNetworkRequired(value), isFalse);
      }
      for (final value in [null, '', 'unknown', 2, [], 'False']) {
        expect(TtsVoiceOption.parseNetworkRequired(value), isNull);
      }
    },
  );

  test(
    'service decodes actual Android plugin numeric strings without an engine',
    () async {
      const channel = MethodChannel('flutter_tts');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'getVoices') {
              return [
                {'name': 'Cloud', 'locale': 'en-US', 'network_required': '1'},
                {'name': 'Device', 'locale': 'en-US', 'network_required': '0'},
                {'name': 'Unspecified', 'locale': 'en-US'},
              ];
            }
            return 1;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      final voices = await TtsService().getVoices();
      expect(voices.map((v) => v.networkRequired), [true, false, null]);
      expect(voices.first.networkUseLabel, 'Internet required');
      expect(voices[1].networkUseLabel, contains('offline unverified'));
      expect(voices.last.networkUseLabel, 'Network use unknown');
    },
  );
}
