import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/prayer_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/islamic.dart';
import '../data/tajweed_data.dart';

/// تبويب الاختبار — ١٢ سؤال تجويد، نتيجة فورية، أفضل نتيجة محفوظة في Hive.
class QuizTab extends ConsumerStatefulWidget {
  const QuizTab({super.key});

  @override
  ConsumerState<QuizTab> createState() => _QuizTabState();
}

class _QuizTabState extends ConsumerState<QuizTab> {
  int _index = 0;
  int _score = 0;
  int? _picked;
  bool _finished = false;

  void _pick(int i) {
    if (_picked != null) return;
    final correct = kTajweedQuiz[_index].answer == i;
    setState(() {
      _picked = i;
      if (correct) _score++;
    });
  }

  void _next() {
    if (_index + 1 >= kTajweedQuiz.length) {
      setState(() => _finished = true);
      final box = ref.read(hiveBoxProvider);
      final best = box.get('quiz_best', defaultValue: 0) as int;
      if (_score > best) box.put('quiz_best', _score);
    } else {
      setState(() {
        _index++;
        _picked = null;
      });
    }
  }

  void _restart() => setState(() {
        _index = 0;
        _score = 0;
        _picked = null;
        _finished = false;
      });

  @override
  Widget build(BuildContext context) {
    final box = ref.watch(hiveBoxProvider);
    final best = box.get('quiz_best', defaultValue: 0) as int;

    if (_finished) return _result(best);
    if (kTajweedQuiz.isEmpty) return const Center(child: Text('لا أسئلة'));

    final q = kTajweedQuiz[_index];
    return ListView(padding: const EdgeInsets.all(16), children: [
      // شريط تقدّم الأسئلة
      Row(children: [
        Text('سؤال ${toArabicDigits(_index + 1)} / ${toArabicDigits(kTajweedQuiz.length)}',
            style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
        const Spacer(),
        const Icon(Icons.star_rounded, color: AppColors.gold, size: 16),
        Text(' أفضل نتيجة: ${toArabicDigits(best)}',
            style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: (_index + 1) / kTajweedQuiz.length,
          minHeight: 7,
          backgroundColor: AppColors.gold.withValues(alpha: 0.2),
          color: AppColors.emerald,
        ),
      ),
      const SizedBox(height: 14),

      OrnamentedCard(
        child: Text(q.q,
            textAlign: TextAlign.center,
            style: AppTheme.amiri(19, bold: false)),
      ),
      const SizedBox(height: 10),

      for (var i = 0; i < q.options.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _option(q, i),
        ),

      if (_picked != null) ...[
        if (q.explain != null)
          OrnamentedCard(
            color: _picked == q.answer
                ? AppColors.success.withValues(alpha: 0.1)
                : AppColors.warning.withValues(alpha: 0.12),
            child: Text(
              (_picked == q.answer ? 'أحسنت! ' : 'الصحيح شرحه: ') + q.explain!,
              style: const TextStyle(fontSize: 13, height: 1.8),
            ),
          ),
        const SizedBox(height: 8),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.emerald),
          onPressed: _next,
          child: Text(_index + 1 == kTajweedQuiz.length ? 'عرض النتيجة' : 'السؤال التالي'),
        ),
      ],
    ]);
  }

  Widget _result(int best) {
    final total = kTajweedQuiz.length;
    final msg = _score == total
        ? 'ممتاز! علامة كاملة — أنت تتقن التجويد نظرياً 🎓'
        : _score >= total * 0.7
            ? 'جيد جداً! راجع الدروس الناقصة في تبويب المنهج'
            : 'لا بأس — ابدأ بالمستوى ١ وأعد الاختبار غداً';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🏆', style: TextStyle(fontSize: 54)),
          const SizedBox(height: 8),
          Text('نتيجتك', style: AppTheme.amiri(20, color: AppColors.emerald)),
          Text('${toArabicDigits(_score)} / ${toArabicDigits(total)}',
              style: AppTheme.amiri(44, color: AppColors.gold)),
          const SizedBox(height: 8),
          Text(msg, textAlign: TextAlign.center,
              style: const TextStyle(height: 1.8, fontSize: 13)),
          const SizedBox(height: 6),
          Text('أفضل نتيجة: ${toArabicDigits(best)}/${toArabicDigits(total)}',
              style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
          const SizedBox(height: 14),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.emerald),
            icon: const Icon(Icons.replay),
            label: const Text('إعادة الاختبار'),
            onPressed: _restart,
          ),
        ]),
      ),
    );
  }

  Widget _option(QuizQ q, int i) {
    final isCorrect = q.answer == i;
    final isPicked = _picked == i;
    Color? bg;
    IconData? icon;
    if (_picked != null) {
      if (isCorrect) {
        bg = AppColors.success.withValues(alpha: 0.14);
        icon = Icons.check_circle;
      } else if (isPicked) {
        bg = AppColors.error.withValues(alpha: 0.1);
        icon = Icons.cancel_outlined;
      }
    }
    return Card(
      color: bg,
      child: ListTile(
        title: Text(q.options[i], style: const TextStyle(fontSize: 14.5)),
        trailing: icon == null ? null : Icon(icon, color: isCorrect ? AppColors.success : AppColors.error),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isPicked || (_picked != null && isCorrect)
                ? (isCorrect ? AppColors.success : AppColors.error)
                : AppColors.gold.withValues(alpha: 0.35),
          ),
        ),
        onTap: () => _pick(i),
      ),
    );
  }
}
