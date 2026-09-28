import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:scripture_planner/src/services/tts_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Windows narration can be stopped without terminating the app',
    () async {
      if (!Platform.isWindows) return;

      final service = TtsService();
      final voices = await service.getVoices();
      expect(voices, isNotEmpty);

      final speech = List<String>.filled(
        100,
        'New Man Windows narration smoke test.',
      ).join(' ');
      final speaking = service.speak(speech);
      await Future<void>.delayed(const Duration(milliseconds: 500));

      expect(service.isSpeaking, isTrue);
      await service.stop();
      await speaking.timeout(const Duration(seconds: 10));
      expect(service.isSpeaking, isFalse);
    },
  );
}
