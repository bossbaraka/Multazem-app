import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

/// آية واحدة
class Ayah {
  const Ayah(this.number, this.text);

  final int number;
  final String text;
}

/// مستودع المصحف — نص «الرسم العثماني» من AlQuran Cloud
/// مع **تخزين محلي في Hive**: السورة تُجلب مرة واحدة ثم تعمل Offline تماماً.
class QuranRepository {
  QuranRepository(this._box);

  final Box _box;

  static const _base = 'https://api.alquran.cloud/v1';
  static const _edition = 'quran-uthmani';

  // البسملة بالرسم العثماني كما ترد في مقدمة آيات المصدر
  static const _basmala = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';

  /// آيات سورة (١–١١٤) — من الكاش المحلي أو من الشبكة ثم تُخزَّن
  Future<List<Ayah>> surah(int number) async {
    final cached = _box.get('surah_$number') as String?;
    if (cached != null) {
      final list = (jsonDecode(cached) as List).cast<Map<String, dynamic>>();
      return [for (final e in list) Ayah(e['n'] as int, e['t'] as String)];
    }

    final uri = Uri.parse('$_base/surah/$number/$_edition');
    final res = await http.get(uri).timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) {
      throw Exception('تعذّر تحميل السورة — تحقّق من اتصالك (مرة واحدة فقط)');
    }

    final data = jsonDecode(utf8.decode(res.bodyBytes))['data'];
    final ayahsJson = (data['ayahs'] as List).cast<Map<String, dynamic>>();

    final ayahs = <Ayah>[
      for (final a in ayahsJson)
        Ayah(
          a['numberInSurah'] as int,
          _cleanFirstAyah(number, a['numberInSurah'] as int, a['text'] as String),
        ),
    ];

    await _box.put(
      'surah_$number',
      jsonEncode([for (final a in ayahs) {'n': a.number, 't': a.text}]),
    );
    return ayahs;
  }

  /// إزالة البسملة الممزوجة بأول آية (المصدر يلحقها بداية كل سورة)
  String _cleanFirstAyah(int surahNumber, int ayahNumber, String text) {
    if (ayahNumber != 1 || surahNumber == 1 || surahNumber == 9) return text;
    if (text.startsWith(_basmala)) {
      return text.substring(_basmala.length).trim();
    }
    return text;
  }

  /// تفسير «الميسّر» لآية — كاش محلي دائم في Hive
  Future<String> tafsir(int surah, int ayah) async {
    final key = 'taf_${surah}_$ayah';
    final cached = _box.get(key) as String?;
    if (cached != null) return cached;

    final uri = Uri.parse('$_base/ayah/$surah:$ayah/ar.muyassar');
    final res = await http.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw Exception('تعذّر تحميل التفسير الآن — تحقّق من الاتصال');
    }
    final data = jsonDecode(utf8.decode(res.bodyBytes))['data'];
    final text = data['text'] as String;
    await _box.put(key, text);
    return text;
  }

  bool isCached(int number) => _box.containsKey('surah_$number');

  // ── آخر قراءة ───────────────────────────────────────────────────
  void saveLastRead({required int surah, required String surahName, required int ayah}) {
    _box.put('quran_last', {'surah': surah, 'name': surahName, 'ayah': ayah});
  }

  Map<String, dynamic>? lastRead() {
    final raw = _box.get('quran_last');
    return raw is Map ? Map<String, dynamic>.from(raw) : null;
  }

  // ── حجم خط المصحف ───────────────────────────────────────────────
  double get fontSize => _box.get('quran_font', defaultValue: 24.0) as double;
}

/// رابط تلاوة سورة كاملة — Islamic Network CDN (المشاري العفاسي)
String surahAudioUrl(int surahNumber) =>
    'https://cdn.islamic.network/quran/audio-surah/128/ar.alafasy/$surahNumber.mp3';
