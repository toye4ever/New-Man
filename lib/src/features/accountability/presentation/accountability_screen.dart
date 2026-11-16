import 'package:flutter/material.dart';

/// A manually entered, in-memory draft. No repositories or sharing boundary.
class AccountabilityScreen extends StatefulWidget {
  const AccountabilityScreen({super.key});

  @override
  State<AccountabilityScreen> createState() => _AccountabilityScreenState();
}

class _AccountabilityScreenState extends State<AccountabilityScreen> {
  final _reflection = TextEditingController();
  final _nextStep = TextEditingController();
  bool _started = false;
  bool _includeReflection = false;
  bool _includeNextStep = false;
  bool _reviewing = false;

  bool get _canReview =>
      (_includeReflection && _reflection.text.trim().isNotEmpty) ||
      (_includeNextStep && _nextStep.text.trim().isNotEmpty);

  void _clear() {
    FocusScope.of(context).unfocus();
    setState(() {
      _reflection.clear();
      _nextStep.clear();
      _started = false;
      _includeReflection = false;
      _includeNextStep = false;
      _reviewing = false;
    });
  }

  @override
  void dispose() {
    _reflection.dispose();
    _nextStep.dispose();
    super.dispose();
  }

  Widget _field({
    required String label,
    required bool included,
    required TextEditingController controller,
    required ValueChanged<bool> onSelected,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      CheckboxListTile(
        title: Text('Include $label'),
        value: included,
        onChanged: (value) => setState(() {
          onSelected(value == true);
          if (value != true) controller.clear();
        }),
      ),
      if (included)
        TextField(
          controller: controller,
          decoration: InputDecoration(labelText: label),
          minLines: 1,
          maxLines: 4,
          maxLength: 280,
          autocorrect: false,
          enableSuggestions: false,
          enableIMEPersonalizedLearning: false,
          onChanged: (_) => setState(() {}),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Local check-in draft')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Optional and private. Nothing is sent or saved by New Man. '
          'The draft is cleared when you leave this tab. '
          'Only fields you select and type appear in review.',
        ),
        const SizedBox(height: 16),
        if (!_started)
          FilledButton(
            onPressed: () => setState(() => _started = true),
            child: const Text('Start private draft'),
          )
        else if (_reviewing) ...[
          Semantics(
            header: true,
            child: Text(
              'Review your draft',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const Text('This is a local preview. There is no send action.'),
          if (_includeReflection && _reflection.text.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Reflection'),
            Text(_reflection.text.trim()),
          ],
          if (_includeNextStep && _nextStep.text.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Next step'),
            Text(_nextStep.text.trim()),
          ],
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => setState(() => _reviewing = false),
            child: const Text('Edit draft'),
          ),
          TextButton(onPressed: _clear, child: const Text('Clear draft')),
        ] else ...[
          _field(
            label: 'Reflection',
            included: _includeReflection,
            controller: _reflection,
            onSelected: (value) => _includeReflection = value,
          ),
          _field(
            label: 'Next step',
            included: _includeNextStep,
            controller: _nextStep,
            onSelected: (value) => _includeNextStep = value,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _canReview
                ? () {
                    FocusScope.of(context).unfocus();
                    setState(() => _reviewing = true);
                  }
                : null,
            child: const Text('Review draft'),
          ),
          TextButton(onPressed: _clear, child: const Text('Cancel draft')),
        ],
      ],
    ),
  );
}
