import 'package:flutter/foundation.dart';

import '../data/plan_templates.dart';
import '../models/plan_template.dart';
import '../models/reading_plan.dart';
import '../services/bible_version_repository.dart';
import '../services/plan_repository.dart';
import '../services/plan_scheduler.dart';
import '../features/word/bible/application/reader_state_repository.dart';
import '../features/word/audio/application/audio_preferences_repository.dart';
import '../features/word/bible/domain/bible_books.dart';
import '../features/word/bible/domain/reader_position.dart';
import '../features/word/translations/domain/translation_state.dart';
import '../features/word/plans/domain/schedule_preview.dart';
import '../features/word/saved_scripture/application/saved_scripture_repository.dart';

class AppController extends ChangeNotifier {
  AppController({
    required this.repository,
    required this.versionRepository,
    ReaderStateRepository? readerStateRepository,
    AudioPreferencesRepository? audioPreferencesRepository,
    SavedScriptureRepository? savedScriptureRepository,
    this.nltOnlineConfigured = false,
  }) : readerStateRepository =
           readerStateRepository ?? VolatileReaderStateRepository(),
       audioPreferencesRepository =
           audioPreferencesRepository ?? VolatileAudioPreferencesRepository(),
       savedScriptureRepository =
           savedScriptureRepository ?? VolatileSavedScriptureRepository();

  final PlanRepository repository;
  final BibleVersionRepository versionRepository;
  final ReaderStateRepository readerStateRepository;
  final AudioPreferencesRepository audioPreferencesRepository;
  final SavedScriptureRepository savedScriptureRepository;
  final bool nltOnlineConfigured;
  final List<PlanTemplate> templates = buildPlanTemplates();
  final PlanScheduler _scheduler = PlanScheduler();

  List<ReadingPlan> _plans = <ReadingPlan>[];
  Map<BibleTranslation, TranslationInstallationState>
  _translationInstallations =
      <BibleTranslation, TranslationInstallationState>{};
  int _selectedDestination = 0;
  int _selectedWordDestination = 0;
  PlanTemplate? _templateToCreate;
  ReadingPlan? _planToEdit;
  ReaderPosition? _lastReaderPosition;

  List<ReadingPlan> get plans => List.unmodifiable(_plans);
  Set<BibleTranslation> get installedTranslations =>
      Set.unmodifiable(BibleTranslation.values.where(isTranslationUsable));
  int get selectedDestination => _selectedDestination;
  int get selectedWordDestination => _selectedWordDestination;
  PlanTemplate? get templateToCreate => _templateToCreate;
  ReadingPlan? get planToEdit => _planToEdit;
  ReaderPosition? get lastReaderPosition => _lastReaderPosition;
  ReaderPosition? get continueReadingPosition {
    final position = _lastReaderPosition;
    if (position == null) return null;
    final book = bibleBookByName(position.book);
    if (book == null || position.chapter < 1 || position.chapter > book.chapterCount) {
      return null;
    }
    return position;
  }

  Future<void> load() async {
    _plans = await repository.loadPlans();
    final translationState = await versionRepository.loadTranslationState();
    _translationInstallations = Map.of(translationState.installations);
    _lastReaderPosition = await readerStateRepository.load();
    notifyListeners();
  }

  Future<void> saveReaderPosition({
    required String book,
    required int chapter,
    required BibleTranslation translation,
  }) async {
    final canonicalBook = bibleBookByName(book);
    if (canonicalBook == null ||
        chapter < 1 ||
        chapter > canonicalBook.chapterCount) {
      throw ArgumentError('Invalid Bible reader position.');
    }
    final position = ReaderPosition(
      book: canonicalBook.name,
      chapter: chapter,
      translation: translation,
      updatedAt: DateTime.now().toUtc(),
    );
    await readerStateRepository.save(position);
    _lastReaderPosition = position;
    notifyListeners();
  }

  void selectDestination(int index) {
    _selectedDestination = index;
    notifyListeners();
  }

  void selectWordDestination(int index) {
    _selectedWordDestination = index;
    notifyListeners();
  }

  void beginTemplate(PlanTemplate template) {
    _templateToCreate = template;
    _planToEdit = null;
    _selectedDestination = 1;
    _selectedWordDestination = 1;
    notifyListeners();
  }

  void beginCustomPlan() {
    _templateToCreate = null;
    _planToEdit = null;
    _selectedDestination = 1;
    _selectedWordDestination = 1;
    notifyListeners();
  }

  void beginEditPlan(ReadingPlan plan) {
    _templateToCreate = null;
    _planToEdit = plan;
    _selectedDestination = 1;
    _selectedWordDestination = 1;
    notifyListeners();
  }

  void clearCreateSelection() {
    _templateToCreate = null;
    _planToEdit = null;
  }

  Future<void> savePlan(ReadingPlan plan) async {
    _plans = <ReadingPlan>[plan, ..._plans.where((item) => item.id != plan.id)];
    await repository.savePlans(_plans);
    _selectedDestination = 1;
    _selectedWordDestination = 0;
    clearCreateSelection();
    notifyListeners();
  }

