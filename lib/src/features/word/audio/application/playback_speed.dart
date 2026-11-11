/// Relative labels use the existing 0.45 native rate as normal narration.
/// Native engines choose actual words/minute; these are nominal multipliers.
class PlaybackSpeed {
  static const normalRate = .45;
  static const multipliers = <double>[
    .5,
    .625,
    .75,
    .875,
    1,
    1.125,
    1.25,
    1.375,
    1.5,
    1.625,
    1.75,
    1.875,
    2,
  ];
  static double nativeRate(double multiplier) =>
      (normalRate + (multiplier - 1) * .4).clamp(.25, .85);
  static double multiplier(double rate) => 1 + (rate - normalRate) / .4;
  static String label(double rate) =>
      '${multiplier(rate).toStringAsFixed(3).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '')}×';
}
