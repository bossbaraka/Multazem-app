import 'dart:convert';
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// النسخ الاحتياطي — بياناتك ملكك:
/// تصدير كل صندوق Hive (صلوات، صدقات، ختمة، تسبيح، إعدادات…) إلى ملف JSON،
/// واستعادته على أي جهاز. بدون خادم، بدون حساب.
class BackupService {
  BackupService._();

  static const _excludedPrefixes = ['surah_', 'taf_']; // الكاش يُعاد جلبه

  /// تصدير البيانات كملف JSON عبر نافذة المشاركة
  static Future<void> export(Box box) async {
    final data = <String, dynamic>{};
    for (final key in box.keys) {
      final k = key.toString();
      if (_excludedPrefixes.any(k.startsWith)) continue;
      data[k] = box.get(key);
    }
    final payload = {
      'app': 'multazim',
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'data': data,
    };

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/multazim_backup.json');
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: 'نسخة احتياطية — مُلتزم',
      text: 'نسخة بياناتي من تطبيق مُلتزم 🤍',
    );
  }

  /// استعادة (تُستدعى من صفحة الاختيار بعد التحقق من الصيغة)
  static Map<String, dynamic>? parseBackup(String content) {
    final j = jsonDecode(content) as Map<String, dynamic>;
    if (j['app'] != 'multazim' || j['data'] is! Map) return null;
    return Map<String, dynamic>.from(j['data'] as Map);
  }

  static Future<void> restore(Box box, Map<String, dynamic> data) async {
    for (final e in data.entries) {
      await box.put(e.key, e.value);
    }
  }
}
