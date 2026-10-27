import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/providers/prayer_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/islamic.dart';
import '../data/morals_content.dart';

/// علِّمني الأخلاق — بوابتان:
/// ١) بطاقات الأخلاق (شرح مفصّل + دليل + تطبيق)
/// ٢) مؤشر الالتزام: تقييم ذاتي دوري لـ ١٥ خلقاً، محفوظ في Hive، مع نسبة عامة وتحليل نقاط القوة والضعف.
class MoralsScreen extends ConsumerWidget {
  const MoralsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('علِّمني الأخلاق'),
          bottom: const TabBar(tabs: [
            Tab(text: 'الأخلاق الكريمة'),
            Tab(text: 'مؤشر الالتزام'),
          ]),
        ),
        body: const TabBarView(children: [
          _MoralsLearnTab(),
          _CommitmentTab(),
        ]),
      ),
    );
  }
}

// ═══════════════════════════ التبويب ١: التعلّم ═══════════════════════════
class _MoralsLearnTab extends StatelessWidget {
  const _MoralsLearnTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        OrnamentedCard(
          color: AppColors.gold.withValues(alpha: 0.08),
          child: const Text(
            '«إِنَّمَا بُعِثْتُ لِأُتَمِّمَ مَكَارِمَ الْأَخْلَاقِ» — رواه الإمام أحمد\nاخلقًا كريمًا واحدًا في اليوم خيرٌ من قنطار منها دفعةً واحدة.',
            textAlign: TextAlign.center,
            style: TextStyle(height: 1.9, fontSize: 12.5),
          ),
        ),
        const SizedBox(height: 10),
        for (final m in kMorals)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: ExpansionTile(
                leading: Text(m.emoji, style: const TextStyle(fontSize: 24)),
                title: Text(m.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                subtitle: Text(
                  '${m.explanation.split('،').first.trim()}…',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: AppColors.inkSoft),
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  // ── الشرح المفصّل ─────────────────────────
                  Text(m.explanation,
                      style: const TextStyle(fontSize: 13.5, height: 1.95)),
                  const SizedBox(height: 10),
                  // ── الدليل ────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.emerald.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.emerald.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('الدليل 📖',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.emerald)),
                          const SizedBox(height: 6),
                          SelectableText(m.evidence,
                              style: GoogleFonts.amiri(
                                  fontSize: 15.5, height: 1.9)),
                          const SizedBox(height: 4),
                          Text(m.source,
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.gold)),
                        ]),
                  ),
                  const SizedBox(height: 8),
                  // ── التطبيق العملي ────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text('🎯 تطبيقك اليوم: ${m.application}',
                        style: const TextStyle(fontSize: 12.5, height: 1.8)),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ════════════════════ التبويب ٢: مقياس الالتزام ════════════════════
class _CommitmentTab extends ConsumerStatefulWidget {
  const _CommitmentTab();

  @override
  ConsumerState<_CommitmentTab> createState() => _CommitmentTabState();
}

class _CommitmentTabState extends ConsumerState<_CommitmentTab> {
  final Map<String, int> _answers = {};

  @override
  void initState() {
    super.initState();
    _loadLast();
  }

  void _loadLast() {
    final box = ref.read(hiveBoxProvider);
    final raw = box.get('morals_last');
    if (raw is Map && raw['answers'] is Map) {
      _answers.addAll(
        (raw['answers'] as Map).map((k, v) => MapEntry(k.toString(), v as int)),
      );
    }
  }

  bool get _complete => _answers.length >= kMorals.length;

  double get _percent {
    if (!_complete) return 0;
    final sum = _answers.values.fold(0, (a, b) => a + b);
    return sum / (kMorals.length * 3);
  }

  List<Moral> get _weakest =>
      kMorals.where((m) => (_answers[m.id] ?? 0) <= 1).toList();

  List<Moral> get _strongest =>
      kMorals.where((m) => (_answers[m.id] ?? 0) == 3).toList();

