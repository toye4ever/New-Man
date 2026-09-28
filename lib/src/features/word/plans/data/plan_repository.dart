import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../application/plan_repository.dart';
import '../domain/reading_plan.dart';

class SharedPreferencesPlanRepository implements PlanRepository {
  SharedPreferencesPlanRepository({SharedPreferencesAsync? preferences})
    : _preferences = preferences;

  static const String storageKey = 'scripture_planner.plans.v1';

  SharedPreferencesAsync? _preferences;

  SharedPreferencesAsync get _store =>
      _preferences ??= SharedPreferencesAsync();

  @override
  Future<List<ReadingPlan>> loadPlans() async {
    final raw = await _store.getString(storageKey);
    if (raw == null || raw.isEmpty) {
      return <ReadingPlan>[];
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => ReadingPlan.fromJson(item as Map<String, dynamic>))
          .toList();
    } on FormatException {
      return <ReadingPlan>[];
    }
  }

  @override
  Future<void> savePlans(List<ReadingPlan> plans) async {
    final raw = jsonEncode(plans.map((plan) => plan.toJson()).toList());
    await _store.setString(storageKey, raw);
  }
}
