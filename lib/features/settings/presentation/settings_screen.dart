import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/providers/prayer_providers.dart';
import '../../../core/services/backup_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/reminder_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/islamic.dart';

/// الإعدادات — الموقع والأذان مفعّلان فعلياً (Hive + جدولة)،
/// وبقية الأقسام تُربط تباعاً في المراحل القادمة.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const _adhanModes = ['أذان كامل', 'تنبيه صامت', 'إيقاف'];
  bool _locating = false;

  Future<void> _updateAdhanMode(String key, String mode) async {
    final box = ref.read(hiveBoxProvider);
    await box.put('adhan_$key', mode);

    final id = prayerAdhanId(key);
    if (mode == 'إيقاف') {
      await NotificationService.cancel(id);
    } else {
      final times = ref.read(prayerTimesProvider);
      final t = timeOf(times, key);
      final arabicName =
          kFivePrayers.firstWhere((p) => p.$1 == key).$2;
      if (t != null) {
        await NotificationService.schedulePrayerAdhan(
          id: id,
          prayerName: arabicName,
          time: t,
          withSound: mode == 'أذان كامل',
        );
      }
    }
    setState(() {}); // تحديث قيم القوائم
  }

  Future<void> _locate() async {
    setState(() => _locating = true);
    try {
      final r = await LocationService.detectAndApply(ref);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم تحديث موقعك: ${r.city} 📍')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر تحديد الموقع — فعّل الإذن وخدمة الموقع')),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _restoreDialog(Box box) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('استعادة نسخة احتياطية'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text(
            'الصق محتوى ملف النسخة الاحتياطية (multazim_backup.json) هنا:',
            style: TextStyle(fontSize: 13, height: 1.7),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: '{ "app": "multazim", ... }',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('استعادة')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      final data = BackupService.parseBackup(controller.text);
      if (data == null) throw 'not multazim';
      await BackupService.restore(box, data);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ تمّت الاستعادة — أعد فتح التبويبات لترى بياناتك')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ ملف غير صالح — تأكد من النسخة الاحتياطية')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final box = ref.watch(hiveBoxProvider);
    final city = ref.watch(cityNameProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // ── الموقع ─────────────────────────────────────────────
        const SectionTitle('الموقع وطريقة الحساب'),
        const SizedBox(height: 8),
        OrnamentedCard(
          child: Column(children: [
            ListTile(
              leading: _locating
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.place_rounded, color: AppColors.emerald),
              title: Text(city),
              subtitle: const Text('يُستخدم للمواقيت والقبلة — ويبقى على جهازك'),
              trailing: TextButton(onPressed: _locate, child: const Text('تحديث')),
            ),
            const Divider(height: 1),
            const ListTile(
              leading: Icon(Icons.calculate_outlined, color: AppColors.gold),
              title: Text('طريقة الحساب: أم القرى'),
              subtitle: Text('مذهب العصر: الشافعي — خيارات أخرى تُضاف بالمرحلة ٥'),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        // ── الأذان لكل صلاة (مفعّل فعلياً) ──────────────────────
        const SectionTitle('الأذان لكل صلاة'),
        const SizedBox(height: 8),
        OrnamentedCard(
          child: Column(children: [
            for (final (key, arabicName) in kFivePrayers)
              ListTile(
                dense: true,
                leading: const Icon(Icons.mosque_rounded, color: AppColors.emerald),
                title: Text(arabicName),
                trailing: DropdownButton<String>(
                  value: box.get('adhan_$key', defaultValue: 'أذان كامل') as String,
                  underline: const SizedBox(),
                  items: [
                    for (final m in _adhanModes)
                      DropdownMenuItem(value: m, child: Text(m)),
                  ],
                  onChanged: (v) => v == null ? null : _updateAdhanMode(key, v),
                ),
              ),
            const ListTile(
              dense: true,
              leading: Icon(Icons.record_voice_over, color: AppColors.gold),
              title: Text('صوت المؤذن: الحرم المكي (افتراضي)'),
              subtitle: Text('بقية الأصوات تُفعَّل عند إضافة ملفات assets/sounds'),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        // ── المصحف ─────────────────────────────────────────────
        const SectionTitle('المصحف'),
        const SizedBox(height: 8),
        OrnamentedCard(
          child: Row(children: [
            const Text('حجم خط القراءة'),
            Expanded(
              child: Slider(
                value: (box.get('quran_font', defaultValue: 24.0) as double)
                    .clamp(16, 34)
                    .toDouble(),
                min: 16,
                max: 34,
                activeColor: AppColors.gold,
                onChanged: (v) {
                  box.put('quran_font', v);
                  setState(() {});
                },
              ),
            ),
            Text('${(box.get('quran_font', defaultValue: 24.0) as double).round()}'),
          ]),
        ),
        const SizedBox(height: 16),

        // ── التذكيرات ───────────────────────────────────────────
        const SectionTitle('التذكيرات'),
        const SizedBox(height: 8),
        OrnamentedCard(
          child: Column(children: [
            for (final (rk, t) in const [
              ('rem_adhkar_sabah', 'أذكار الصباح 🌅 (٦:٠٠)'),
              ('rem_adhkar_masaa', 'أذكار المساء 🌇 (٤:٠٠ م)'),
              ('rem_wird', 'ورد القرآن اليومي 📖 (٨:٠٠ م)'),
              ('rem_kahf', 'سورة الكهف يوم الجمعة 📿'),
              ('rem_fast', 'صيام الاثنين والخميس 🌙'),
              ('rem_sadaqa_friday', 'صدقة يوم الجمعة 💚'),
              ('rem_sleep', 'أذكار النوم 🌌 (١٠:٠٠ م)'),
            ])
              SwitchListTile(
                dense: true,
                value: ReminderService.isOn(box, rk),
                onChanged: (v) async {
                  await ReminderService.set(box, rk, v);
                  setState(() {});
                },
                title: Text(t, style: const TextStyle(fontSize: 14)),
                activeThumbColor: AppColors.emerald,
              ),
          ]),
        ),
        const SizedBox(height: 16),

        // ── النسخ الاحتياطي ───────────────────────────────────
        const SectionTitle('النسخ الاحتياطي'),
        const SizedBox(height: 8),
        OrnamentedCard(
          child: Column(children: [
            const Text(
              'بياناتك ملكك: صدّر ملف JSON يحوي (صلواتك، صدقاتك، ختمتك، تسبيحك، إعداداتك، علامات القرآن) وأعد استيراده على أي جهاز — بدون حساب وبدون خادم.',
              style: TextStyle(fontSize: 12.5, height: 1.8),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  icon: const Icon(Icons.upload_rounded, size: 18),
                  label: const Text('تصدير'),
                  onPressed: () async {
                    try {
                      await BackupService.export(box);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تعذّر التصدير')));
                      }
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('استعادة'),
                  onPressed: () => _restoreDialog(box),
                ),
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 16),

        // ── الخصوصية ───────────────────────────────────────────
        const SectionTitle('الخصوصية'),
        const SizedBox(height: 8),
        const OrnamentedCard(
          child: Text(
            '🔒 موقعك وبياناتك وسجلّ صلواتك وصدقاتك تبقى على جهازك فقط.\nلا حسابات إجبارية، لا تتبّع، ولا إعلانات.',
            style: TextStyle(height: 1.9, fontSize: 13),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text('مُلتزم v0.2 — صدقة جارية 🤍',
              style: TextStyle(color: AppColors.inkSoft.withValues(alpha: 0.7), fontSize: 12)),
        ),
      ]),
    );
  }
}
