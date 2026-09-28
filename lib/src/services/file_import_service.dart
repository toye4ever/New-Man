import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

class ImportedPassageText {
  const ImportedPassageText({required this.fileName, required this.text});

  final String fileName;
  final String text;
}

class FileImportService {
  Future<ImportedPassageText?> pickPassageFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['txt', 'csv', 'json'],
    );

    if (result.isEmpty) {
      return null;
    }

    final file = result.single;
    final bytes = await file.readAsBytes();
    final extensionSeparator = file.name.lastIndexOf('.');
    final extension = extensionSeparator == -1
        ? ''
        : file.name.substring(extensionSeparator + 1).toLowerCase();
    final text = switch (extension) {
      'txt' => utf8.decode(bytes),
      'csv' => _extractCsvPassages(bytes),
      'json' => _extractJsonPassages(bytes),
      _ => throw const FormatException(
        'Only TXT, CSV, and JSON files are supported.',
      ),
    };

    return ImportedPassageText(fileName: file.name, text: text.trim());
  }

  String _extractCsvPassages(Uint8List bytes) {
    final rows = _parseCsv(utf8.decode(bytes));
    if (rows.isEmpty) {
      throw const FormatException('The CSV file is empty.');
    }

    final headers = rows.first
        .map((value) => value.trim().toLowerCase())
        .toList();
    var passageIndex = headers.indexOf('passage');
    if (passageIndex == -1) {
      passageIndex = headers.indexOf('reference');
    }

    final startRow = passageIndex == -1 ? 0 : 1;
    passageIndex = passageIndex == -1 ? 0 : passageIndex;

    final passages = <String>[];
    for (var rowIndex = startRow; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];
      if (passageIndex < row.length && row[passageIndex].trim().isNotEmpty) {
        passages.add(row[passageIndex].trim());
      }
    }

    if (passages.isEmpty) {
      throw const FormatException(
        'No passage or reference values were found in the CSV file.',
      );
    }
    return passages.join('\n');
  }

  String _extractJsonPassages(Uint8List bytes) {
    final decoded = jsonDecode(utf8.decode(bytes));
    final passages = <String>[];

    void addValue(dynamic value) {
      if (value is String && value.trim().isNotEmpty) {
        passages.add(value.trim());
      } else if (value is Map<String, dynamic>) {
        final candidate = value['passage'] ?? value['reference'];
        if (candidate is String && candidate.trim().isNotEmpty) {
          passages.add(candidate.trim());
        }
      }
    }

    if (decoded is List<dynamic>) {
      for (final item in decoded) {
        addValue(item);
      }
    } else if (decoded is Map<String, dynamic>) {
      final list = decoded['passages'] ?? decoded['readings'];
      if (list is List<dynamic>) {
        for (final item in list) {
          addValue(item);
        }
      } else {
        addValue(decoded);
      }
    }

    if (passages.isEmpty) {
      throw const FormatException('No passages were found in the JSON file.');
    }
    return passages.join('\n');
  }

  List<List<String>> _parseCsv(String input) {
    final rows = <List<String>>[];
    var row = <String>[];
    var field = StringBuffer();
    var quoted = false;

    for (var index = 0; index < input.length; index++) {
      final character = input[index];
      if (character == '"') {
        if (quoted && index + 1 < input.length && input[index + 1] == '"') {
          field.write('"');
          index++;
        } else {
          quoted = !quoted;
        }
      } else if (character == ',' && !quoted) {
        row.add(field.toString());
        field = StringBuffer();
      } else if ((character == '\n' || character == '\r') && !quoted) {
        if (character == '\r' &&
            index + 1 < input.length &&
            input[index + 1] == '\n') {
          index++;
        }
        row.add(field.toString());
        field = StringBuffer();
        if (row.any((value) => value.trim().isNotEmpty)) {
          rows.add(row);
        }
        row = <String>[];
      } else {
        field.write(character);
      }
    }

    row.add(field.toString());
    if (row.any((value) => value.trim().isNotEmpty)) {
      rows.add(row);
    }
    return rows;
  }
}
