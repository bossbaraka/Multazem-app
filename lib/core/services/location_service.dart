import 'package:adhan/adhan.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';

import '../providers/prayer_providers.dart';

class LocationResult {
  const LocationResult(this.latitude, this.longitude, this.city);

  final double latitude;
  final double longitude;
  final String city;
}

/// الموقع — يبقى على الجهاز فقط (خصوصية أولاً)
class LocationService {
  LocationService._();

  static const _latKey = 'loc_lat';
  static const _lngKey = 'loc_lng';
  static const _cityKey = 'loc_city';

  /// الافتراضي حتى يحدّد المستخدم موقعه
  static const fallback = LocationResult(31.5017, 34.4668, 'غزة');

  static LocationResult loadSaved(Box box) {
    final lat = box.get(_latKey) as double?;
    final lng = box.get(_lngKey) as double?;
    if (lat == null || lng == null) return fallback;
    return LocationResult(
        lat, lng, box.get(_cityKey, defaultValue: fallback.city) as String);
  }

  static Future<void> save(Box box, LocationResult r) async {
    await box.put(_latKey, r.latitude);
    await box.put(_lngKey, r.longitude);
    await box.put(_cityKey, r.city);
  }

  /// التقاط الموقع الحقيقي + اسم المدينة (geocoding بالعربية)
  static Future<LocationResult> detect() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('تم رفض إذن الموقع');
    }

    final pos = await Geolocator.getCurrentPosition();

    var city = 'موقعك';
    try {
      final marks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
        localeIdentifier: 'ar',
      );
      if (marks.isNotEmpty) {
        city = marks.first.locality ??
            marks.first.subAdministrativeArea ??
            marks.first.administrativeArea ??
            'موقعك';
      }
    } catch (_) {/* لا إنترنت؟ نكمل بردّ الإحداثيات */}

    return LocationResult(pos.latitude, pos.longitude, city);
  }

  /// تحديث الموقع + حفظه + بثّه لكل الواجهة (يُستدعى من زر «تحديث»)
  static Future<LocationResult> detectAndApply(WidgetRef ref) async {
    final result = await detect();
    final box = ref.read(hiveBoxProvider);
    await save(box, result);
    ref.read(coordinatesProvider.notifier).state =
        Coordinates(result.latitude, result.longitude);
    ref.read(cityNameProvider.notifier).state = result.city;
    // ملاحظة: إعادة جدولة الأذان تتم تلقائياً عند فتح التطبيق التالي.
    return result;
  }
}