  Future<void> toggleReading(String planId, int assignmentIndex) async {
    final planIndex = _plans.indexWhere((plan) => plan.id == planId);
    if (planIndex == -1) return;

    final plan = _plans[planIndex];
    final assignments = List<ScheduledReading>.from(plan.assignments);
    final current = assignments[assignmentIndex];
    assignments[assignmentIndex] = current.copyWith(
      completed: !current.completed,
    );
    _plans[planIndex] = plan.copyWith(assignments: assignments);
    await repository.savePlans(_plans);
    notifyListeners();
  }

  Future<void> setReadingTranslation(
    String planId,
    int assignmentIndex,
    BibleTranslation translation,
  ) async {
    final planIndex = _plans.indexWhere((plan) => plan.id == planId);
    if (planIndex == -1) return;

    final plan = _plans[planIndex];
    final assignments = List<ScheduledReading>.from(plan.assignments);
    assignments[assignmentIndex] = assignments[assignmentIndex].copyWith(
      translationOverride: translation,
    );
    _plans[planIndex] = plan.copyWith(assignments: assignments);
    await repository.savePlans(_plans);
    notifyListeners();
  }

  Future<void> installTranslation(BibleTranslation translation) async {
    final availability = translationAvailability(translation);
    if (!availability.canInstall) {
      throw TranslationInstallationException(
        'not_downloadable',
        '${translation.shortLabel} does not support an offline download.',
      );
    }
    await versionRepository.install(
      translation,
      onStateChanged: (state) {
        _translationInstallations = {
          ..._translationInstallations,
          translation: state,
        };
        notifyListeners();
      },
    );
  }

  bool isTranslationInstalled(BibleTranslation translation) =>
      isTranslationUsable(translation);

  bool isTranslationUsable(BibleTranslation translation) =>
      translationAvailability(translation).isUsable;

  TranslationAvailability translationAvailability(
    BibleTranslation translation,
  ) {
    final definition = translation.definition;
    if (definition.supportsOfflineDownload) {
      final state =
          _translationInstallations[translation] ??
          const TranslationInstallationState.notInstalled();
      final kind = switch (state.status) {
        TranslationInstallationStatus.notInstalled =>
          TranslationAvailabilityKind.downloadAvailable,
        TranslationInstallationStatus.downloading =>
          TranslationAvailabilityKind.downloading,
        TranslationInstallationStatus.processing =>
          TranslationAvailabilityKind.processing,
        TranslationInstallationStatus.installed =>
          TranslationAvailabilityKind.installedOffline,
        TranslationInstallationStatus.failed =>
          TranslationAvailabilityKind.failed,
      };
      return TranslationAvailability(
        definition: definition,
        kind: kind,
        progress: state.progress,
        failureCode: state.failureCode,
      );
    }

    final onlineAvailable = nltOnlineConfigured;
    return TranslationAvailability(
      definition: definition,
      kind: onlineAvailable
          ? TranslationAvailabilityKind.online
          : TranslationAvailabilityKind.setupRequired,
    );
  }

  SchedulePreview previewCatchUpPlan(String planId, {DateTime? fromDate}) {
    final index = _plans.indexWhere((plan) => plan.id == planId);
    if (index == -1) throw ArgumentError('The plan no longer exists.');

    final plan = _plans[index];
    final effectiveDate = fromDate ?? DateTime.now();
    final assignments = _scheduler.redistributeRemaining(
      plan: plan,
      fromDate: effectiveDate,
    );
    final unfinishedCount = plan.assignments
        .where((item) => !item.completed)
        .length;
    final start = DateTime(
      effectiveDate.year,
      effectiveDate.month,
      effectiveDate.day,
    );
    final eligibleDays = <DateTime>[];
    for (
      var day = start;
      !day.isAfter(plan.endDate);
      day = day.add(const Duration(days: 1))
    ) {
      if (plan.readingWeekdays.contains(day.weekday)) eligibleDays.add(day);
    }
    return SchedulePreview(
      planId: plan.id,
      assignments: assignments,
      unfinishedReadingCount: unfinishedCount,
      eligibleDayCount: eligibleDays.length,
      targetEndDate: plan.endDate,
    );
  }

  Future<void> applyCatchUpPreview(SchedulePreview preview) async {
    final index = _plans.indexWhere((plan) => plan.id == preview.planId);
    if (index == -1) throw ArgumentError('The plan no longer exists.');
    final plan = _plans[index];
    if (plan.endDate != preview.targetEndDate) {
      throw StateError('This plan changed. Preview Catch Me Up again.');
    }
    _plans[index] = plan.copyWith(assignments: preview.assignments);
    await repository.savePlans(_plans);
    notifyListeners();
  }

  /// Compatibility entry point for callers that already explicitly chose to
  /// apply Catch Me Up. Presentation should show [previewCatchUpPlan] first.
  Future<void> catchUpPlan(String planId, {DateTime? fromDate}) async {
    final preview = previewCatchUpPlan(planId, fromDate: fromDate);
    await applyCatchUpPreview(preview);
  }

  Future<void> deletePlan(String planId) async {
    _plans = _plans.where((plan) => plan.id != planId).toList();
    await repository.savePlans(_plans);
    notifyListeners();
  }
}
