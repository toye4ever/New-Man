import 'package:flutter_test/flutter_test.dart';
import 'package:scripture_planner/src/services/reference_parser.dart';

void main() {
  group('ReferenceParser', () {
    final parser = ReferenceParser();

    test('parses repeated chapters after one book name', () {
      final result = parser.parse('Matthew 5, 15, 18');

      expect(result.issues, isEmpty);
      expect(result.references.map((item) => item.display), <String>[
        'Matthew 5',
        'Matthew 15',
        'Matthew 18',
      ]);
    });

    test('parses chapter and verse ranges', () {
      final result = parser.parse('John 1-3; Romans 8:1-17');

      expect(result.issues, isEmpty);
      expect(result.references[0].display, 'John 1-3');
      expect(result.references[1].display, 'Romans 8:1-17');
    });

    test('reports invalid chapters', () {
      final result = parser.parse('Matthew 51');

      expect(result.references, isEmpty);
      expect(result.issues, hasLength(1));
      expect(result.issues.first.message, contains('28 chapters'));
    });

    test('normalizes compact Go To verse forms and numbered aliases', () {
      expect(parser.parse('rom 4:3').references.single.display, 'Romans 4:3');
      expect(parser.parse('rom 4 3').references.single.display, 'Romans 4:3');
      expect(parser.parse('rom 4 3 8').references.single.display, 'Romans 4:3-8');
      expect(parser.parse('1 cor 13 4').references.single.display, '1 Corinthians 13:4');
    });
  });
}
