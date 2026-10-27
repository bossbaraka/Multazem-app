import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/providers/prayer_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/islamic.dart';
import '../../quran/data/surah_index.dart';

/// تبويب التلقين — «اسمع وكرّر»:
/// آيات مقطّعة (صوت آية-بآية من Islamic Network CDN بصوت العفاسي)
/// مع محاولات تكرار مضبوطة، وتلميح لكل آية بالقراءة قبل الانتقال.
class RepeatModeTab extends ConsumerStatefulWidget {
  const RepeatModeTab({super.key});

  @override
  ConsumerState<RepeatModeTab> createState() => _RepeatModeTabState();
}

class _RepeatModeTabState extends ConsumerState<RepeatModeTab> {
  final _player = AudioPlayer();
  SurahMeta _surah = kSurahIndex.first;
  int _ayah = 1;
  int _repeatsTarget = 3;
  int _played = 0;
  bool _playing = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  /// رقم الآية المطلق (١–٦٢٣٦) لمقطع الصوت
  int _globalAyah(int surahNumber, int ayahInSurah) {
    var offset = 1;
    for (final s in kSurahIndex) {
      if (s.number == surahNumber) break;
      offset += s.ayahs;
    }
    return offset + ayahInSurah - 1;
  }

  Future<void> _togglePlay() async {
    if (_playing) {
      await _player.pause();
      setState(() => _playing = false);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _played = 0;
      _playing = true;
    });
    try {
      await _loadAndPlay();
    } catch (_) {
      setState(() {
        _loading = false;
        _error = 'تعذّر تشغيل التلاوة — تحقّق من الاتصال';
      });
    }
  }

  Future<void> _loadAndPlay() async {
    final global = _globalAyah(_surah.number, _ayah);
    await _player.setUrl(
      'https://cdn.islamic.network/quran/audio/128/ar.alafasy/$global.mp3',
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _playing = true;
    });
    // كرّر الآية بالعدد المطلوب (مع وقفة صغيرة بين التكرارات للترديد)
    for (var i = 0; i < _repeatsTarget; i++) {
      if (!mounted || !_playing) return;
      setState(() => _played = i + 1);
      await _player.seek(Duration.zero);
      await _player.play(); // يكتمل await عند انتهاء الآية
      if (i < _repeatsTarget - 1) {
        await Future.delayed(const Duration(milliseconds: 900));
      }
    }
    if (mounted) setState(() => _playing = false);
  }

  void _nextAyah() {
    if (_ayah < _surah.ayahs) {
      setState(() {
        _ayah++;
        _played = 0;
        _playing = false;
      });
      _player.stop();
    }
  }

  void _prevAyah() {
    if (_ayah > 1) {
      setState(() {
        _ayah--;
        _played = 0;
        _playing = false;
      });
      _player.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      const OrnamentedCard(
        color: AppColors.emerald,
        child: Column(children: [
          Text('«اسمع وكرِّر» — أجود طرق الحفظ 🎧',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text(
            'اختر السورة والآية، وحدّد عدد التكرارات، وسيُشغّل «مُلتزم» الآية بصوت العفاسي كرّةً بعد كرّة حتى تتقنها.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.8),
          ),
        ]),
      ),
      const SizedBox(height: 12),

      // اختيار السورة
      OrnamentedCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('السورة', style: TextStyle(fontSize: 12, color: AppColors.inkSoft)),
          const SizedBox(height: 6),
          DropdownButton<int>(
            isExpanded: true,
            value: _surah.number,
            underline: const SizedBox(),
            items: [
              for (final s in kSurahIndex)
                DropdownMenuItem(
                  value: s.number,
                  child: Text('${s.number}. سورة ${s.name} (${toArabicDigits(s.ayahs)} آية)',
                      style: const TextStyle(fontSize: 13)),
                ),
            ],
            onChanged: (v) {
              final s = kSurahIndex.firstWhere((s) => s.number == v);
              setState(() {
                _surah = s;
                _ayah = 1;
                _played = 0;
                _playing = false;
              });
              _player.stop();
            },
          ),
          const SizedBox(height: 12),
          // اختيار الآية
          Row(children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: AppColors.emerald),
              onPressed: _prevAyah,
            ),
            Expanded(
              child: Center(
                child: Text(
                  'الآية ${toArabicDigits(_ayah)} من ${toArabicDigits(_surah.ayahs)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: AppColors.emerald),
              onPressed: _nextAyah,
            ),
          ]),
          Slider(
            value: _ayah.toDouble(),
            min: 1,
            max: _surah.ayahs.toDouble(),
            activeColor: AppColors.gold,
            onChanged: (v) => setState(() {
              _ayah = v.round();
              _played = 0;
              _playing = false;
              _player.stop();
            }),
          ),
          const SizedBox(height: 6),
          // عدد التكرارات
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('كرّر: ', style: TextStyle(fontSize: 13)),
            for (final n in [1, 3, 5, 7])
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(toArabicDigits(n)),
                  selected: _repeatsTarget == n,
                  selectedColor: AppColors.gold.withValues(alpha: 0.25),
                  onSelected: (_) => setState(() => _repeatsTarget = n),
                ),
              ),
          ]),
        ]),
      ),
      const SizedBox(height: 12),

      // مشغّل التلقين
      OrnamentedCard(
        child: Column(children: [
          Text('سورة ${_surah.name} — الآية ${toArabicDigits(_ayah)}',
              style: GoogleFonts.amiri(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.emerald)),
          const SizedBox(height: 12),
          if (_played > 0)
            Text('استمعت: ${toArabicDigits(_played)} / ${toArabicDigits(_repeatsTarget)} مرات',
                style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(
              tooltip: 'الآية السابقة',
              icon: const Icon(Icons.skip_previous_rounded),
              iconSize: 32,
              color: AppColors.emerald,
              onPressed: _prevAyah,
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _togglePlay,
              child: Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  gradient: AppColors.headerGradient,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _loading
                      ? Icons.hourglass_top
                      : _playing
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                  color: AppColors.goldLight,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              tooltip: 'الآية التالية',
              icon: const Icon(Icons.skip_next_rounded),
              iconSize: 32,
              color: AppColors.emerald,
              onPressed: _nextAyah,
            ),
          ]),
          const SizedBox(height: 8),
          Text(
            _played >= _repeatsTarget && _played > 0
                ? '✨ أتممت التكرار — كرّر أنت بصوت مرتفع ثم انتقل'
                : 'اضغط ▶ واسمع الآية ${_repeatsTarget == 1 ? 'مرة' : '$toArabicDigits(_repeatsTarget) مرات'}، ثم ردّدها خلف القارئ',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.inkSoft, height: 1.8),
          ),
        ]),
      ),

      const SizedBox(height: 10),
      OrnamentedCard(
        color: AppColors.gold.withValues(alpha: 0.08),
        child: const Text(
          '💡 منهجية أهل القرآن في الحفظ: اقرأ الصفحة غيباً ١٠ مرات، ثم اربط المعاني، ثم راجع عند النوم وعند الفجر — ليستعصم الحفظ.',
          style: TextStyle(fontSize: 12.5, height: 1.9),
        ),
      ),
    ]);
  }
}
