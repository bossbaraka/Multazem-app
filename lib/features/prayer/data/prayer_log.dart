import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/providers/prayer_providers.dart';

// ── مستودع سجل الصلوات (Hive — محلي ١٠٠٪) ─────────────────────────────
// الحالات: onTime (في وقتها) / jamaah (في جماعة) / qada (قضاءً)

class PrayerLogRepository {
  PrayerLogRepository(this._box);

  final Box _box;

  static String _key(DateTime d) => 'log_${d.year}-${d.month}-${d.day}';

  Map<String, String> day(DateTime d) {
    final raw = _box.get(_key(d));
    if (raw == null) return <String, String>{};
    return Map<String, String>.from(raw as Map);
  }

  Future<void> mark(DateTime d, String prayerKey, String status) async {
    final m = day(d)..[prayerKey] = status;
    await _box.put(_key(d), m);
  }

  Future<void> remove(DateTime d, String prayerKey) async {
    final m = day(d)..remove(prayerKey);
    await _box.put(_key(d), m);
  }

  /// نسب الالتزام لآخر ٧ أيام (0..1) مع أسماء الأيام
  List<(String, double)> weekRatios() {
    final now = DateTime.now();
    return [
      for (var i = 6; i >= 0; i--)
        () {
          final d = now.subtract(Duration(days: i));
          final done = day(d).values.where((v) => v.isNotEmpty).length;
          return (kWeekdayNames[d.weekday]!, done / 5);
        }(),
    ];
  }
}

const kWeekdayNames = {
  1: 'الاثنين',
  2: 'الثلاثاء',
  3: 'الأربعاء',
  4: 'الخميس',
  5: 'الجمعة',
  6: 'السبت',
  7: 'الأحد',
};

/// تسميات الحالات للعرض
const kMarkLabels = {
  'onTime': 'في وقتها',
  'jamaah': 'في جماعة',
  'qada': 'قضاءً',
};

// ── Riverpod ───────────────────────────────────────────────────────────

final prayerLogRepoProvider = Provider<PrayerLogRepository>(
  (ref) => PrayerLogRepository(ref.watch(hiveBoxProvider)),
);

/// سجلّ اليوم (يتفاعل فوراً مع كل تسجيل)
final todayLogProvider =
    StateNotifierProvider<TodayLogNotifier, Map<String, String>>(
  (ref) => TodayLogNotifier(ref.watch(prayerLogRepoProvider)),
);

class TodayLogNotifier extends StateNotifier<Map<String, String>> {
  TodayLogNotifier(this._repo) : super(_repo.day(DateTime.now()));

  final PrayerLogRepository _repo;

  Future<void> set(String prayerKey, String status) async {
    final d = DateTime.now();
    await _repo.mark(d, prayerKey, status);
    state = _repo.day(d);
  }

  Future<void> remove(String prayerKey) async {
    final d = DateTime.now();
    await _repo.remove(d, prayerKey);
    state = _repo.day(d);
  }
}

/// بيانات الرسم الأسبوعي — تتحدّث تلقائياً مع أي تسجيل جديد
final weekRatiosProvider = Provider<List<(String, double)>>((ref) {
  ref.watch(todayLogProvider); // إعادة الحساب عند تغيّر اليوم
  return ref.watch(prayerLogRepoProvider).weekRatios();
});
