import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/providers/prayer_providers.dart';
import 'core/services/location_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/reminder_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ١) التخزين المحلي (سجل الصلوات، الموقع، تفضيلات الأذان…)
  await Hive.initFlutter();
  final box = await Hive.openBox('multazim');

  // تنسيق التواريخ بالعربية (الهجرية الميلادية في الواجهات)
  await initializeDateFormatting('ar');

  // ٢) الإشعارات
  await NotificationService.init();

  // ٣) الموقع المحفوظ (أو الافتراضي) ثم جدولة أذان اليوم
  final saved = LocationService.loadSaved(box);
  final coords = Coordinates(saved.latitude, saved.longitude);
  try {
    await _scheduleTodayAdhan(box, coords);
  } catch (e) {
    debugPrint('تعذّرت جدولة الأذان: $e');
  }
  try {
    await ReminderService.applyAll(box); // تذكيرات الأذكار/الكهف/الصدقة…
  } catch (e) {
    debugPrint('تعذّرت جدولة التذكيرات: $e');
  }

  // شريط الحالة شفاف فوق تدرّجنا الزمرّدي
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(ProviderScope(
    overrides: [
      hiveBoxProvider.overrideWithValue(box),
      coordinatesProvider.overrideWith((ref) => coords),
      cityNameProvider.overrideWith((ref) => saved.city),
    ],
    child: const MultazimApp(),
  ));
}

/// جدولة أذان الصلوات الخمس لليوم مع احترام مفتاح كل صلاة من الإعدادات.
/// (تُعاد الجدولة تلقائياً في كل فتح للتطبيق — نمط شائع للمواقيت المتغيرة يومياً)
Future<void> _scheduleTodayAdhan(Box box, Coordinates coords) async {
  final params = CalculationMethod.umm_al_qura.getParameters();
  params.madhab = Madhab.shafi;
  final times = PrayerTimes.today(coords, params);

  for (final (key, arabicName) in kFivePrayers) {
    final mode = box.get('adhan_$key', defaultValue: 'أذان كامل') as String;
    final id = prayerAdhanId(key);

    if (mode == 'إيقاف') {
      await NotificationService.cancel(id);
      continue;
    }
    final t = timeOf(times, key);
    if (t == null) continue;

    await NotificationService.schedulePrayerAdhan(
      id: id,
      prayerName: arabicName,
      time: t,
      withSound: mode == 'أذان كامل',
    );
  }
}