  Future<void> _save() async {
    final box = ref.read(hiveBoxProvider);
    final percent = _percent;
    await box.put('morals_last', {
      'answers': _answers,
      'percent': percent,
      'at': DateTime.now().toIso8601String(),
    });
    final hist = (box.get('morals_history', defaultValue: const []) as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    hist.add({
      'percent': percent,
      'at': DateTime.now().toIso8601String(),
    });
    if (hist.length > 30) hist.removeAt(0);
    await box.put('morals_history', hist);
  }

  String get _verdict {
    final p = _percent;
    if (p >= 0.9) return 'ما شاء الله — أخلاق كريمة راسخة، ثبّتك الله 🌟';
    if (p >= 0.7) return 'مستوى رفيع — ركّز على الثغرات الأدنى';
    if (p >= 0.5) return 'جيد — لكن الرحلة أهم من السرعة، اثبت';
    if (p >= 0.3) return 'منتصف الطريق — ابدأ من الأضعف ثم اصعد';
    return 'كل بناءٍ عظيم يبدأ بخطوة — اليوم أحسن من أمس 🤍';
  }

  @override
  Widget build(BuildContext context) {
    final box = ref.watch(hiveBoxProvider);
    final history = box.get('morals_history', defaultValue: const []) as List;
    final lastRaw = box.get('morals_last');

    // ── لم يقيّم بعد: شاشة تعليمات ────────────────────────────
    if (lastRaw == null && !_complete) return _intro();

    return ListView(padding: const EdgeInsets.all(16), children: [
      // ── بطاقة النسبة ──────────────────────────────────────
      OrnamentedCard(
        color: AppColors.emerald,
        child: Column(children: [
          const Text('مؤشر التزامك بالأخلاق الكريمة',
              style: TextStyle(color: Colors.white, fontSize: 15, height: 1.6)),
          const SizedBox(height: 12),
          SizedBox(
            width: 130,
            height: 130,
            child: Stack(alignment: Alignment.center, children: [
              CircularProgressIndicator(
                value: _complete ? _percent : (lastRaw?['percent'] as double? ?? 0),
                strokeWidth: 10,
                backgroundColor: Colors.white24,
                color: AppColors.goldLight,
              ),
              Text(
                _complete
                    ? '${toArabicDigits((_percent * 100).round())}٪'
                    : lastRaw == null
                        ? '—'
                        : '${toArabicDigits(((lastRaw['percent'] as double) * 100).round())}٪',
                style: AppTheme.amiri(28, color: Colors.white),
              ),
            ]),
          ),
          const SizedBox(height: 8),
          Text(
            _complete ? _verdict : 'تقييمك السابق — جدّد نفسك كل أسبوع',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.7),
          ),
        ]),
      ),
      const SizedBox(height: 12),

      // ── تحليل القوة والضعف ─────────────────────────────────
      if (_complete || _answers.isNotEmpty) ...[
        SectionTitle('نقاط قوتك 🟢 (${_strongest.length})'),
        const SizedBox(height: 6),
        if (_strongest.isEmpty)
          const OrnamentedCard(
              child: Text('لا يوجد — ورحلة الألف ميل تبدأ بخطوة',
                  style: TextStyle(fontSize: 12.5, height: 1.7)))
        else
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final m in _strongest)
              Chip(
                avatar: Text(m.emoji),
                label: Text(m.name, style: const TextStyle(fontSize: 11)),
                backgroundColor: AppColors.success.withValues(alpha: 0.15),
                side: BorderSide.none,
              ),
          ]),
        const SizedBox(height: 14),
        SectionTitle('ركّز على 💪 (${_weakest.length})'),
        const SizedBox(height: 6),
        for (final m in _weakest.take(4))
          OrnamentedCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${m.emoji} ${m.name}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              Text('${m.explanation.split('،').first.trim()}، والبداية من:',
                  style: const TextStyle(fontSize: 12.5, height: 1.8)),
              Text('🎯 ${m.application}',
                  style: const TextStyle(fontSize: 12.5, height: 1.8, color: AppColors.emerald)),
            ]),
          ),
        const SizedBox(height: 6),
      ],

      // ── سجل التقييمات ──────────────────────────────────────
      if (history.length >= 2)
        OrnamentedCard(
          color: AppColors.gold.withValues(alpha: 0.08),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('📈 مسارك عبر الأسبوع',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (final h in history.cast<Map>().skip(
                    history.length > 6 ? history.length - 6 : 0).toList())
                  _histBar((h['percent'] as num).toDouble()),
              ],
            ),
          ]),
        ),
      const SizedBox(height: 12),

      // ── زر التقييم/التجديد ─────────────────────────────────
      FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.emerald,
          minimumSize: const Size.fromHeight(50),
        ),
        icon: const Icon(Icons.rate_review_rounded),
        label: Text(_complete
            ? 'احفظ نتيجة التقييم ✅'
            : lastRaw == null
                ? 'ابدأ تقييم نفسك'
                : 'أعِد التقييم الأسبوعي'),
        onPressed: () {
          if (_complete) {
            _save().then((_) {
              if (context.mounted) {
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text(
                        '✅ حُفظ تقييمك — عود الأسبوع القادم وشاهد مسارك يرتفع بإذن الله')));
              }
            });
          } else {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (ctx) => _AssessmentSheet(
                answers: _answers,
                onChanged: () {
                  setState(() {});
                  if (_complete) {
                    _save().then((_) {
                      if (ctx.mounted) Navigator.pop(ctx);
                    });
                  }
                },
              ),
            );
          }
        },
      ),
      const SizedBox(height: 16),
    ]);
  }

  Widget _intro() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🪞', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 12),
          Text('مرآة الأخلاق', style: AppTheme.amiri(22, color: AppColors.emerald)),
          const SizedBox(height: 8),
          const Text(
            'قيّم نفسك أسبوعياً على ١٥ خلقاً كريماً بصدقٍ مع نفسك،\nوراقب ارتفاع مؤشر التزامك في سجلّ بياني يحفظه «مُلتزم» على جهازك.\n\nالصدق مع النفس أول خطوات الإصلاح 🤍',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, height: 1.9, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.emerald),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('ابدأ التقييم الأول'),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (ctx) => _AssessmentSheet(
                answers: _answers,
                onChanged: () {
                  setState(() {});
                  if (_complete) {
                    _save().then((_) {
                      if (ctx.mounted) Navigator.pop(ctx);
                    });
                  }
                },
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _histBar(double percent) => Column(children: [
        Text('${(percent * 100).round()}٪',
            style: const TextStyle(fontSize: 10, color: AppColors.emerald)),
        const SizedBox(height: 4),
        Container(
          width: 22,
          height: (70 * percent).clamp(8, 70),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [AppColors.emerald, AppColors.gold],
            ),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ]);
}

