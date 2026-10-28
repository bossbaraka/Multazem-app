import 'package:flutter_test/flutter_test.dart';
import 'package:multazim/core/services/backup_service.dart';

void main() {
  group('BackupService.parseBackup', () {
    test('reads data from a مُلتزم JSON backup', () {
      final data = BackupService.parseBackup('''
        {
          "app": "multazim",
          "version": 1,
          "exportedAt": "2026-10-28T12:00:00.000Z",
          "data": {
            "prayer_log_example": {"fajr": true},
            "theme": "dark"
          }
        }
      ''');

      expect(data, {
        'prayer_log_example': {'fajr': true},
        'theme': 'dark',
      });
    });

    test('rejects a backup for another app or one without data', () {
      expect(
        BackupService.parseBackup('{"app":"other","data":{"key":"value"}}'),
        isNull,
      );
      expect(BackupService.parseBackup('{"app":"multazim","data":[]}'), isNull);
    });
  });
}
