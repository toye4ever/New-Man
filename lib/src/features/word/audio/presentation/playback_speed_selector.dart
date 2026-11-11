import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../application/playback_speed.dart';

class PlaybackSpeedSelector extends StatelessWidget {
  const PlaybackSpeedSelector({
    required this.rate,
    required this.onChanged,
    super.key,
  });
  final double rate;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => _pick(context),
    child: Text(PlaybackSpeed.label(rate)),
  );

  Future<void> _pick(BuildContext context) async {
    final rates = PlaybackSpeed.multipliers
        .map(PlaybackSpeed.nativeRate)
        .toList();
    var selected = rates.indexWhere((v) => (v - rate).abs() < .0001);
    if (selected < 0) {
      selected = List.generate(rates.length, (i) => i).reduce(
        (a, b) => (rates[a] - rate).abs() < (rates[b] - rate).abs() ? a : b,
      );
    }
    final scroll = FixedExtentScrollController(initialItem: selected);
    final value = await showModalBottomSheet<double>(
      context: context,
      builder: (sheet) => SafeArea(
        child: SizedBox(
          height: 260,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Expanded(child: Text('Reading speed')),
                    TextButton(
                      onPressed: () => Navigator.pop(sheet, rates[selected]),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  scrollController: scroll,
                  itemExtent: 40,
                  onSelectedItemChanged: (index) => selected = index,
                  children: [
                    for (final rate in rates)
                      Center(child: Text(PlaybackSpeed.label(rate))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    scroll.dispose();
    if (value != null) onChanged(value);
  }
}
