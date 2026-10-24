import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// محرك التذكيرات — محلي ١٠٠٪ (أذان، أذكار، ورد، صدقة…).
///
/// ⚠️ ملاحظات منصّة:
/// • أندرويد: ملف `adhan_makkah.mp3` (مثلاً) يجب أن يكون في
///   `android/app/src/main/res/raw/` ثم يُستخدم اسمه في [AndroidNotificationDetails].
///   وعلى Android 12+ قد يُطلب إذن «التنبيهات الدقيقة» من إعدادات النظام.
/// • iOS: الملف داخل حزمة التطبيق، والصوت الطويل (>٣٠ث) يحتاج نهجاً مخصصاً.
class NotificationService {
  NotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz_data.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// أذان صلاة محددة — يتكرر يومياً في وقتها.
  /// [withSound]=true ⇐ صوت المؤذن الكامل، وfalse ⇐ تنبيه صامت/قصير.
  static Future<void> schedulePrayerAdhan({
    required int id,
    required String prayerName,
    required DateTime time,
    bool withSound = true,
    String sound = 'adhan_makkah',
  }) async {
    final details = withSound
        ? NotificationDetails(
            android: AndroidNotificationDetails(
              'adhan_$sound',
              'الأذان',
              channelDescription: 'إشعارات الأذان بصوت المؤذن المختار',
              importance: Importance.max,
              priority: Priority.high,
              sound: RawResourceAndroidNotificationSound(sound),
              playSound: true,
              enableVibration: true,
            ),
            iOS: DarwinNotificationDetails(sound: '$sound.mp3', presentSound: true),
          )
        : const NotificationDetails(
            android: AndroidNotificationDetails(
              'adhan_silent',
              'تنبيه الصلاة (صامت)',
              importance: Importance.defaultImportance,
              playSound: false,
            ),
            iOS: DarwinNotificationDetails(presentSound: false),
          );

    await _plugin.zonedSchedule(
      id,
      withSound ? 'حان الآن وقت صلاة $prayerName 🕌' : 'تنبيه: اقترب وقت صلاة $prayerName',
      'تقبّل الله طاعتكم',
      tz.TZDateTime.from(time, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // تكرار يومي
    );
  }

  /// تذكير يومي/أسبوعي عام (أذكار الصباح والمساء، الكهف، صدقة الجمعة…)
  static Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    DateTimeComponents repeat = DateTimeComponents.time,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminders',
          'تذكيرات مُلتزم',
          importance: Importance.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: repeat,
    );
  }

  /// تذكير أسبوعي في يوم محدد (weekday: ١=الاثنين … ٧=الأحد)
  static Future<void> scheduleWeekly({
    required int id,
    required String title,
    required String body,
    required int weekday,
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var d = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    while (d.weekday != weekday || d.isBefore(now)) {
      d = d.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      d,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminders',
          'تذكيرات مُلتزم',
          importance: Importance.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  static Future<void> cancel(int id) => _plugin.cancel(id);

  static Future<void> cancelAll() => _plugin.cancelAll();
}