/// ورقة التقييم — ١٥ خلقاً × خيار من ٤ مستويات
class _AssessmentSheet extends StatefulWidget {
  const _AssessmentSheet({required this.answers, required this.onChanged});

  final Map<String, int> answers;
  final VoidCallback onChanged;

  @override
  State<_AssessmentSheet> createState() => _AssessmentSheetState();
}

class _AssessmentSheetState extends State<_AssessmentSheet> {
  @override
  Widget build(BuildContext context) {
    final done = widget.answers.length;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (ctx, controller) => Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            Text('تقييمك الذاتي (${toArabicDigits(done)}/${toArabicDigits(kMorals.length)})',
                style: AppTheme.amiri(17, color: AppColors.emerald)),
            const Spacer(),
            if (done >= kMorals.length)
              const Text('اكتمل ✓',
                  style: TextStyle(
                      color: AppColors.success, fontWeight: FontWeight.bold)),
          ]),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: done / kMorals.length,
              minHeight: 6,
              backgroundColor: AppColors.gold.withValues(alpha: 0.2),
              color: AppColors.emerald,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(20),
            children: [
              for (final m in kMorals)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: OrnamentedCard(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${m.emoji} ${m.name}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 2),
                          Text(
                            'كيف أجد نفسي في «${m.explanation.split('،').first.trim()}»؟',
                            style: const TextStyle(
                                fontSize: 11.5, color: AppColors.inkSoft),
                          ),
                          const SizedBox(height: 8),
                          Row(children: [
                            for (final (label, emo, val) in kCommitmentLevels)
                              Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 2),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () {
                                      widget.answers[m.id] = val;
                                      widget.onChanged();
                                      setState(() {});
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      decoration: BoxDecoration(
                                        color:
                                            widget.answers[m.id] == val
                                                ? AppColors.emerald
                                                : AppColors.gold
                                                    .withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.gold
                                              .withValues(alpha: 0.35),
                                        ),
                                      ),
                                      child: Column(children: [
                                        Text(emo,
                                            style:
                                                const TextStyle(fontSize: 14)),
                                        Text(label,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              height: 1.4,
                                              color:
                                                  widget.answers[m.id] == val
                                                      ? Colors.white
                                                      : AppColors.ink,
                                            )),
                                      ]),
                                    ),
                                  ),
                                ),
                            ),
                          ]),
                        ]),
                  ),
                ),
            ],
          ),
        ),
      ]),
    );
  }
}
