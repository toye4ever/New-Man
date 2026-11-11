import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../controllers/app_controller.dart';
import '../models/plan_template.dart';
import '../models/reading_plan.dart';
import '../models/reference_parse_result.dart';
import '../services/file_import_service.dart';
import '../services/plan_assistant_service.dart';
import '../services/plan_scheduler.dart';
import '../services/reference_parser.dart';
import '../services/reference_utils.dart';
import '../widgets/page_header.dart';
import '../widgets/responsive_content.dart';

class CreatePlanScreen extends StatefulWidget {
  const CreatePlanScreen({
    required this.controller,
    required this.template,
    required this.planToEdit,
    this.onSaved,
    super.key,
  });

  final AppController controller;
  final PlanTemplate? template;
  final ReadingPlan? planToEdit;
  final VoidCallback? onSaved;

  @override
  State<CreatePlanScreen> createState() => _CreatePlanScreenState();
}

class _CreatePlanScreenState extends State<CreatePlanScreen> {
  final _titleController = TextEditingController();
  final _passagesController = TextEditingController();
  final _assistantController = TextEditingController();
  final _parser = ReferenceParser();
  final _scheduler = PlanScheduler();
  final _importService = FileImportService();
  final _assistant = PlanAssistantService();

  late DateTime _startDate;
  late DateTime _endDate;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 7, minute: 0);
  Set<int> _weekdays = <int>{
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
    DateTime.saturday,
    DateTime.sunday,
  };
  BibleTranslation _defaultTranslation = BibleTranslation.kjv;
  ReferenceParseResult? _parseResult;
  String? _assistantMessage;
  bool _saving = false;

  bool get _isEditing => widget.planToEdit != null;

  @override
  void initState() {
    super.initState();
    final editing = widget.planToEdit;
    final template = widget.template;
    final now = DateTime.now();

    if (editing != null) {
      _titleController.text = editing.title;
      _passagesController.text = ReferenceUtils.formatForEditor(
        editing.sourceReferences,
      );
      _startDate = editing.startDate;
      _endDate = editing.endDate;
      _weekdays = Set<int>.from(editing.readingWeekdays);
      _defaultTranslation = editing.defaultTranslation;
      _reminderTime = _parseTime(editing.reminderTime);
    } else {
      _titleController.text = template?.title ?? 'My Bible Plan';
      _passagesController.text = template == null
          ? ''
          : ReferenceUtils.formatForEditor(template.references);
      _startDate = DateTime(now.year, now.month, now.day);
      _endDate = _startDate.add(
        Duration(days: (template?.defaultDurationDays ?? 30) - 1),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _passagesController.dispose();
    _assistantController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final template = widget.template;
    return ResponsiveContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          PageHeader(
            title: _isEditing
                ? 'Edit ${widget.planToEdit!.title}'
                : template == null
                ? 'Create a custom plan'
                : 'Customize ${template.title}',
            subtitle: _isEditing
                ? 'Change the end date, reading days, reminder, and default version. Source passages stay fixed to protect history.'
                : 'Choose what to read and the date you want to finish. The app will build the schedule.',
          ),
          const SizedBox(height: 24),
          if (_isEditing) ...<Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.edit_calendar_outlined),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Completed chapters that remain in the edited plan will stay completed.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
          ],
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Plan name'),
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<BibleTranslation>(
            initialValue: _defaultTranslation,
            decoration: const InputDecoration(
              labelText: 'Default reading version',
              helperText:
                  'You can switch versions for any individual reading later.',
            ),
            items: BibleTranslation.values
                .map(
                  (translation) => DropdownMenuItem<BibleTranslation>(
                    value: translation,
                    child: Text(
                      '${translation.label} (${translation.shortLabel})',
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _defaultTranslation = value);
              }
            },
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _passagesController,
            readOnly: _isEditing,
            minLines: 7,
            maxLines: 16,
            decoration: InputDecoration(
              labelText: 'Passages included in this plan',
              hintText: 'Matthew 5, 15, 18\nRomans 8:1-17\nPsalm 23\nJohn 1-3',
              helperText: _isEditing
                  ? 'Source passages cannot be changed after creation so completed reading history stays exact.'
                  : 'Paste references, edit a preset, or import TXT, CSV, or JSON.',
              suffixIcon: _isEditing
                  ? null
                  : IconButton(
                      tooltip: 'Import passage file',
                      onPressed: _importPassages,
                      icon: const Icon(Icons.upload_file),
                    ),
            ),
            onChanged: (_) => setState(() => _parseResult = null),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              if (!_isEditing)
                OutlinedButton.icon(
                  onPressed: _importPassages,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Import passage file'),
                ),
              OutlinedButton.icon(
                onPressed: _previewPassages,
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('Validate passages'),
              ),
            ],
          ),
          if (_parseResult != null) ...<Widget>[
            const SizedBox(height: 16),
            _ParsePreview(result: _parseResult!),
          ],
          const SizedBox(height: 22),
          if (!_isEditing)
            _AssistantCard(
              controller: _assistantController,
              message: _assistantMessage,
              onApply: _applyAssistantInstruction,
            ),
          const SizedBox(height: 28),
          Text('Schedule', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final children = <Widget>[
                _DateField(
                  label: 'Start date',
                  value: DateFormat.yMMMd().format(_startDate),
                  icon: Icons.calendar_today,
                  onTap: _pickStartDate,
                ),
                _DateField(
                  label: 'End date',
                  value: DateFormat.yMMMd().format(_endDate),
                  icon: Icons.event_available,
                  onTap: _pickEndDate,
                ),
                _DateField(
                  label: 'Reminder time',
                  value: _reminderTime.format(context),
                  icon: Icons.alarm,
                  onTap: _pickReminderTime,
                ),
              ];

              if (constraints.maxWidth >= 760) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children
                      .map(
                        (child) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: child,
                          ),
                        ),
                      )
                      .toList(),
                );
              }
              return Column(
                children: children
                    .map(
                      (child) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: child,
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 18),
          Text('Reading days', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final day in const <_WeekdayChoice>[
                _WeekdayChoice(DateTime.monday, 'Mon'),
                _WeekdayChoice(DateTime.tuesday, 'Tue'),
                _WeekdayChoice(DateTime.wednesday, 'Wed'),
                _WeekdayChoice(DateTime.thursday, 'Thu'),
                _WeekdayChoice(DateTime.friday, 'Fri'),
                _WeekdayChoice(DateTime.saturday, 'Sat'),
                _WeekdayChoice(DateTime.sunday, 'Sun'),
              ])
                FilterChip(
                  label: Text(day.label),
                  selected: _weekdays.contains(day.value),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _weekdays = <int>{..._weekdays, day.value};
                      } else if (_weekdays.length > 1) {
                        _weekdays = _weekdays
                            .where((value) => value != day.value)
                            .toSet();
                      }
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 30),
          FilledButton.icon(
            onPressed: _saving ? null : _savePlan,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(_isEditing ? Icons.preview_outlined : Icons.preview),
            label: Text(
              _saving
                  ? 'Saving plan...'
                  : _isEditing
                  ? 'Preview plan changes'
                  : 'Preview schedule',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _importPassages() async {
    try {
      final imported = await _importService.pickPassageFile();
      if (imported == null || !mounted) return;

      final existing = _passagesController.text.trim();
      _passagesController.text = existing.isEmpty
          ? imported.text
          : '$existing\n${imported.text}';
      setState(() => _parseResult = _parser.parse(_passagesController.text));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Imported ${imported.fileName}.')));
    } on FormatException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('The file could not be imported: $error')),
      );
    }
  }

  void _previewPassages() {
    setState(() => _parseResult = _parser.parse(_passagesController.text));
  }

  void _applyAssistantInstruction() {
    final instruction = _assistantController.text.trim();
    if (instruction.isEmpty) {
      setState(() => _assistantMessage = 'Enter an instruction first.');
      return;
    }

    final result = _assistant.apply(
      instruction: instruction,
      passagesText: _passagesController.text,
      endDate: _endDate,
      readingWeekdays: _weekdays,
    );
    setState(() {
      _passagesController.text = result.passagesText;
      _endDate = result.endDate;
      _weekdays = result.readingWeekdays;
      _assistantMessage = result.message;
      _parseResult = _parser.parse(_passagesController.text);
    });
  }

  Future<void> _pickStartDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (value != null) {
      setState(() {
        _startDate = value;
        if (_endDate.isBefore(value)) _endDate = value;
      });
    }
  }

  Future<void> _pickEndDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _endDate.isBefore(_startDate) ? _startDate : _endDate,
      firstDate: _startDate,
      lastDate: _startDate.add(const Duration(days: 3650)),
    );
    if (value != null) setState(() => _endDate = value);
  }

  Future<void> _pickReminderTime() async {
    final value = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (value != null) setState(() => _reminderTime = value);
  }

  Future<void> _savePlan() async {
    final parsed = _parser.parse(_passagesController.text);

    if (_titleController.text.trim().isEmpty) {
      _showError('Add a name for this plan.');
      return;
    }
    if (parsed.references.isEmpty) {
      setState(() => _parseResult = parsed);
      _showError('Add at least one valid Bible passage.');
      return;
    }
    if (parsed.issues.isNotEmpty) {
      setState(() => _parseResult = parsed);
      _showError('Correct the highlighted passage entries before saving.');
      return;
    }
    if (_endDate.isBefore(_startDate)) {
      _showError('The end date cannot be before the start date.');
      return;
    }

    setState(() => _saving = true);
    try {
      final editing = widget.planToEdit;
      final scheduleChanged = editing == null ||
          editing.startDate != _startDate ||
          editing.endDate != _endDate ||
          !_sameWeekdays(editing.readingWeekdays, _weekdays);
      final scheduleStart = editing == null
          ? _startDate
          : _laterDate(_startDate, DateTime.now());
      final assignments = scheduleChanged
          ? (editing == null
                ? _scheduler.preview(
                    references: parsed.references,
                    startDate: _startDate,
                    endDate: _endDate,
                    readingWeekdays: _weekdays,
                  )
                : _scheduler.rescheduleUnfinished(
                    plan: editing,
                    startDate: scheduleStart,
                    endDate: _endDate,
                    readingWeekdays: _weekdays,
                  ))
          : editing.assignments;

      final reminder =
          '${_reminderTime.hour.toString().padLeft(2, '0')}:'
          '${_reminderTime.minute.toString().padLeft(2, '0')}';
      final plan = ReadingPlan(
        id: editing?.id ?? const Uuid().v4(),
        title: _titleController.text.trim(),
        defaultTranslation: _defaultTranslation,
        createdAt: editing?.createdAt ?? DateTime.now(),
        startDate: _startDate,
        endDate: _endDate,
        readingWeekdays: _weekdays,
        reminderTime: reminder,
        sourceReferences: parsed.references,
        assignments: assignments,
        templateId: editing?.templateId ?? widget.template?.id,
        lastReadLocation: editing?.lastReadLocation,
        lastReadAssignmentHint: editing?.lastReadAssignmentHint,
      );
      if (scheduleChanged &&
          !await _confirmSchedulePreview(
            plan: plan,
            completedCount: editing?.completedCount ?? 0,
          )) {
        return;
      }
      await widget.controller.savePlan(plan);
      if (!mounted) return;
      if (widget.onSaved != null) {
        widget.onSaved!();
      } else {
        Navigator.of(context).maybePop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Saved changes to ${plan.title}.'
                : 'Created ${plan.title} with ${assignments.length} scheduled readings.',
          ),
        ),
      );
    } catch (error) {
      if (mounted) _showError('The plan could not be saved: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _confirmSchedulePreview({
    required ReadingPlan plan,
    required int completedCount,
  }) async {
    final upcoming = plan.assignments.where((item) => !item.completed).toList();
    final first = upcoming.isEmpty ? null : upcoming.first;
    final last = upcoming.isEmpty ? null : upcoming.last;
    return (await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Schedule preview'),
            content: Text(
              '${upcoming.length} unfinished readings will be scheduled on '
              '${plan.readingWeekdays.length} selected weekday(s) through '
              '${DateFormat.yMMMd().format(plan.endDate)}.\n\n'
              '${completedCount == 0 ? '' : '$completedCount completed reading(s) stay unchanged.\n\n'}'
              '${first == null ? 'No unfinished readings remain.' : 'First: ${DateFormat.yMMMd().format(first.date)}\nLast: ${DateFormat.yMMMd().format(last!.date)}'}',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Apply schedule'),
              ),
            ],
          ),
        )) ??
        false;
  }

  bool _sameWeekdays(Set<int> left, Set<int> right) =>
      left.length == right.length && left.containsAll(right);

  DateTime _laterDate(DateTime left, DateTime right) {
    final normalizedLeft = DateTime(left.year, left.month, left.day);
    final normalizedRight = DateTime(right.year, right.month, right.day);
    return normalizedLeft.isAfter(normalizedRight)
        ? normalizedLeft
        : normalizedRight;
  }

  TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return const TimeOfDay(hour: 7, minute: 0);
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 7,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _AssistantCard extends StatelessWidget {
  const _AssistantCard({
    required this.controller,
    required this.message,
    required this.onApply,
  });

  final TextEditingController controller;
  final String? message;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.auto_awesome),
                const SizedBox(width: 10),
                Text(
                  'Plan assistant',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Give an instruction and the assistant will edit the plan form. '
              'This MVP uses safe local commands and does not send your plan to an AI service.',
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Instruction',
                hintText:
                    'Only include chapters, and change the end date to August 30, 2026.',
              ),
              onSubmitted: (_) => onApply(),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: onApply,
              icon: const Icon(Icons.auto_fix_high),
              label: const Text('Apply instruction'),
            ),
            if (message != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(message!),
            ],
          ],
        ),
      ),
    );
  }
}

class _ParsePreview extends StatelessWidget {
  const _ParsePreview({required this.result});

  final ReferenceParseResult result;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '${result.references.length} valid reference'
              '${result.references.length == 1 ? '' : 's'}',
            ),
            const SizedBox(height: 8),
            if (result.references.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: result.references
                    .map((reference) => Chip(label: Text(reference.display)))
                    .toList(),
              ),
            if (result.issues.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                'Needs attention',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 6),
              ...result.issues.map(
                (issue) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• ${issue.input}: ${issue.message}'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, suffixIcon: Icon(icon)),
        child: Text(value),
      ),
    );
  }
}

class _WeekdayChoice {
  const _WeekdayChoice(this.value, this.label);

  final int value;
  final String label;
}
