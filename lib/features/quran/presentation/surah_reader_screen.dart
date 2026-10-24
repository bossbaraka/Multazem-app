import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/providers/prayer_providers.dart' show hiveBoxProvider;
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/islamic.dart';
import '../data/quran_repository.dart';
import '../data/surah_index.dart';

/// قارئ المصحف — نص عثماني متصل (صفاء قراءة) مع:
/// حجم خط قابل للتعديل · علامة «آخر قراءة» (ضغطة مطوّلة) · تلاوة السورة كاملة.
class SurahReaderScreen extends ConsumerStatefulWidget {
  const SurahReaderScreen({super.key, required this.surah});

  final SurahMeta surah;

  @override
  ConsumerState<SurahReaderScreen> createState() => _SurahReaderScreenState();
}

class _SurahReaderScreenState extends ConsumerState<SurahReaderScreen> {
  late Future<List<Ayah>> _future;
  late final QuranRepository _repo;

  @override
  void initState() {
    super.initState();
    _repo = QuranRepository(HiveSingleton.box(ref));
    _future = _repo.surah(widget.surah.number);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.surah;
    final box = HiveSingleton.box(ref);

    return Scaffold(
      appBar: AppBar(
        title: Text('سورة ${s.name}'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(2),
          child: Divider(height: 2),
        ),
      ),
      bottomNavigationBar: _AudioBar(
        surahNumber: s.number,
        surahName: s.name,
      ),
      body: FutureBuilder<List<Ayah>>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) {
            return _ErrorView(
              message: '${snap.error}',
              onRetry: () => setState(() => _future = _repo.surah(s.number)),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final ayahs = snap.data!;
          // يعيد البناء تلقائياً عند تغيير حجم الخط/العلامة
          return ValueListenableBuilder(
            valueListenable: box.listenable(keys: const ['quran_font', 'quran_last']),
            builder: (context, _, __) {
              final font = _repo.fontSize;
              final lastAyah = (_repo.lastRead()?['surah'] == s.number)
                  ? _repo.lastRead()?['ayah'] as int?
                  : null;

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                children: [
                  // ── الترويسة + البسملة ──────────────────────────
                  Text(
                    '﴿ سورة ${s.name} ﴾',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.amiri(
                        fontSize: font + 4, fontWeight: FontWeight.bold, color: AppColors.emerald),
                  ),
                  Text(
                    '${s.revelation} · آياتها ${s.ayahs}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.inkSoft, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  if (s.number != 9)
                    Text(
                      'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.amiri(fontSize: font + 2),
                    ),
                  const OrnamentDivider(),
                  const SizedBox(height: 12),

                  // ── نص السورة متصلاً ────────────────────────────
                  SelectableText.rich(
                    TextSpan(
                      style: GoogleFonts.amiri(
                        fontSize: font,
                        height: 1.95,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                      children: [
                        for (final a in ayahs) ...[
                          if (a.number == lastAyah) const TextSpan(text: '🔖 '),
                          TextSpan(
                            text: a.text,
                            // اضغط أي آية ⇐ تفسيرها الميسّر + خيارات
                            recognizer: TapGestureRecognizer()
                              ..onTap = () =>
                                  _showAyahSheet(context, _repo, widget.surah, a),
                          ),
                          TextSpan(
                            text: ' ﴿${a.number}﴾ ',
                            style: const TextStyle(color: AppColors.gold),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () =>
                                  _showAyahSheet(context, _repo, widget.surah, a),
                          ),
                        ],
                      ],
                    ),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 16),

                  // ── تثبيت آخر قراءة عند نهاية السورة ────────────
                  OutlinedButton.icon(
                    icon: const Icon(Icons.bookmark_add_outlined),
                    label: Text(
                      lastAyah == null
                          ? 'ثبّت علامة «آخر قراءة» عند نهاية السورة'
                          : 'علامتك حالياً عند الآية $lastAyah — اضغط للانتقال لسورة تالية',
                    ),
                    onPressed: () {
                      _repo.saveLastRead(
                          surah: s.number, surahName: s.name, ayah: ayahs.last.number);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                '📖 تم حفظ آخر قراءة: سورة ${s.name} — الآية ${ayahs.last.number}')),
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// شريط تشغيل تلاوة السورة (المشاري العفاسي — بثّ مباشر)
class _AudioBar extends StatefulWidget {
  const _AudioBar({required this.surahNumber, required this.surahName});

  final int surahNumber;
  final String surahName;

  @override
  State<_AudioBar> createState() => _AudioBarState();
}

class _AudioBarState extends State<_AudioBar> {
  final _player = AudioPlayer();
  bool _loading = false;
  bool _ready = false;
  bool _error = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _ensureLoaded() async {
    if (_ready) return;
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      await _player.setUrl(surahAudioUrl(widget.surahNumber));
      _ready = true;
    } catch (_) {
      _error = true;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: AppColors.headerGradient,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Row(children: [
          StreamBuilder<bool>(
            stream: _player.playingStream,
            builder: (context, snap) {
              final playing = snap.data ?? false;
              return IconButton(
                iconSize: 36,
                color: AppColors.goldLight,
                onPressed: () async {
                  await _ensureLoaded();
                  if (_error) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تعذّر تشغيل التلاوة — تحقّق من الاتصال')),
                      );
                    }
                    return;
                  }
                  playing ? _player.pause() : _player.play();
                },
                icon: _loading
                    ? const SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.goldLight))
                    : Icon(playing
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_fill_rounded),
              );
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('تلاوة سورة ${widget.surahName}',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              StreamBuilder<Duration>(
                stream: _player.positionStream,
                builder: (context, snap) {
                  final pos = snap.data ?? Duration.zero;
                  final total = _player.duration ?? Duration.zero;
                  return Text(
                    total == Duration.zero
                        ? 'مشاري راشد العفاسي · بثّ مباشر'
                        : '${_fmt(pos)} / ${_fmt(total)}',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75), fontSize: 11),
                  );
                },
              ),
            ]),
          ),
          IconButton(
            color: Colors.white,
            icon: const Icon(Icons.stop_rounded),
            onPressed: () => _player.stop(),
          ),
        ]),
      ),
    );
  }

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off_rounded, size: 44, color: AppColors.inkSoft),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
          ),
        ]),
      ),
    );
  }
}

