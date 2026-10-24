import 'package:hive/hive.dart';

import 'notification_service.dart';

/// مفاتيح التذكيرات الافتراضية + جدولتها/إلغاؤها من مفاتيح الإعدادات.
class ReminderService {
  ReminderService._();

  /// المفتاح ⇐ القيمة الافتراضية
  static const defaults = <String, bool>{
    'rem_adhkar_sabah': true,   // أذكار الصباح ٦:٠٠
    'rem_adhkar_masaa': true,   // أذكار المساء ١٦:٠٠
    'rem_wird': true,           // الورد القرآني ٢٠:٠٠
    'rem_kahf': true,           // الكهف — الجمعة ٩:٠٠
    'rem_fast': false,          // الاثنين والخميس ٧:٠٠
    'rem_sadaqa_friday': false, // صدقة الجمعة ١٠:٠٠
    'rem_sleep': true,          // أذكار النوم ٢٢:٠٠
  };

  static bool isOn(Box box, String key) =>
      box.get(key, defaultValue: defaults[key] ?? false) as bool;

  static Future<void> set(Box box, String key, bool value) async {
    await box.put(key, value);
    if (value) {
      await _schedule(key);
    } else {
      await _cancel(key);
    }
  }

  /// تطبيق كل المفاتيح (عند فتح التطبيق)
  static Future<void> applyAll(Box box) async {
    for (final key in defaults.keys) {
      if (isOn(box, key)) await _schedule(key);
    }
  }

  static Future<void> _cancel(String key) async {
    for (final id in _ids[key] ?? const <int>[]) {
      await NotificationService.cancel(id);
    }
  }

  static const _ids = {
    'rem_adhkar_sabah': [200],
    'rem_adhkar_masaa': [201],
    'rem_wird': [202],
    'rem_kahf': [203],
    'rem_fast': [204, 205],
    'rem_sadaqa_friday': [206],
    'rem_sleep': [207],
  };

  static Future<void> _schedule(String key) async {
    switch (key) {
      case 'rem_adhkar_sabah':
        await NotificationService.scheduleDaily(
            id: 200, title: 'أذكار الصباح 🌅', body: 'احفظ يومك بأذكار الصباح', hour: 6, minute: 0);
      case 'rem_adhkar_masaa':
        await NotificationService.scheduleDaily(
            id: 201, title: 'أذكار المساء 🌇', body: 'اختِم نهارك بأذكار المساء', hour: 16, minute: 0);
      case 'rem_wird':
        await NotificationService.scheduleDaily(
            id: 202, title: 'وردك القرآني 📖', body: 'لا يمضي يومك بلا قرآن', hour: 20, minute: 0);
      case 'rem_kahf':
        await NotificationService.scheduleWeekly(
            id: 203,
            title: 'يوم الجمعة 📿',
            body: 'لا تنسَ سورة الكهف والصلاة على النبي ﷺ',
            weekday: DateTime.friday,
            hour: 9,
            minute: 0);
      case 'rem_fast':
        await NotificationService.scheduleWeekly(
            id: 204, title: 'صيام التطوّع 🌙', body: 'اليوم الاثنين — يُستحب صيامه', weekday: DateTime.monday, hour: 7, minute: 0);
        await NotificationService.scheduleWeekly(
            id: 205, title: 'صيام التطوّع 🌙', body: 'اليوم الخميس — يُستحب صيامه', weekday: DateTime.thursday, hour: 7, minute: 0);
      case 'rem_sadaqa_friday':
        await NotificationService.scheduleWeekly(
            id: 206,
            title: 'صدقة الجمعة 💚',
            body: 'خير يوم طلعت فيه الشمس — تصدّق ولو بالقليل',
            weekday: DateTime.friday,
            hour: 10,
            minute: 0);
      case 'rem_sleep':
        await NotificationService.scheduleDaily(
            id: 207, title: 'أذكار النوم 🌌', body: 'باسمك اللهم أموت وأحيا', hour: 22, minute: 0);
    }
  }
}
