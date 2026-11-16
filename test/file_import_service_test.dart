import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:scripture_planner/src/services/file_import_service.dart';

void main() {
  final service = FileImportService();
  String parse(String name, String input) => service
      .parsePassageFile(name, Uint8List.fromList(utf8.encode(input)))
      .text;

  test('imports BOM-prefixed UTF-8 TXT, CSV and JSON', () {
    expect(parse('plan.TXT', '\uFEFFJohn 3\nRomans 8'), 'John 3\nRomans 8');
    expect(
      parse('plan.csv', '\uFEFFreference,title\r\nJohn 3,Faith'),
      'John 3',
    );
    expect(
      parse('plan.json', '\uFEFF{"readings":[{"reference":"John 3"}]}'),
      'John 3',
    );
  });

  test('CSV preserves quoted delimiters, newlines and escaped quotes', () {
    expect(
      parse(
        'plan.csv',
        'title,passage\r\n"A, B","John 3\nRomans 8"\r\n"A ""quote""",Psalm 1',
      ),
      'John 3\nRomans 8\nPsalm 1',
    );
    expect(parse('plan.csv', 'John 3\r\nRomans 8'), 'John 3\nRomans 8');
  });

  test('rejects malformed CSV instead of importing a partial reading list', () {
    for (final input in [
      'reference\n"John 3\nRomans 8',
      'reference\nJohn "3"',
      'reference\n"John 3"extra',
      'reference\n"John 3""',
    ]) {
      expect(
        () => parse('plan.csv', input),
        throwsFormatException,
        reason: input,
      );
    }
  });

  test('rejects empty and unsupported imports', () {
    for (final entry in {
      'empty.txt': '\uFEFF \n',
      'empty.csv': 'reference\n\n',
      'empty.json': '{"passages":[]}',
      'plan.pdf': 'John 3',
    }.entries) {
      expect(() => parse(entry.key, entry.value), throwsFormatException);
    }
    expect(
      () => service.parsePassageFile('plan.txt', Uint8List.fromList([0xff])),
      throwsFormatException,
    );
  });

  test('rejects mixed JSON lists without silently dropping readings', () {
    for (final input in [
      '["John 3",42]',
      '["John 3",{"title":"missing reference"}]',
      '["John 3",""]',
      '{"readings":[{"reference":"John 3"},null]}',
    ]) {
      expect(() => parse('plan.json', input), throwsFormatException);
    }
  });

  test('JSON accepts passage lists and single reference objects', () {
    expect(
      parse('plan.json', '["John 3",{"passage":"Romans 8"}]'),
      'John 3\nRomans 8',
    );
    expect(parse('plan.json', '{"reference":"Psalm 1"}'), 'Psalm 1');
  });
}
