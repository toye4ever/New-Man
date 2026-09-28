import 'package:flutter_test/flutter_test.dart';
import 'package:scripture_planner/src/services/plan_assistant_service.dart';

void main() {
  test('converts verse ranges into unique chapter references', () {
    final assistant = PlanAssistantService();
    final result = assistant.apply(
      instruction: 'Only include the chapters of the Bible.',
      passagesText: 'Matthew 15:18-20\nMark 7:20-23\n1 Corinthians 6:12',
      endDate: DateTime(2026, 8, 1),
      readingWeekdays: <int>{DateTime.monday},
    );

    expect(result.changed, isTrue);
    expect(result.passagesText, 'Matthew 15\nMark 7\n1 Corinthians 6');
  });

  test('changes the end date from a plain-language instruction', () {
    final assistant = PlanAssistantService();
    final result = assistant.apply(
      instruction: 'Change the end date to August 30, 2026.',
      passagesText: 'Matthew 5',
      endDate: DateTime(2026, 8, 1),
      readingWeekdays: <int>{DateTime.monday},
    );

    expect(result.endDate, DateTime(2026, 8, 30));
  });
}
