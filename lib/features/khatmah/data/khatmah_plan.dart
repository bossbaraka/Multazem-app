import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/providers/prayer_providers.dart';

/// خطة ختمة القرآن — ٦٠٤ صفحات موزّعة على عدد أيام يختاره المستخدم.
class KhatmahPlan {
  KhatmahPlan({
    required this.days,
    required this.startDate,
    required this.doneDays,
  });

  final int days;
  final DateTime startDate;
  int doneDays;

  static const totalPages = 604;

  int get pagesPerDay => (totalPages / days).ceil();

  /// رقم اليوم الحالي في الخطة (١..days)
  int get currentDay {
    final d = DateTime.now().difference(startDate).inDays + 1;
    return d.clamp(1, days);
  }

  /// صفحات ورد اليوم: من..إلى
  (int, int) get todayRange {
    final from = (currentDay - 1) * pagesPerDay + 1;
    final to = (currentDay * pagesPerDay).clamp(1, totalPages);
    return (from, to);
  }

  bool get todayDone => doneDays >= currentDay;
  bool get finished => doneDays >= days;
  double get progress => (doneDays / days).clamp(0.0, 1.0);

  /// متى يُتوقع الختام لو استمر كما بدأ
  DateTime get expectedFinish => startDate.add(Duration(days: days - 1));
}

class KhatmahRepository {
  KhatmahRepository(this._box);

  final Box _box;

  KhatmahPlan? current() {
    final days = _box.get('khat_days') as int?;
    final start = _box.get('khat_start') as String?;
    if (days == null || start == null) return null;
    return KhatmahPlan(
      days: days,
      startDate: DateTime.parse(start),
      doneDays: _box.get('khat_done', defaultValue: 0) as int,
    );
  }

  Future<KhatmahPlan> create(int days) async {
    await _box.put('khat_days', days);
    await _box.put('khat_start', DateTime.now().toIso8601String());
    await _box.put('khat_done', 0);
    return current()!;
  }

  Future<KhatmahPlan?> markTodayDone() async {
    final plan = current();
    if (plan == null || plan.finished) return plan;
    plan.doneDays = plan.currentDay; // يُعتبر كل ما قبله منجزاً
    await _box.put('khat_done', plan.doneDays);
    return plan;
  }

  Future<void> clear() async {
    await _box.delete('khat_days');
    await _box.delete('khat_start');
    await _box.delete('khat_done');
  }
}

final khatmahRepoProvider = Provider<KhatmahRepository>(
  (ref) => KhatmahRepository(ref.watch(hiveBoxProvider)),
);
