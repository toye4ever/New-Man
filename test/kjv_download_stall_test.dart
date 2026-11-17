import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:scripture_planner/src/models/reading_plan.dart';
import 'package:scripture_planner/src/features/word/translations/domain/translation_state.dart';
import 'package:scripture_planner/src/services/bible_version_repository.dart';

void main() {
  for (final stallHeaders in [false, true]) {
    testWidgets(
      '${stallHeaders ? 'missing headers' : 'partial body'} times out safely and permits retry',
      (tester) async {
        final directory = (await tester.runAsync(
          () => Directory.systemTemp.createTemp('synthetic-kjv-stall-'),
        ))!;
        final file = File('${directory.path}/kjv.json');
        final old = jsonEncode({
          'metadata': {'complete': true},
          'books': {'Synthetic': 'previous sentinel'},
        });
        await tester.runAsync(() => file.writeAsString(old));
        final headers = Completer<http.StreamedResponse>();
        var cancelled = false;
        var listened = false;
        final body = StreamController<List<int>>(
          onListen: () => listened = true,
          onCancel: () async {
            cancelled = true;
          },
        );
        var conversions = 0;
        var fileRequests = 0;
        final client = _SequenceClient([
          () async => stallHeaders
              ? headers.future
              : http.StreamedResponse(body.stream, 200, contentLength: 10),
          () async => http.StreamedResponse(Stream.value([4, 5, 6]), 200),
        ]);
        // Only state persistence and archive conversion are faked. The real
        // request/body timeouts, install catch/state path and file store run.
        final repository = _MemoryStateRepository(
          httpClient: client,
          kjvFileProvider: () async {
            fileRequests++;
            return file;
          },
          archiveConverter: (bytes) async {
            conversions++;
            expect(bytes, [4, 5, 6]);
            return {
              'metadata': {'complete': true},
              'books': {'Synthetic': 'replacement sentinel'},
            };
          },
        );
        final states = <TranslationInstallationState>[];
        Object? failure;
        var finished = false;
        try {
          final install = repository
              .install(BibleTranslation.kjv, onStateChanged: states.add)
              .then<void>(
                (_) => finished = true,
                onError: (Object error, StackTrace stack) {
                  failure = error;
                  finished = true;
                },
              );
          await tester.pump();
          if (!stallHeaders) {
            expect(listened, isTrue);
            body.add([1, 2]);
            await tester.pump();
            await tester.pump(); // Resume after the awaited progress callback.
            expect(body.isPaused, isFalse);
          }
          await tester.pump(
            const Duration(minutes: 2) - const Duration(milliseconds: 1),
          );
          expect(finished, isFalse);
          expect(states.last.status, TranslationInstallationStatus.downloading);
          await tester.pump(const Duration(milliseconds: 1));
          await tester.pump();
          expect(finished, isTrue);
          await install;
          expect(
            failure,
            isA<TranslationInstallationException>()
                .having((e) => e.code, 'code', 'download_timeout')
                .having((e) => e.message, 'message', contains('retry')),
          );
          expect(states.last.status, TranslationInstallationStatus.failed);
          expect(repository.saved.last.failureCode, 'download_timeout');
          final availability = TranslationAvailability(
            definition: BibleTranslation.kjv.definition,
            kind: TranslationAvailabilityKind.failed,
          );
          expect(availability.canInstall, isTrue);
          expect(availability.isBusy, isFalse);
          expect(conversions, 0);
          expect(fileRequests, 0); // No staging, backup or promotion reached.
          if (stallHeaders) {
            headers.complete(http.StreamedResponse(body.stream, 200));
          } else {
            expect(cancelled, isTrue);
          }
          body.add([3]); // Late data must not resume an expired attempt.
          await tester.pump();
          expect(conversions, 0);
          expect(fileRequests, 0);
          expect(states.last.status, TranslationInstallationStatus.failed);
          if (stallHeaders) expect(listened, isFalse);
          await tester.runAsync(() async {
            expect(await file.readAsString(), old);
            expect(await directory.list().length, 1);
            final reopened = BibleVersionRepository(
              httpClient: client,
              kjvFileProvider: () async => file,
            );
            expect(await reopened.isKjvInstalled(), isTrue);
          });
          await tester.runAsync(
            () => repository.install(
              BibleTranslation.kjv,
              onStateChanged: states.add,
            ),
          );
          expect(conversions, 1);
          expect(client.calls, 2);
          expect(states.last.status, TranslationInstallationStatus.installed);
          await tester.runAsync(() async {
            expect(await file.readAsString(), contains('replacement sentinel'));
            expect(await File('${file.path}.previous').readAsString(), old);
            expect(await repository.isKjvInstalled(), isTrue);
          });
        } finally {
          unawaited(body.close());
          repository.dispose();
          client.close();
          await tester.runAsync(() => directory.delete(recursive: true));
        }
      },
    );
  }
}

class _MemoryStateRepository extends BibleVersionRepository {
  _MemoryStateRepository({
    required super.httpClient,
    required super.kjvFileProvider,
    required super.archiveConverter,
  });
  final saved = <TranslationInstallationState>[];
  @override
  Future<void> saveInstallationState(
    BibleTranslation translation,
    TranslationInstallationState state,
  ) async => saved.add(state);
}

class _SequenceClient extends http.BaseClient {
  _SequenceClient(this.responses);
  final List<Future<http.StreamedResponse> Function()> responses;
  int calls = 0;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      responses[calls++]();
}
