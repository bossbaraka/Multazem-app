import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/prayer_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/islamic.dart';

/// السبحة الرقمية — عدّاد لمس كبير، اهتزاز عند الاكتمال،
/// إجمالي تراكمي محفوظ في Hive، وأذكار جاهزة + مخصص.
class TasbihScreen extends ConsumerStatefulWidget {
  const TasbihScreen({super.key});

  @override
  ConsumerState<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends ConsumerState<TasbihScreen> {
  static const _presets = <(String, String)>[
    ('سبحان الله', 'سُبْحَانَ اللَّهِ'),
    ('الحمد لله', 'الْحَمْدُ لِلَّهِ'),
    ('الله أكبر', 'اللَّهُ أَكْبَرُ'),
    ('التهليل', 'لَا إِلَهَ إِلَّا اللَّهُ'),
    ('الاستغفار', 'أَسْتَغْفِرُ اللَّهَ'),
    ('الصلاة على النبي ﷺ', 'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ'),
    ('الباقيات الصالحات', 'سُبْحَانَ اللَّهِ وَالْحَمْدُ لِلَّهِ وَلَا إِلَهَ إِلَّا اللَّهُ وَاللَّهُ أَكْبَرُ'),
  ];

  static const _targets = [33, 100, 500];

  String _label = _presets.first.$1;
  String _phrase = _presets.first.$2;
  int _target = 33;
  int _count = 0;
  bool _targetDone = false;

  int get _total =>
      ref.read(hiveBoxProvider).get('tasbih_total', defaultValue: 0) as int;

  Future<void> _tap() async {
    HapticFeedback.lightImpact();
    var done = false;
    setState(() {
      if (_targetDone) {
        // دورة جديدة
        _count = 1;
        _targetDone = false;
      } else {
        _count++;
        if (_count >= _target) {
          _targetDone = true;
          done = true;
        }
      }
    });

    final box = ref.read(hiveBoxProvider);
    await box.put('tasbih_total', _total + 1);

    if (done) {
      HapticFeedback.mediumImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('ما شاء الله! أتممت ${toArabicDigits(_target)} من «$_label» ✨'),
          ),
        );
      }
    }
  }

  void _pickPreset(int i) {
    setState(() {
      _label = _presets[i].$1;
      _phrase = _presets[i].$2;
      _count = 0;
      _targetDone = false;
    });
  }

  Future<void> _customPhrase() async {
    final c = TextEditingController();
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('سبحة مخصصة', style: AppTheme.amiri(19, color: AppColors.emerald)),
          const SizedBox(height: 12),
          TextField(
            controller: c,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'اكتب الذكر أو الدعاء…',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.emerald),
              onPressed: () => Navigator.pop(ctx, c.text.trim()),
              child: const Text('ابدأ'),
            ),
          ),
        ]),
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() {
        _label = 'مخصص';
        _phrase = result;
        _count = 0;
        _targetDone = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final box = ref.watch(hiveBoxProvider);
    final total = box.get('tasbih_total', defaultValue: 0) as int;
    final progress = _count / _target;

    return Scaffold(
      appBar: AppBar(
        title: const Text('السبحة الرقمية'),
        actions: [
          IconButton(
            tooltip: 'تصفير',
            icon: const Icon(Icons.restart_alt),
            onPressed: () => setState(() {
              _count = 0;
              _targetDone = false;
            }),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── الذكر الحالي ─────────────────────────────────────
          OrnamentedCard(
            child: Column(children: [
              Text(_phrase,
                  textAlign: TextAlign.center,
                  style: AppTheme.amiri(22, bold: false)),
              const SizedBox(height: 8),
              Text(_label,
                  style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
            ]),
          ),

          const SizedBox(height: 12),

          // ── السبحة الكبيرة ───────────────────────────────────
          Center(
            child: GestureDetector(
              onTap: _tap,
              child: Stack(alignment: Alignment.center, children: [
                SizedBox(
                  width: 210,
                  height: 210,
                  child: CircularProgressIndicator(
                    value: progress.clamp(0, 1),
                    strokeWidth: 10,
                    backgroundColor: AppColors.gold.withValues(alpha: 0.2),
                    color: _targetDone ? AppColors.success : AppColors.emerald,
                  ),
                ),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                    _targetDone ? Icons.check_circle : Icons.touch_app_rounded,
                    color: _targetDone ? AppColors.success : AppColors.gold,
                    size: 30,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    toArabicDigits(_count),
                    style: AppTheme.amiri(52),
                  ),
                  Text('من ${toArabicDigits(_target)}',
                      style: const TextStyle(color: AppColors.inkSoft)),
                  const SizedBox(height: 4),
                  const Text('المس للعدّ', style: TextStyle(fontSize: 11, color: AppColors.inkSoft)),
                ]),
              ]),
            ),
          ),

          const SizedBox(height: 16),

          // ── الأهداف ──────────────────────────────────────────
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (final t in _targets)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(toArabicDigits(t)),
                  selected: _target == t,
                  onSelected: (_) => setState(() {
                    _target = t;
                    _count = 0;
                    _targetDone = false;
                  }),
                ),
              ),
          ]),

          const SizedBox(height: 14),

          // ── الذَّكَر الجاهز ──────────────────────────────────
          const SectionTitle('أذكار جاهزة'),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (var i = 0; i < _presets.length; i++)
              ChoiceChip(
                label: Text(_presets[i].$1, style: const TextStyle(fontSize: 12)),
                selected: _label == _presets[i].$1,
                selectedColor: AppColors.gold.withValues(alpha: 0.25),
                onSelected: (_) => _pickPreset(i),
              ),
            ActionChip(
              avatar: const Icon(Icons.add, size: 16),
              label: const Text('مخصص', style: TextStyle(fontSize: 12)),
              onPressed: _customPhrase,
            ),
          ]),

          const SizedBox(height: 20),
          const OrnamentDivider(),
          const SizedBox(height: 10),

          // ── الإجمالي التراكمي ────────────────────────────────
          OrnamentedCard(
            color: AppColors.emerald,
            child: Column(children: [
              Text('مجموع تسبيحاتك منذ البدء',
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 6),
              Text(toArabicDigits(total),
                  style: AppTheme.amiri(34, color: AppColors.goldLight)),
              const Text(
                '«كلمتان خفيفتان على اللسان، ثقيلتان في الميزان…» — متفق عليه',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
