import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/providers/prayer_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/islamic.dart';
import '../../prayer/data/prayer_log.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _ticker;
  Duration _remaining = Duration.zero;
  final Set<String> _done = {};

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final next = ref.read(nextPrayerProvider).time;
    setState(() {
      _remaining = next.difference(DateTime.now());
      if (_remaining.isNegative) _remaining = Duration.zero;
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return toArabicDigits(
        '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}');
  }

  List<(String, String, IconData)> _routine(DateTime now) {
    final items = <(String, String, IconData)>[
      ('قيام الليل والوتر', 'قبل الفجر', Icons.nightlight_round),
      ('أذكار الصباح', 'بعد الفجر', Icons.wb_twilight),
      ('وردك القرآني اليومي', 'أي وقت اليوم', Icons.menu_book_rounded),
      ('أذكار المساء', 'بعد العصر', Icons.wb_sunny_outlined),
      ('أذكار النوم', 'قبل النوم', Icons.bedtime_rounded),
    ];
    if (now.weekday == DateTime.friday) {
      items.insert(
          1, ('سورة الكهف + الصلاة على النبي ﷺ', 'يوم الجمعة', Icons.auto_awesome));
    }
    if (now.weekday == DateTime.monday || now.weekday == DateTime.thursday) {
      items.add(('صيام التطوّع', 'اليوم', Icons.eco_rounded));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final next = ref.watch(nextPrayerProvider);
    final hijri = ref.watch(hijriTodayProvider);
    final now = DateTime.now();
    final routine = _routine(now);

    return Scaffold(
      appBar: AppBar(
        title: const Text('مُلتزم'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // ── الترويسة: تحية + تاريخان ──────────────────────────────
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppColors.headerGradient,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('السلام عليكم ورحمة الله 🤍',
                  style: AppTheme.amiri(20, color: AppColors.inkOnDark)),
              const SizedBox(height: 8),
              Text(formatHijri(hijri),
                  style: const TextStyle(
                      color: AppColors.goldLight,
                      fontSize: 17,
                      fontWeight: FontWeight.bold)),
              Text(
                DateFormat('EEEE d MMMM y', 'ar').format(now),
                style: TextStyle(
                    color: AppColors.inkOnDark.withValues(alpha: 0.8), fontSize: 13),
              ),
              Text('📍 ${ref.watch(cityNameProvider)}',
                  style: const TextStyle(color: AppColors.goldLight, fontSize: 12)),
            ]),
          ),
          const SizedBox(height: 12),

          // ── اختصارات سريعة (قابلة للتمرير أفقياً) ──────────────
          SizedBox(
            height: 92,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final (icon, label, route) in const [
                  (Icons.calendar_month_rounded, 'التقويم', '/calendar'),
                  (Icons.auto_stories_rounded, 'ختمتي', '/khatmah'),
                  (Icons.fingerprint, 'السبحة', '/tasbih'),
                  (Icons.emoji_events_rounded, 'إنجازاتي', '/achievements'),
                  (Icons.school_rounded, 'تعلّم التجويد', '/learn-quran'),
                  (Icons.local_library_rounded, 'المكتبة', '/library'),
                  (Icons.favorite_rounded, 'الأخلاق', '/morals'),
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: SizedBox(
                      width: 88,
                      child: Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => context.push(route),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(icon, color: AppColors.emerald, size: 24),
                              const SizedBox(height: 4),
                              Text(label,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // ── بطاقة الصلاة القادمة ──────────────────────────────────
          OrnamentedCard(
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('الصلاة القادمة', style: AppTheme.amiri(17, color: AppColors.emerald)),
                Chip(
                  label: Text(prayerName(next.prayer)),
                  backgroundColor: AppColors.gold.withValues(alpha: 0.2),
                  side: BorderSide.none,
                ),
              ]),
              const SizedBox(height: 6),
              Text(formatTime(next.time), style: AppTheme.amiri(40)),
              const SizedBox(height: 4),
              Text('تبقّى على الأذان  ${_fmt(_remaining)}',
                  style: const TextStyle(color: AppColors.inkSoft)),
              const SizedBox(height: 10),
              () {
                final log = ref.watch(todayLogProvider);
                final doneCount = log.values.where((v) => v.isNotEmpty).length;
                return Column(children: [
                  Text('أتممت ${toArabicDigits(doneCount)} من ٥ صلوات اليوم 🕌',
                      style: const TextStyle(color: AppColors.inkSoft, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    for (final (key, label) in kFivePrayers)
                      _PrayerDot(logKey: key, label: label),
                  ]),
                ]);
              }(),
            ]),
          ),
          const SizedBox(height: 20),

          // ── خطة اليوم ────────────────────────────────────────────
          const SectionTitle('خطة يومك 🕌'),
          const SizedBox(height: 10),
          for (final (title, timeHint, icon) in routine) ...[
            OrnamentedCard(
              child: Row(children: [
                Icon(icon, color: AppColors.emerald),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(timeHint,
                        style: const TextStyle(
                            color: AppColors.inkSoft, fontSize: 12)),
                  ]),
                ),
                IconButton(
                  onPressed: () => setState(() => _done.contains(title)
                      ? _done.remove(title)
                      : _done.add(title)),
                  icon: Icon(
                    _done.contains(title)
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: _done.contains(title)
                        ? AppColors.success
                        : AppColors.inkSoft,
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 8),
          ],

          // ── لفتة اليوم ───────────────────────────────────────────
          const OrnamentDivider(),
          OrnamentedCard(
            color: AppColors.gold.withValues(alpha: 0.08),
            child: Column(children: [
              Text('«أَحَبُّ الأَعْمَالِ إِلَى اللَّهِ أَدْوَمُهَا وَإِنْ قَلَّ»',
                  textAlign: TextAlign.center, style: AppTheme.amiri(18)),
              const SizedBox(height: 6),
              const Text('رواه البخاري ٦٤٦٤',
                  style: TextStyle(color: AppColors.inkSoft, fontSize: 12)),
            ]),
          ),
        ],
      ),
    );
  }
}

class _PrayerDot extends ConsumerWidget {
  const _PrayerDot({required this.logKey, required this.label});

  final String logKey;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mark = ref.watch(todayLogProvider)[logKey] ?? '';
    final done = mark.isNotEmpty;
    final color = switch (mark) {
      'jamaah' => AppColors.gold,
      'qada' => AppColors.warning,
      'onTime' => AppColors.success,
      _ => AppColors.gold.withValues(alpha: 0.18),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(children: [
        CircleAvatar(
          radius: 13,
          backgroundColor: color,
          child: Icon(
            done ? Icons.check : Icons.circle_outlined,
            size: 14,
            color: done ? Colors.white : AppColors.gold,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.inkSoft)),
      ]),
    );
  }
}
