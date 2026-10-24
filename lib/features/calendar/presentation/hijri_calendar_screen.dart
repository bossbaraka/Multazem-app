import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri.dart';

import '../../../core/providers/prayer_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/islamic.dart';
import '../data/islamic_occasions.dart';

/// التقويم الهجري + المناسبات + متتبع الصيام (اليوم والإحصاء)
class HijriCalendarScreen extends ConsumerWidget {
  const HijriCalendarScreen({super.key});

  static const _fastLabels = {
    'volunteer': 'تطوّع',
    'qada': 'قضاء',
    'ramadan': 'رمضان',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final box = ref.watch(hiveBoxProvider);
    final today = ref.watch(hijriTodayProvider);
    final daysInMonth = _monthLength(today.hYear, today.hMonth);
    final firstGreg = HijriCalendar().hijriToGregorian(today.hYear, today.hMonth, 1);
    final leadEmpty = (firstGreg.weekday - DateTime.saturday) % 7;
    final todayKey = _dayKey(DateTime.now());
    final fastingToday = box.get('fast_$todayKey') as String?;

    // إحصاءات الصيام (آخر ٦٠ يوماً)
    var monthCount = 0;
    var streak = 0;
    final now = DateTime.now();
    for (var i = 0; i < 60; i++) {
      final d = now.subtract(Duration(days: i));
      final has = box.get('fast_${_dayKey(d)}') != null;
      if (d.month == now.month && d.year == now.year && has) monthCount++;
      if (i == 0 && !has) continue; // اليوم غير مسجل لا يكسر السلسلة
      if (has) {
        streak++;
      } else {
        break;
      }
    }

    final monthOccasions =
        kIslamicOccasions.where((o) => o.hijriMonth == today.hMonth).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('التقويم الهجري')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // ── ترويسة التاريخ ──────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppColors.headerGradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(children: [
            Text(formatHijri(today),
                textAlign: TextAlign.center,
                style: AppTheme.amiri(22, color: AppColors.inkOnDark)),
            const SizedBox(height: 4),
            Text(
              'شهر ${kHijriMonths[today.hMonth - 1]} — ${toArabicDigits(daysInMonth)} يوماً',
              style: const TextStyle(color: AppColors.goldLight, fontSize: 13),
            ),
          ]),
        ),
        const SizedBox(height: 14),

        // ── شبكة الشهر ─────────────────────────────────────────
        OrnamentedCard(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            // أسماء الأيام (تبدأ السبت)
            Row(children: [
              for (final d in const ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج'])
                Expanded(
                  child: Center(
                    child: Text(d,
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.inkSoft,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
            ]),
            const SizedBox(height: 6),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisExtent: 44,
              ),
              itemCount: leadEmpty + daysInMonth,
              itemBuilder: (context, i) {
                if (i < leadEmpty) return const SizedBox.shrink();
                final day = i - leadEmpty + 1;
                return _DayCell(
                  year: today.hYear,
                  month: today.hMonth,
                  day: day,
                  todayHDay: today.hDay,
                  firstGreg: firstGreg,
                );
              },
            ),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _legend(AppColors.gold, 'مناسبة'),
              const SizedBox(width: 12),
              _legend(AppColors.emerald, 'أيام بيض'),
              const SizedBox(width: 12),
              _legend(AppColors.warning, 'اثنين/خميس'),
            ]),
          ]),
        ),
        const SizedBox(height: 14),

        // ── متتبع الصيام ───────────────────────────────────────
        const SectionTitle('صيام اليوم 🌙'),
        const SizedBox(height: 8),
        OrnamentedCard(
          color: fastingToday != null
              ? AppColors.success.withValues(alpha: 0.1)
              : null,
          child: Column(children: [
            Row(children: [
              Icon(
                fastingToday != null
                    ? Icons.check_circle
                    : Icons.circle_outlined,
                color: fastingToday != null
                    ? AppColors.success
                    : AppColors.inkSoft,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('أنا صائم اليوم',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              DropdownButton<String?>(
                value: fastingToday,
                hint: const Text('اختر'),
                underline: const SizedBox(),
                items: [
                  for (final e in _fastLabels.entries)
                    DropdownMenuItem(value: e.key, child: Text(e.value)),
                  const DropdownMenuItem(value: null, child: Text('إلغاء')),
                ],
                onChanged: (v) {
                  if (v == null) {
                    box.delete('fast_$todayKey');
                  } else {
                    box.put('fast_$todayKey', v);
                  }
                },
              ),
            ]),
            const Divider(height: 18),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _stat('هذا الشهر', '${toArabicDigits(monthCount)} أيام'),
              _stat('سلسلتك', '${toArabicDigits(streak)} أيام'),
              _stat('البيض (هذا الشهر الهجري)',
                  isWhiteDays(today.hDay) ? 'اليوم! ✨' : '١٣-١٤-١٥'),
            ]),
          ]),
        ),

        const SizedBox(height: 14),

        // ── مناسبات الشهر ──────────────────────────────────────
        SectionTitle('مناسبات ${kHijriMonths[today.hMonth - 1]}'),
        const SizedBox(height: 8),
        if (monthOccasions.isEmpty)
          OrnamentedCard(
            child: Text(
              'لا مناسبات مخصوصة هذا الشهر — $whiteDaysNote',
              style: const TextStyle(fontSize: 13, height: 1.8),
            ),
          )
        else
          for (final o in monthOccasions)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OrnamentedCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.star_rounded, color: AppColors.gold, size: 20),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(o.title,
                          style: AppTheme.amiri(17, color: AppColors.emerald)),
                    ),
                    Text(
                      o.endDay == null
                          ? toArabicDigits(o.hijriDay)
                          : '${toArabicDigits(o.hijriDay)}–${toArabicDigits(o.endDay!)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  Text(o.description,
                      style: const TextStyle(fontSize: 13, height: 1.8)),
                  if (o.recommended != null) ...[
                    const SizedBox(height: 6),
                    Text('📌 ${o.recommended}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.success, height: 1.7)),
                  ],
                ]),
              ),
            ),

        // الأيام البيض
        if (isWhiteDays(today.hDay))
          OrnamentedCard(
            color: AppColors.gold.withValues(alpha: 0.12),
            child: Text(
              '✨ أنت الآن في الأيام البيض — يُستحب صيامها. «صيام ثلاثة أيام من كل شهر» — متفق عليه.',
              style: const TextStyle(fontSize: 13, height: 1.8),
            ),
          ),
      ]),
    );
  }

  static String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  /// طول الشهر الهجري بالتحويل الميلادي (٢٩ أو ٣٠)
  static int _monthLength(int year, int month) {
    final first = HijriCalendar().hijriToGregorian(year, month, 1);
    final next = month == 12
        ? HijriCalendar().hijriToGregorian(year + 1, 1, 1)
        : HijriCalendar().hijriToGregorian(year, month + 1, 1);
    final len = next.difference(first).inDays;
    return (len == 29 || len == 30) ? len : 30;
  }

  Widget _stat(String label, String value) => Column(children: [
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: AppColors.emerald)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
      ]);

  Widget _legend(Color color, String label) => Row(children: [
        Container(width: 8, height: 8, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.inkSoft)),
      ]);
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.year,
    required this.month,
    required this.day,
    required this.todayHDay,
    required this.firstGreg,
  });

  final int year;
  final int month;
  final int day;
  final int todayHDay;
  final DateTime firstGreg;

  @override
  Widget build(BuildContext context) {
    final isToday = day == todayHDay;
    final white = isWhiteDays(day);
    final hasOccasion = kIslamicOccasions.any((o) => o.contains(month, day));
    final gregOfDay = firstGreg.add(Duration(days: day - 1));
    final sunnahFast = gregOfDay.weekday == DateTime.monday ||
        gregOfDay.weekday == DateTime.thursday;

    return Container(
      margin: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        color: isToday
            ? AppColors.emerald
            : white
                ? AppColors.emerald.withValues(alpha: 0.1)
                : null,
        border: hasOccasion ? Border.all(color: AppColors.gold, width: 1.4) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(
          toArabicDigits(day),
          style: TextStyle(
            fontSize: 12,
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            color: isToday ? Colors.white : null,
          ),
        ),
        if (sunnahFast)
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: AppColors.warning,
              shape: BoxShape.circle,
            ),
          ),
      ]),
    );
  }
}
