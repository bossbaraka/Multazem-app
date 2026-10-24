import 'package:adhan/adhan.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri.dart';
import 'package:hive/hive.dart';

// ── التخزين والموقع ────────────────────────────────────────────────────
/// صندوق Hive الرئيسي — يُحقن من main.dart بعد الفتح.
final hiveBoxProvider = Provider<Box>(
  (ref) => throw UnimplementedError('hiveBoxProvider must be overridden in main'),
);

/// إحداثيات مواقيت الصلاة (تُبدأ بالمحفوظ من main ثم تتحدث من إعدادات الموقع)
final coordinatesProvider = StateProvider<Coordinates>(
  (ref) => Coordinates(31.5017, 34.4668),
);

final cityNameProvider = StateProvider<String>((ref) => 'غزة');

final calculationParamsProvider = Provider<CalculationParameters>((ref) {
  final params = CalculationMethod.umm_al_qura.getParameters();
  params.madhab = Madhab.shafi; // TODO(الإعدادات): حنفي ⇐ Madhab.hanafi
  return params;
});

// ── مواقيت اليوم ───────────────────────────────────────────────────────
final prayerTimesProvider = Provider<PrayerTimes>((ref) {
  final coords = ref.watch(coordinatesProvider);
  final params = ref.watch(calculationParamsProvider);
  return PrayerTimes.today(coords, params);
});

/// الصلاة القادمة + وقتها (مع ترحيلها لفجر الغد بعد العشاء)
final nextPrayerProvider = Provider<({Prayer prayer, DateTime time})>((ref) {
  final coords = ref.watch(coordinatesProvider);
  final params = ref.watch(calculationParamsProvider);
  final today = PrayerTimes.today(coords, params);

  final next = today.nextPrayer();
  if (next != Prayer.none) {
    return (prayer: next, time: today.timeForPrayer(next)!);
  }
  final tomorrow = PrayerTimes(
    coords,
    DateComponents.from(DateTime.now().add(const Duration(days: 1))),
    params,
  );
  return (prayer: Prayer.fajr, time: tomorrow.fajr);
});

// ── التاريخ الهجري ────────────────────────────────────────────────────
final hijriTodayProvider = Provider<HijriCalendar>((ref) => HijriCalendar.now());

const kHijriMonths = [
  'محرم', 'صفر', 'ربيع الأول', 'ربيع الآخر', 'جمادى الأولى', 'جمادى الآخرة',
  'رجب', 'شعبان', 'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة',
];

String formatHijri(HijriCalendar h) =>
    '${toArabicDigits(h.hDay)} ${kHijriMonths[h.hMonth - 1]} ${toArabicDigits(h.hYear)}هـ';

// ── الصلوات الخمس (للجداول والإشعارات) ─────────────────────────────────
/// (مفتاح التخزين، الاسم العربي) — بدون الشروق (لا أذان له)
const kFivePrayers = <(String, String)>[
  ('fajr', 'الفجر'),
  ('dhuhr', 'الظهر'),
  ('asr', 'العصر'),
  ('maghrib', 'المغرب'),
  ('isha', 'العشاء'),
];

/// معرّف إشعار ثابت لكل صلاة (١٠٠–١٠٤)
int prayerAdhanId(String key) => 100 + kFivePrayers.indexWhere((p) => p.$1 == key);

DateTime? timeOf(PrayerTimes t, String key) => switch (key) {
      'fajr' => t.fajr,
      'dhuhr' => t.dhuhr,
      'asr' => t.asr,
      'maghrib' => t.maghrib,
      'isha' => t.isha,
      _ => null,
    };

// ── أدوات عرض ─────────────────────────────────────────────────────────
const kPrayerNames = {
  Prayer.fajr: 'الفجر',
  Prayer.sunrise: 'الشروق',
  Prayer.dhuhr: 'الظهر',
  Prayer.asr: 'العصر',
  Prayer.maghrib: 'المغرب',
  Prayer.isha: 'العشاء',
};

String prayerName(Prayer p) => kPrayerNames[p] ?? '';

/// تحويل الأرقام إلى عربية-مشرقية (٠١٢٣…)
String toArabicDigits(Object n) {
  const en = '0123456789';
  const ar = '٠١٢٣٤٥٦٧٨٩';
  final s = n.toString();
  return s.split('').map((c) {
    final i = en.indexOf(c);
    return i >= 0 ? ar[i] : c;
  }).join();
}

String formatTime(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final m = t.minute.toString().padLeft(2, '0');
  final period = t.hour < 12 ? 'ص' : 'م';
  return '${toArabicDigits('$h:$m')} $period';
}