// وصول سريع لصندوق Hive المفتوح من main
class HiveSingleton {
  static box(WidgetRef ref) => ref.read(hiveBoxProvider);
}

/// قائمة الآية — تفسير ميسّر + نسخ + تثبيت «آخر قراءة»
void _showAyahSheet(
    BuildContext context, QuranRepository repo, SurahMeta surah, Ayah ayah) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _AyahSheet(repo: repo, surah: surah, ayah: ayah),
  );
}

class _AyahSheet extends StatelessWidget {
  const _AyahSheet({required this.repo, required this.surah, required this.ayah});

  final QuranRepository repo;
  final SurahMeta surah;
  final Ayah ayah;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      maxChildSize: 0.9,
      builder: (ctx, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Text('سورة ${surah.name} · الآية ${ayah.number}',
              textAlign: TextAlign.center,
              style: GoogleFonts.amiri(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: AppColors.emerald)),
          const SizedBox(height: 10),
          OrnamentedCard(
            color: AppColors.gold.withValues(alpha: 0.07),
            child: Text(
              ayah.text,
              textAlign: TextAlign.justify,
              style: GoogleFonts.amiri(fontSize: 18, height: 1.85),
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('نسخ الآية'),
                onPressed: () {
                  Clipboard.setData(ClipboardData(
                      text: '${ayah.text} ﴿${ayah.number}﴾ [سورة ${surah.name}]'));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('نُسخت الآية 📋')),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: AppColors.emerald),
                icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                label: const Text('ثبّت كآخر قراءة'),
                onPressed: () {
                  repo.saveLastRead(
                      surah: surah.number,
                      surahName: surah.name,
                      ayah: ayah.number);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            '🔖 علامتك: ${surah.name} — الآية ${ayah.number}')),
                  );
                },
              ),
            ),
          ]),
          const SizedBox(height: 16),
          const SectionTitle('التفسير الميسّر'),
          const SizedBox(height: 8),
          FutureBuilder<String>(
            future: repo.tafsir(surah.number, ayah.number),
            builder: (context, snap) {
              if (snap.hasError) {
                return const Text('تعذّر تحميل التفسير الآن — يُعرض لاحقاً بإذن الله',
                    style: TextStyle(color: AppColors.warning));
              }
              if (!snap.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return OrnamentedCard(
                child: Text(snap.data!,
                    style: const TextStyle(fontSize: 14.5, height: 1.95)),
              );
            },
          ),
        ],
      ),
    );
  }
}
