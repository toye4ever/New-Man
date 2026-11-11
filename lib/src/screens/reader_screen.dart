import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../controllers/app_controller.dart';
import '../features/word/audio/application/audio_preferences_repository.dart';
import '../features/word/audio/application/bible_audio_service.dart';
import '../features/word/bible/application/bible_reader_request.dart';
import '../features/word/bible/domain/bible_chapter_navigation.dart';
import '../features/word/bible/domain/reference_parser.dart';
import '../features/word/bible/domain/scripture_anchor.dart';
import '../features/word/bible/domain/scripture_reference.dart';
import '../features/word/saved_scripture/domain/saved_scripture.dart';
import '../features/word/translations/domain/translation_state.dart';
import '../models/reading_plan.dart';
import '../services/bible_version_repository.dart';
import '../services/scripture_service.dart';
import '../services/tts_service.dart';
import '../features/word/audio/presentation/playback_speed_selector.dart';
import '../features/word/bible/application/scripture_search.dart';
import '../features/word/bible/presentation/scripture_search_results_screen.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({
    required this.controller,
    required this.request,
    this.audio,
    this.scriptureRepositoryFactory,
    this.search,
    super.key,
  });
  final AppController controller;
  final BibleReaderRequest request;
  final BibleAudioService? audio;
  final ScriptureRepository Function(BibleTranslation translation)?
  scriptureRepositoryFactory;
  final ScriptureSearch? search;
  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final _navigation = const BibleChapterNavigation();
  final _parser = ReferenceParser();
  final _goToController = TextEditingController();
  final _goToFocusNode = FocusNode();
  final _goToRegionGroup = Object();
  final _scrollController = ScrollController();
  final _verseKeys = <int, GlobalKey>{};
  late final BibleAudioService _audio;
  late BibleTranslation _translation;
  late List<ScriptureReference> _queue;
  late Future<List<ScriptureTextResult>> _passagesFuture;
  int _queueIndex = 0;
  final SplayTreeSet<int> _selected = SplayTreeSet<int>();
  List<ScriptureHighlight> _highlights = const [];
  ScriptureReference? _goToTarget;
  bool _showGoTo = false;
  String? _goToError;
  double _speechRate = .45;
  String? _voiceKey;
  List<TtsVoiceOption> _voices = const [];
  int? _narratedVerse;
  List<_Verse> _chapterNarrationVerses = const [];
  int? _narrationCursor;
  int _narrationGeneration = 0;
  _NarrationPhase _narrationPhase = _NarrationPhase.idle;
  _ChapterRepeat _chapterRepeat = _ChapterRepeat.off;
  bool _copied = false;
  Timer? _copiedTimer;
  Timer? _targetTimer;
  bool _autoFollowNarration = true;
  late final ScriptureSearch _search;
  int _searchGeneration = 0;
  bool _planDetached = false;
  bool _hideHeader = false;
  bool _savingProgress = false;
  final _optionsRevision = ValueNotifier<int>(0);

  // A modal route is outside this State's subtree, so it needs its own signal
  // whenever the Reader's live playback/settings state changes.
  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    _optionsRevision.value++;
  }

  bool get _mobile => MediaQuery.sizeOf(context).width < 600;
  bool _revealPending = false;
  int _revealAttempts = 0;
  bool get _isPlanReader =>
      widget.request.planProgress != null && !_planDetached;
  ScriptureReference get _current => _queue[_queueIndex];
  bool get _finalPlanChapter =>
      _isPlanReader && _queueIndex == _queue.length - 1;
  bool get _hasSelection => _selected.isNotEmpty;
  List<_VerseRun> get _runs => _VerseRun.fromSelected(_selected);
  bool get _noteSupported => _hasSelection;
  ScheduledReading? get _progressReading {
    final target = widget.request.planProgress;
    if (target == null) return null;
    final plan = widget.controller.plans
        .where((p) => p.id == target.planId)
        .firstOrNull;
    return plan == null || target.assignmentIndex >= plan.assignments.length
        ? null
        : plan.assignments[target.assignmentIndex];
  }

  @override
  void initState() {
    super.initState();
    _search =
        widget.search ?? ScriptureSearch(KjvScriptureService().searchVerses);
    _audio = widget.audio ?? TtsService();
    widget.controller.addListener(_onControllerChanged);
    _goToFocusNode.addListener(_onGoToFocusChanged);
    _translation = widget.request.initialTranslation;
    _queue = _chapterQueue(widget.request.references);
    _queueIndex = widget.request.initialChapterIndex.clamp(
      0,
      _queue.length - 1,
    );
    _goToTarget = widget.request.goToTarget;
    _revealPending = _goToTarget != null;
    _showGoTo = widget.request.expandGoTo;
    _passagesFuture = _loadCurrent();
    unawaited(_loadAudioPreferences());
    unawaited(_persistPosition());
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _goToFocusNode.removeListener(_onGoToFocusChanged);
    _copiedTimer?.cancel();
    _targetTimer?.cancel();
    unawaited(_audio.stop());
    _goToController.dispose();
    _goToFocusNode.dispose();
    _scrollController.dispose();
    _optionsRevision.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _onGoToFocusChanged() {
    if (mounted && !_goToFocusNode.hasFocus && _showGoTo) {
      setState(() => _showGoTo = false);
    }
  }

  void _toggleGoTo() {
    if (_showGoTo) {
      _goToFocusNode.unfocus();
      setState(() => _showGoTo = false);
      return;
    }
    setState(() => _showGoTo = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _showGoTo) _goToFocusNode.requestFocus();
    });
  }

  Future<void> _loadAudioPreferences() async {
    final prefs = await widget.controller.audioPreferencesRepository.load();
    final voices = await _audio.getVoices();
    final selected = voices.any((v) => v.key == prefs.voiceKey)
        ? prefs.voiceKey
        : voices.firstOrNull?.key;
    if (selected != null) {
      await _audio.setVoice(voices.firstWhere((v) => v.key == selected));
    }
    if (mounted) {
      setState(() {
        _speechRate = prefs.playbackRate;
        _voices = voices;
        _voiceKey = selected;
      });
    }
  }

  Future<List<ScriptureTextResult>> _loadCurrent() async {
    final availability = widget.controller.translationAvailability(
      _translation,
    );
    if (!availability.isUsable) {
      throw ScriptureUnavailableException(_unavailableMessage(availability));
    }
    final service =
        widget.scriptureRepositoryFactory?.call(_translation) ??
        scriptureServiceFor(_translation);
    final requested = _current;
    final result = await service.getPassage(requested);
    if (!mounted || requested != _current) return [result];
    final planTarget = widget.request.planProgress;
    if (_isPlanReader && planTarget != null) {
      await widget.controller.recordPlanReading(
        planTarget.planId,
        planTarget.assignmentIndex,
        requested,
      );
    }
    final all = await widget.controller.savedScriptureRepository
        .loadHighlights();
    await widget.controller.savedScriptureRepository.recordSuccessfulOpen(
      _anchorFor(_current),
    );
    if (mounted) {
      setState(
        () => _highlights = all
            .where(
              (h) =>
                  h.anchor.book == _current.book &&
                  h.anchor.chapter == _current.startChapter,
            )
            .toList(),
      );
    }
    return [result];
  }

  void _scheduleGoToReveal() {
    if (!_revealPending || _goToTarget?.startVerse == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_revealPending) return;
      final c = _verseKeys[_goToTarget!.startVerse]?.currentContext;
      if (c == null) {
        if (++_revealAttempts < 3) _scheduleGoToReveal();
        return;
      }
      _revealPending = false;
      Scrollable.ensureVisible(
        c,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      _targetTimer?.cancel();
      _targetTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _goToTarget = null);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final availability = widget.controller.translationAvailability(
      _translation,
    );
    final target = widget.request.planProgress;
    final plan = _isPlanReader
        ? widget.controller.plans
              .where((p) => p.id == target!.planId)
              .firstOrNull
        : null;
    return Scaffold(
      appBar: _mobile && (_hideHeader || _hasSelection) && !_showGoTo
          ? null
          : AppBar(
              leading: _mobile
                  ? IconButton(
                      tooltip: 'Bible books',
                      onPressed: _savingProgress ? null : _returnToBooks,
                      icon: const Icon(Icons.close),
                    )
                  : null,
              title: plan != null && _mobile
                  ? TextButton(
                      onPressed: _savingProgress
                          ? null
                          : () => Navigator.maybePop(context),
                      child: Text(
                        '${plan.title} · Day ${target!.assignmentIndex + 1}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  : Text(
                      plan == null
                          ? _current.display
                          : '${plan.title} · Day ${target!.assignmentIndex + 1}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
      body: FutureBuilder<List<ScriptureTextResult>>(
        future: _passagesFuture,
        builder: (context, snapshot) {
          final passage = snapshot.data?.singleOrNull;
          return Column(
            children: [
              if (!_mobile) ...[
                if (_narrationPhase != _NarrationPhase.idle) _miniPlayer(),
                _toolbar(availability, passage),
              ],
              if (_showGoTo) _goToField(),
              Expanded(child: _readingBody(snapshot)),
            ],
          );
        },
      ),
      bottomNavigationBar: !_mobile
          ? null
          : FutureBuilder<List<ScriptureTextResult>>(
              future: _passagesFuture,
              builder: (context, snapshot) {
                final passage = snapshot.data?.singleOrNull;
                return SafeArea(
                  top: false,
                  child: _hasSelection
                      ? _selectionActions(
                          passage == null ? [] : _versesFor(passage.text),
                        )
                      : _mobileDock(passage),
                );
              },
            ),
    );
  }

  void _returnToBooks() {
    widget.controller.selectDestination(1);
    widget.controller.selectWordDestination(2);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Widget _mobileDock(ScriptureTextResult? passage) {
    final left = _isPlanReader
        ? (_queueIndex == 0 ? null : _queue[_queueIndex - 1])
        : _navigation.previousChapter(_current);
    final right = _isPlanReader
        ? (_queueIndex + 1 < _queue.length ? _queue[_queueIndex + 1] : null)
        : _navigation.nextChapter(_current);
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          children: [
            IconButton(
              tooltip: _isPlanReader && _queueIndex == 0
                  ? 'Back to plan'
                  : 'Previous chapter',
              onPressed: _savingProgress
                  ? null
                  : _isPlanReader && _queueIndex == 0
                  ? () => Navigator.maybePop(context)
                  : left == null
                  ? null
                  : () => _moveTo(left),
              icon: Icon(
                _isPlanReader && _queueIndex == 0
                    ? Icons.close
                    : Icons.chevron_left,
              ),
            ),
            Expanded(
              child: TextButton(
                onPressed: _openReaderOptions,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _current.display,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      _translation.shortLabel,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              tooltip: _finalPlanChapter
                  ? 'Complete chapter and finish day'
                  : _isPlanReader
                  ? 'Complete chapter and continue'
                  : 'Next chapter',
              onPressed:
                  _savingProgress ||
                      passage == null ||
                      (!_isPlanReader && right == null)
                  ? null
                  : () => _advance(right),
              icon: _savingProgress
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(_finalPlanChapter ? Icons.check : Icons.chevron_right),
            ),
            Tooltip(
              message: _narrationPhase == _NarrationPhase.playing
                  ? 'Pause narration'
                  : 'Play narration',
              triggerMode: TooltipTriggerMode.manual,
              child: GestureDetector(
                onLongPress: _openReaderOptions,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          value:
                              _narrationCursor == null ||
                                  _chapterNarrationVerses.isEmpty
                              ? 0
                              : (_narrationCursor! + 1) /
                                    _chapterNarrationVerses.length,
                        ),
                      ),
                      IconButton(
                        onPressed: passage == null
                            ? null
                            : () {
                                if (_narrationPhase ==
                                    _NarrationPhase.playing) {
                                  unawaited(_pauseNarration());
                                } else if (_narrationPhase ==
                                    _NarrationPhase.paused) {
                                  unawaited(_resumeNarration());
                                } else {
                                  unawaited(
                                    _beginNarration(
                                      _versesFor(passage.text),
                                      0,
                                    ),
                                  );
                                }
                              },
                        icon: Icon(
                          _narrationPhase == _NarrationPhase.playing
                              ? Icons.pause
                              : Icons.play_arrow,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Go to Scripture',
              onPressed: _toggleGoTo,
              icon: const Icon(Icons.search),
            ),
            IconButton(
              tooltip: 'Reading options',
              onPressed: _openReaderOptions,
              icon: const Icon(Icons.more_horiz),
            ),
          ],
        ),
      ),
    );
  }

  void _openReaderOptions() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => ValueListenableBuilder<int>(
        valueListenable: _optionsRevision,
        builder: (_, revision, child) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(child: Text('Translation')),
                    DropdownButton<BibleTranslation>(
                      value: _translation,
                      items: BibleTranslation.values
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              enabled: widget.controller.isTranslationUsable(t),
                              child: Text(t.shortLabel),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          Navigator.pop(sheetContext);
                          unawaited(_changeTranslation(v));
                        }
                      },
                    ),
                  ],
                ),
                if (widget.controller
                    .translationAvailability(_translation)
                    .canInstall)
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      unawaited(_installSelectedTranslation());
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Download KJV'),
                  ),
                _miniPlayer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _advance(ScriptureReference? right) async {
    if (_savingProgress) return;
    setState(() => _savingProgress = true);
    try {
      final target = widget.request.planProgress;
      if (_isPlanReader && target != null) {
        await widget.controller.completePlanChapter(
          target.planId,
          target.assignmentIndex,
          _current,
        );
      }
      if (!mounted) return;
      if (_finalPlanChapter) {
        await _stopAudio();
        if (mounted) Navigator.pop(context);
      } else if (right != null) {
        await _moveTo(right);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save reading progress. Please retry.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _savingProgress = false);
    }
  }

  Widget _toolbar(
    TranslationAvailability availability,
    ScriptureTextResult? passage,
  ) {
    final left = _isPlanReader
        ? (_queueIndex == 0 ? null : _queue[_queueIndex - 1])
        : _navigation.previousChapter(_current);
    final right = _isPlanReader
        ? (_queueIndex + 1 < _queue.length ? _queue[_queueIndex + 1] : null)
        : _navigation.nextChapter(_current);
    return Material(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TapRegion(
              groupId: _goToRegionGroup,
              child: IconButton(
                tooltip: 'Go to Scripture',
                onPressed: _toggleGoTo,
                icon: const Icon(Icons.search),
              ),
            ),
            SizedBox(
              width: MediaQuery.sizeOf(context).width < 600
                  ? (MediaQuery.sizeOf(context).width - 120) / 2
                  : 170,
              child: OutlinedButton.icon(
                onPressed: _isPlanReader && _queueIndex == 0
                    ? () => Navigator.maybePop(context)
                    : left == null
                    ? null
                    : () => _moveTo(left),
                icon: const Icon(Icons.arrow_back),
                label: Text(
                  _isPlanReader && _queueIndex == 0
                      ? 'Back to Plan'
                      : left?.display ?? 'First chapter',
                ),
              ),
            ),
            SizedBox(
              width: MediaQuery.sizeOf(context).width < 600
                  ? (MediaQuery.sizeOf(context).width - 120) / 2
                  : 170,
              child: _finalPlanChapter
                  ? FilledButton.icon(
                      onPressed: _savingProgress ? null : _completePlan,
                      icon: const Icon(Icons.check),
                      label: Text(
                        _progressReading?.completed == true
                            ? 'Finish reading'
                            : 'Complete',
                      ),
                    )
                  : OutlinedButton.icon(
                      onPressed: right == null || _savingProgress
                          ? null
                          : () => _advance(right),
                      iconAlignment: IconAlignment.end,
                      icon: const Icon(Icons.arrow_forward),
                      label: Text(right?.display ?? 'Last chapter'),
                    ),
            ),
            const SizedBox(width: 8),
            DropdownButton<BibleTranslation>(
              value: _translation,
              selectedItemBuilder: (_) => BibleTranslation.values
                  .map(
                    (t) => Align(
                      alignment: Alignment.centerLeft,
                      child: Text(t.shortLabel),
                    ),
                  )
                  .toList(),
              items: BibleTranslation.values.map((t) {
                final s = widget.controller.translationAvailability(t);
                return DropdownMenuItem(
                  value: t,
                  enabled: s.kind != TranslationAvailabilityKind.setupRequired,
                  child: Text('${t.shortLabel} — ${s.shortStatus}'),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) unawaited(_changeTranslation(v));
              },
            ),
            if (availability.canInstall)
              FilledButton.tonalIcon(
                onPressed: () => unawaited(_installSelectedTranslation()),
                icon: Icon(
                  availability.kind == TranslationAvailabilityKind.failed
                      ? Icons.refresh
                      : Icons.download_outlined,
                ),
                label: Text(
                  availability.kind == TranslationAvailabilityKind.failed
                      ? 'Retry KJV'
                      : 'Download KJV',
                ),
              ),
            if (availability.isBusy)
              SizedBox(
                width: 80,
                child: LinearProgressIndicator(value: availability.progress),
              ),
            FilledButton.icon(
              onPressed:
                  passage != null && _narrationPhase == _NarrationPhase.idle
                  ? () =>
                        unawaited(_beginNarration(_versesFor(passage.text), 0))
                  : null,
              icon: Icon(
                _narrationPhase == _NarrationPhase.idle
                    ? Icons.play_arrow
                    : Icons.graphic_eq,
              ),
              label: Text(
                _narrationPhase == _NarrationPhase.paused
                    ? 'Paused'
                    : _narrationPhase == _NarrationPhase.playing
                    ? 'Reading…'
                    : 'Listen',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _goToField() => TapRegion(
    groupId: _goToRegionGroup,
    onTapOutside: (_) => _goToFocusNode.unfocus(),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        controller: _goToController,
        focusNode: _goToFocusNode,
        autofocus: true,
        textInputAction: TextInputAction.go,
        onSubmitted: (_) => _goTo(),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.menu_book_outlined),
          suffixIcon: IconButton(
            tooltip: 'Go',
            icon: const Icon(Icons.arrow_forward),
            onPressed: _goTo,
          ),
          labelText: 'Go to Scripture',
          hintText: 'Philippians 4:8, a quotation, or a topic',
          errorText: _goToError,
          border: const OutlineInputBorder(),
        ),
      ),
    ),
  );
  Widget _readingBody(AsyncSnapshot<List<ScriptureTextResult>> snapshot) {
    if (snapshot.connectionState != ConnectionState.done) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snapshot.hasError) {
      return _ErrorState(
        message: snapshot.error.toString(),
        onRetry: () => setState(() => _passagesFuture = _loadCurrent()),
      );
    }
    final passage = snapshot.data!.single;
    final verses = _versesFor(passage.text);
    _scheduleGoToReveal();
    return Stack(
      children: [
        NotificationListener<UserScrollNotification>(
          onNotification: (notification) {
            if (_mobile && notification.direction != ScrollDirection.idle) {
              final hide = notification.direction == ScrollDirection.reverse;
              if (hide != _hideHeader) setState(() => _hideHeader = hide);
            }
            if (_narrationPhase != _NarrationPhase.idle &&
                notification.direction != ScrollDirection.idle &&
                _autoFollowNarration) {
              setState(() => _autoFollowNarration = false);
            }
            return false;
          },
          child: ListView(
            controller: _scrollController,
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              24 + MediaQuery.viewPaddingOf(context).bottom,
            ),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        passage.reference,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      if (passage.notice != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(passage.notice!),
                        ),
                      const SizedBox(height: 16),
                      for (final verse in verses) _verseTile(verse),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_hasSelection && !_mobile)
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _selectionActions(verses),
              ),
            ),
          ),
      ],
    );
  }

  Widget _verseTile(_Verse verse) {
    final selected = _selected.contains(verse.number);
    final target =
        _goToTarget != null &&
        verse.number >= (_goToTarget!.startVerse ?? 1) &&
        verse.number <= (_goToTarget!.endVerse ?? _goToTarget!.startVerse ?? 1);
    final saved = _highlightForVerse(verse.number);
    return GestureDetector(
      onTap: () {
        _goToFocusNode.unfocus();
        _toggleVerse(verse.number);
      },
      child: Opacity(
        opacity: _mobile && _hasSelection && !selected ? .35 : 1,
        child: Container(
          key: _verseKeys.putIfAbsent(verse.number, GlobalKey.new),
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            color: saved == null
                ? (target
                      ? Theme.of(
                          context,
                        ).colorScheme.tertiaryContainer.withValues(alpha: .55)
                      : null)
                : _highlightColor(saved.style).withValues(alpha: .32),
            border: target
                ? Border.all(
                    color: Theme.of(context).colorScheme.tertiary,
                    width: 2,
                  )
                : selected
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  )
                : verse.number == _narratedVerse
                ? Border(
                    bottom: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  )
                : null,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '${verse.number} ${verse.text}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.7),
          ),
        ),
      ),
    );
  }

  ScriptureHighlight? _highlightForVerse(int verse) => _highlights
      .where(
        (h) =>
            h.anchor.startVerse != null &&
            verse >= h.anchor.startVerse! &&
            verse <= (h.anchor.endVerse ?? h.anchor.startVerse!),
      )
      .firstOrNull;
  Widget _selectionActions(List<_Verse> verses) => _mobile
      ? Material(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                tooltip: 'Listen from here',
                onPressed: () => unawaited(_listenFromSelection(verses)),
                icon: const Icon(Icons.play_arrow),
              ),
              IconButton(
                tooltip: 'Highlight',
                onPressed: () => unawaited(_chooseHighlight()),
                icon: const Icon(Icons.highlight_alt),
              ),
              IconButton(
                tooltip: 'Note',
                onPressed: () => unawaited(_editNote()),
                icon: const Icon(Icons.note_add_outlined),
              ),
              IconButton(
                tooltip: 'Bookmark',
                onPressed: () => unawaited(_toggleBookmark()),
                icon: const Icon(Icons.bookmark_add_outlined),
              ),
              IconButton(
                tooltip: 'Copy',
                onPressed: () => _copySelection(verses),
                icon: const Icon(Icons.content_copy),
              ),
              IconButton(
                tooltip: 'Clear selection',
                onPressed: _clearSelection,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        )
      : Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Wrap(
              spacing: 2,
              children: [
                TextButton.icon(
                  onPressed: () => unawaited(_listenFromSelection(verses)),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Listen from here'),
                ),
                TextButton.icon(
                  onPressed: () => unawaited(_chooseHighlight()),
                  icon: const Icon(Icons.highlight_alt),
                  label: const Text('Highlight'),
                ),
                TextButton.icon(
                  onPressed: _noteSupported
                      ? () => unawaited(_editNote())
                      : null,
                  icon: const Icon(Icons.note_add_outlined),
                  label: const Text('Note'),
                ),
                TextButton.icon(
                  onPressed: () => unawaited(_toggleBookmark()),
                  icon: const Icon(Icons.bookmark_add_outlined),
                  label: const Text('Bookmark'),
                ),
                TextButton.icon(
                  onPressed: () => _copySelection(verses),
                  icon: const Icon(Icons.content_copy),
                  label: Text(_copied ? 'Copied!' : 'Copy'),
                ),
                IconButton(
                  tooltip: 'Clear selection',
                  onPressed: _clearSelection,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
        );
  Widget _miniPlayer() {
    final cursor = _narrationCursor;
    final verse = cursor == null ? null : _chapterNarrationVerses[cursor];
    final paused = _narrationPhase == _NarrationPhase.paused;
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_current.display} · Verse ${verse?.number ?? '-'} of ${_chapterNarrationVerses.length}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Align(
              alignment: Alignment.center,
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Previous verse',
                    onPressed: cursor == null || cursor == 0
                        ? null
                        : () => unawaited(_stepNarration(-1)),
                    icon: const Icon(Icons.skip_previous),
                  ),
                  IconButton(
                    tooltip: paused ? 'Resume reading' : 'Pause at this verse',
                    onPressed: paused
                        ? () => unawaited(_resumeNarration())
                        : () => unawaited(_pauseNarration()),
                    icon: Icon(paused ? Icons.play_arrow : Icons.pause),
                  ),
                  IconButton(
                    tooltip: 'Next verse',
                    onPressed:
                        cursor == null ||
                            cursor == _chapterNarrationVerses.length - 1
                        ? null
                        : () => unawaited(_stepNarration(1)),
                    icon: const Icon(Icons.skip_next),
                  ),
                  IconButton(
                    tooltip: _chapterRepeat.label,
                    onPressed: cursor == null ? null : _cycleChapterRepeat,
                    icon: Icon(_chapterRepeat.icon),
                  ),
                  PlaybackSpeedSelector(
                    rate: _speechRate,
                    onChanged: (v) => unawaited(_changeRate(v)),
                  ),
                  if (_voices.isNotEmpty)
                    SizedBox(
                      width: 135,
                      child: DropdownButton<String>(
                        isExpanded: true,
                        isDense: true,
                        value: _voiceKey,
                        items: _voices
                            .map(
                              (v) => DropdownMenuItem(
                                value: v.key,
                                child: Text(
                                  v.label,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) unawaited(_changeVoice(v));
                        },
                      ),
                    ),
                  if (!_autoFollowNarration)
                    TextButton.icon(
                      onPressed: _restoreNarrationFollow,
                      icon: const Icon(Icons.my_location),
                      label: const Text('Follow reading'),
                    ),
                  IconButton(
                    tooltip: 'Close player',
                    onPressed: () => unawaited(_stopAudio()),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleVerse(int verse) => setState(() {
    _selected.contains(verse) ? _selected.remove(verse) : _selected.add(verse);
    _resetCopied();
  });
  void _clearSelection() => setState(() {
    _selected.clear();
    _resetCopied();
  });
  void _resetCopied() {
    _copiedTimer?.cancel();
    _copied = false;
  }

  Future<void> _copySelection(List<_Verse> verses) async {
    final chosen = verses.where((v) => _selected.contains(v.number)).toList();
    final label = _runs.map((r) => r.anchor(_current).display).join(', ');
    await Clipboard.setData(
      ClipboardData(
        text:
            '$label\n${chosen.map((v) => '${v.number} ${v.text}').join('\n')}',
      ),
    );
    if (!mounted) return;
    setState(() => _copied = true);
    _copiedTimer?.cancel();
    _copiedTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _toggleBookmark() async {
    final r = widget.controller.savedScriptureRepository;
    for (final a in _runs.map((run) => run.anchor(_current))) {
      if (await r.isBookmarked(a)) {
        await r.removeBookmark(a);
      } else {
        await r.saveBookmark(a);
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _chooseHighlight() async {
    final style = await showModalBottomSheet<HighlightStyle>(
      context: context,
      builder: (c) => SafeArea(
        child: Wrap(
          children: [
            for (final s in HighlightStyle.values)
              ListTile(title: Text(s.label), onTap: () => Navigator.pop(c, s)),
          ],
        ),
      ),
    );
    if (style == null) return;
    for (final a in _runs.map((run) => run.anchor(_current))) {
      await widget.controller.savedScriptureRepository.saveHighlight(a, style);
    }
    await _reloadHighlights();
  }

  Future<void> _reloadHighlights() async {
    final all = await widget.controller.savedScriptureRepository
        .loadHighlights();
    if (mounted) {
      setState(
        () => _highlights = all
            .where(
              (h) =>
                  h.anchor.book == _current.book &&
                  h.anchor.chapter == _current.startChapter,
            )
            .toList(),
      );
    }
  }

  Future<void> _editNote() async {
    if (!_noteSupported) return;
    final text = TextEditingController();
    final anchors = _runs.map((run) => run.anchor(_current)).toList();
    final save = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(
          'Private note — ${anchors.map((a) => a.display).join(', ')}',
        ),
        content: TextField(controller: text, minLines: 3, maxLines: 8),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (save == true && text.text.trim().isNotEmpty) {
      final now = DateTime.now().toUtc();
      await widget.controller.savedScriptureRepository.saveNote(
        ScriptureNote(
          id: 'note-${now.microsecondsSinceEpoch}',
          anchors: anchors,
          body: text.text.trim(),
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
    text.dispose();
  }

  Future<void> _goTo() async {
    final query = _goToController.text.trim();
    if (query.isEmpty) {
      setState(() => _goToError = 'Enter a reference, quotation, or topic.');
      return;
    }
    final generation = ++_searchGeneration;
    final parsed = _parser.parse(query);
    if (parsed.isValid && parsed.references.length == 1) {
      await _openSearchResult(
        ScriptureSearchResult(parsed.references.single, ''),
      );
      return;
    }
    _goToFocusNode.unfocus();
    setState(() {
      _showGoTo = false;
      _goToError = null;
    });
    final result = await Navigator.of(context).push<ScriptureSearchResult>(
      MaterialPageRoute(
        builder: (_) =>
            ScriptureSearchResultsScreen(query: query, search: _search),
      ),
    );
    if (!mounted || generation != _searchGeneration) return;
    if (result != null) {
      await _openSearchResult(result);
    } else {
      setState(() => _showGoTo = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _goToFocusNode.requestFocus();
      });
    }
  }

  Future<void> _openSearchResult(ScriptureSearchResult result) async {
    final target = result.reference;
    await _stopAudio();
    if (!mounted) return;
    _searchGeneration++;
    _targetTimer?.cancel();
    setState(() {
      _planDetached = true;
      _queue = [
        ScriptureReference(
          book: target.book,
          startChapter: target.startChapter,
        ),
      ];
      _queueIndex = 0;
      _goToTarget = target.startVerse == null ? null : target;
      _revealPending = _goToTarget != null;
      _revealAttempts = 0;
      _selected.clear();
      _goToError = null;
      _showGoTo = false;
      _passagesFuture = _loadCurrent();
    });
    await _persistPosition();
  }

  Future<void> _moveTo(ScriptureReference reference) async {
    await _stopAudio();
    if (!mounted) return;
    final index = _queue.indexWhere(
      (r) =>
          r.book == reference.book && r.startChapter == reference.startChapter,
    );
    _targetTimer?.cancel();
    setState(() {
      if (_isPlanReader && index >= 0) {
        _queueIndex = index;
      } else {
        _planDetached = true;
        _queue = [reference];
        _queueIndex = 0;
      }
      _selected.clear();
      _goToTarget = null;
      _passagesFuture = _loadCurrent();
    });
    await _persistPosition();
  }

  Future<void> _completePlan() async {
    await _advance(null);
  }

  Future<void> _changeTranslation(BibleTranslation value) async {
    await _stopAudio();
    setState(() {
      _translation = value;
      _passagesFuture = _loadCurrent();
    });
    await _persistPosition();
    final t = widget.request.planProgress;
    if (_isPlanReader &&
        t != null &&
        widget.controller.isTranslationUsable(value)) {
      await widget.controller.setReadingTranslation(
        t.planId,
        t.assignmentIndex,
        value,
      );
    }
  }

  Future<void> _installSelectedTranslation() async {
    try {
      await widget.controller.installTranslation(_translation);
      if (mounted) setState(() => _passagesFuture = _loadCurrent());
    } on TranslationInstallationException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _changeVoice(String key) async {
    final voice = _voices.firstWhere((v) => v.key == key);
    final restart = _narrationPhase == _NarrationPhase.playing;
    final cursor = _narrationCursor;
    if (restart) {
      final generation = ++_narrationGeneration;
      await _audio.stop();
      if (generation != _narrationGeneration) return;
    }
    await _audio.setVoice(voice);
    _voiceKey = key;
    await _saveAudioPreferences();
    if (mounted) setState(() {});
    if (restart && cursor != null) unawaited(_startNarrationAt(cursor));
  }

  Future<void> _changeRate(double rate) async {
    final restart = _narrationPhase == _NarrationPhase.playing;
    final cursor = _narrationCursor;
    if (restart) {
      final generation = ++_narrationGeneration;
      await _audio.stop();
      if (generation != _narrationGeneration) return;
    }
    _speechRate = rate;
    await _audio.setRate(rate);
    await _saveAudioPreferences();
    if (mounted) setState(() {});
    if (restart && cursor != null) unawaited(_startNarrationAt(cursor));
  }

  Future<void> _saveAudioPreferences() => widget
      .controller
      .audioPreferencesRepository
      .save(AudioPreferences(voiceKey: _voiceKey, playbackRate: _speechRate));
  Future<void> _listenFromSelection(List<_Verse> verses) async {
    final index = verses.indexWhere((verse) => verse.number == _selected.first);
    if (index >= 0) await _beginNarration(verses, index);
  }

  Future<void> _beginNarration(List<_Verse> verses, int startIndex) async {
    final generation = ++_narrationGeneration;
    await _audio.stop();
    if (!mounted || generation != _narrationGeneration) return;
    _chapterNarrationVerses = verses;
    _autoFollowNarration = true;
    await _startNarrationAt(startIndex);
  }

  Future<void> _startNarrationAt(int startIndex) async {
    if (startIndex < 0 || startIndex >= _chapterNarrationVerses.length) return;
    final generation = ++_narrationGeneration;
    var nextStart = startIndex;
    var onceLooped = false;
    if (mounted) setState(() => _narrationPhase = _NarrationPhase.playing);
    try {
      while (mounted && generation == _narrationGeneration) {
        for (
          var index = nextStart;
          index < _chapterNarrationVerses.length;
          index++
        ) {
          if (!mounted || generation != _narrationGeneration) break;
          final verse = _chapterNarrationVerses[index];
          setState(() {
            _narrationCursor = index;
            _narratedVerse = verse.number;
          });
          _revealNarratedVerse(force: index == nextStart);
          await _audio.setRate(_speechRate);
          await _audio.speak('${verse.number}. ${verse.text}');
        }
        if (!mounted || generation != _narrationGeneration) break;
        if (_chapterRepeat == _ChapterRepeat.continuous) {
          nextStart = 0;
          continue;
        }
        if (_chapterRepeat == _ChapterRepeat.once && !onceLooped) {
          onceLooped = true;
          if (mounted) setState(() => _chapterRepeat = _ChapterRepeat.off);
          nextStart = 0;
          continue;
        }
        break;
      }
    } finally {
      if (mounted && generation == _narrationGeneration) {
        setState(() {
          _narratedVerse = null;
          _narrationCursor = null;
          _narrationPhase = _NarrationPhase.idle;
        });
      }
    }
  }

  Future<void> _pauseNarration() async {
    final cursor = _narrationCursor;
    if (cursor == null) return;
    final generation = ++_narrationGeneration;
    await _audio.stop();
    if (!mounted || generation != _narrationGeneration) return;
    setState(() => _narrationPhase = _NarrationPhase.paused);
  }

  Future<void> _resumeNarration() async {
    final cursor = _narrationCursor;
    if (_narrationPhase == _NarrationPhase.paused && cursor != null) {
      await _startNarrationAt(cursor);
    }
  }

  Future<void> _stepNarration(int delta) async {
    final cursor = _narrationCursor;
    if (cursor == null) return;
    final target = cursor + delta;
    if (target < 0 || target >= _chapterNarrationVerses.length) return;
    if (_narrationPhase == _NarrationPhase.paused) {
      setState(() {
        _narrationCursor = target;
        _narratedVerse = _chapterNarrationVerses[target].number;
      });
      _revealNarratedVerse(force: true);
      return;
    }
    final generation = ++_narrationGeneration;
    await _audio.stop();
    if (!mounted || generation != _narrationGeneration) return;
    await _startNarrationAt(target);
  }

  void _cycleChapterRepeat() {
    setState(
      () => _chapterRepeat = switch (_chapterRepeat) {
        _ChapterRepeat.off => _ChapterRepeat.once,
        _ChapterRepeat.once => _ChapterRepeat.continuous,
        _ChapterRepeat.continuous => _ChapterRepeat.off,
      },
    );
  }

  void _restoreNarrationFollow() {
    setState(() => _autoFollowNarration = true);
    _revealNarratedVerse(force: true);
  }

  void _revealNarratedVerse({bool force = false}) {
    final verse = _narratedVerse;
    if (verse == null || !_autoFollowNarration) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _verseKeys[verse]?.currentContext;
      if (!mounted || context == null || !_scrollController.hasClients) return;
      final renderObject = context.findRenderObject();
      final viewport = Scrollable.of(context).context.findRenderObject();
      if (renderObject is! RenderBox || viewport is! RenderBox) return;
      final bounds =
          renderObject.localToGlobal(Offset.zero, ancestor: viewport) &
          renderObject.size;
      final comfortableTop = viewport.size.height * .12;
      final comfortableBottom = viewport.size.height * .88;
      final visible =
          bounds.top >= comfortableTop && bounds.bottom <= comfortableBottom;
      if (force || !visible) {
        final owner = RenderAbstractViewport.of(renderObject);
        final target = owner.getOffsetToReveal(renderObject, .35).offset;
        final position = _scrollController.position;
        _scrollController.animateTo(
          target.clamp(position.minScrollExtent, position.maxScrollExtent),
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _stopAudio() async {
    _narrationGeneration++;
    await _audio.stop();
    if (mounted) {
      setState(() {
        _narratedVerse = null;
        _narrationCursor = null;
        _chapterNarrationVerses = const [];
        _narrationPhase = _NarrationPhase.idle;
        _chapterRepeat = _ChapterRepeat.off;
      });
    }
  }

  Future<void> _persistPosition() => widget.controller.saveReaderPosition(
    book: _current.book,
    chapter: _current.startChapter,
    translation: _translation,
  );
  ScriptureAnchor _anchorFor(ScriptureReference r) => ScriptureAnchor(
    book: r.book,
    chapter: r.startChapter,
    startVerse: r.startVerse,
    endVerse: r.endVerse,
  );
  String _unavailableMessage(TranslationAvailability s) => switch (s.kind) {
    TranslationAvailabilityKind.downloading =>
      '${_translation.shortLabel} is still downloading.',
    TranslationAvailabilityKind.processing =>
      '${_translation.shortLabel} is being verified and prepared.',
    TranslationAvailabilityKind.failed =>
      '${_translation.shortLabel} installation failed. Retry when ready.',
    TranslationAvailabilityKind.setupRequired =>
      '${_translation.shortLabel} is online-only and requires provider setup. No download is available.',
    _ => '${_translation.shortLabel} is not available yet.',
  };
}

List<ScriptureReference> _chapterQueue(
  Iterable<ScriptureReference> references,
) {
  final seen = <String>{};
  return [
    for (final r in references)
      for (var c = r.startChapter; c <= r.resolvedEndChapter; c++)
        if (seen.add('${r.book}:$c'))
          ScriptureReference(book: r.book, startChapter: c),
  ];
}

List<_Verse> _versesFor(String text) {
  final verses = <_Verse>[];
  for (final line in text.split(RegExp(r'\n+'))) {
    final m = RegExp(r'^\s*(\d+)\s+(.+)$').firstMatch(line.trim());
    if (m != null) verses.add(_Verse(int.parse(m.group(1)!), m.group(2)!));
  }
  return verses.isEmpty ? [_Verse(1, text)] : verses;
}

class _Verse {
  const _Verse(this.number, this.text);
  final int number;
  final String text;
}

enum _NarrationPhase { idle, playing, paused }

enum _ChapterRepeat { off, once, continuous }

extension on _ChapterRepeat {
  String get label => switch (this) {
    _ChapterRepeat.off => 'Repeat chapter off',
    _ChapterRepeat.once => 'Repeat chapter once',
    _ChapterRepeat.continuous => 'Repeat chapter continuously',
  };
  IconData get icon => switch (this) {
    _ChapterRepeat.off => Icons.repeat,
    _ChapterRepeat.once => Icons.repeat_one,
    _ChapterRepeat.continuous => Icons.repeat_on,
  };
}

class _VerseRun {
  const _VerseRun(this.first, this.last);
  final int first;
  final int last;
  ScriptureAnchor anchor(ScriptureReference r) => ScriptureAnchor(
    book: r.book,
    chapter: r.startChapter,
    startVerse: first,
    endVerse: last,
  );
  static List<_VerseRun> fromSelected(SplayTreeSet<int> selected) {
    final runs = <_VerseRun>[];
    int? first;
    int? previous;
    for (final verse in selected) {
      if (previous != null && verse != previous + 1) {
        runs.add(_VerseRun(first!, previous));
        first = verse;
      }
      first ??= verse;
      previous = verse;
    }
    if (first != null) runs.add(_VerseRun(first, previous!));
    return runs;
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}

Color _highlightColor(HighlightStyle s) => switch (s) {
  HighlightStyle.gold => Colors.amber,
  HighlightStyle.green => Colors.green,
  HighlightStyle.blue => Colors.blue,
  HighlightStyle.rose => Colors.pink,
};

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final i = iterator;
    return i.moveNext() ? i.current : null;
  }
}
