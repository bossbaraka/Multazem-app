import 'package:flutter/material.dart';

/// هوية «مُلتزم» — زمردي عميق × ذهبي ملكي (مطابقة للبرومبت §٣.٢)
abstract final class AppColors {
  // الأساسيات
  static const emerald = Color(0xFF0B5D3B);
  static const emeraldDeep = Color(0xFF083D28);
  static const gold = Color(0xFFC9A227);
  static const goldLight = Color(0xFFE8C766);

  // خلفيات
  static const ivory = Color(0xFFFAF6ED);
  static const nightGreen = Color(0xFF0D1B16);
  static const nightCard = Color(0xFF152822);

  // نصوص
  static const ink = Color(0xFF1E2B26);
  static const inkSoft = Color(0xFF6B7A72);
  static const inkOnDark = Color(0xFFF0EDE4);

  // حالات
  static const success = Color(0xFF1FA05E);
  static const warning = Color(0xFFD98E2B);
  static const error = Color(0xFFA63D40);

  // تدرّج الترويسة
  static const headerGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [emerald, emeraldDeep],
  );
}
