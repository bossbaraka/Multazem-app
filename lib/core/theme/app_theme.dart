import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// الثيم الفاتح والداكن — كلاسيكي فاخر: بطاقات مقوّسة بإطار ذهبي خفيف.
abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.emerald,
      brightness: brightness,
    ).copyWith(
      primary: AppColors.emerald,
      secondary: AppColors.gold,
      surface: isDark ? AppColors.nightCard : Colors.white,
      error: AppColors.error,
    );

    final textTheme = GoogleFonts.tajawalTextTheme(
      isDark
          ? ThemeData.dark().textTheme.apply(bodyColor: AppColors.inkOnDark)
          : ThemeData.light().textTheme.apply(bodyColor: AppColors.ink),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark ? AppColors.nightGreen : AppColors.ivory,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: GoogleFonts.amiri(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: isDark ? AppColors.inkOnDark : AppColors.emeraldDeep,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.gold.withValues(alpha: 0.35)),
        ),
        color: isDark ? AppColors.nightCard : Colors.white,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? AppColors.nightCard : Colors.white,
        indicatorColor: AppColors.gold.withValues(alpha: 0.25),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.emerald
                : AppColors.inkSoft,
          ),
        ),
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.tajawal(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
      dividerColor: AppColors.gold.withValues(alpha: 0.2),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }

  /// نمط العناوين التراثي (أميري)
  static TextStyle amiri(double size, {Color? color, bool bold = true}) =>
      GoogleFonts.amiri(
        fontSize: size,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        color: color,
        height: 1.6,
      );
}

// ملاحظة: إن كان إصدار Flutter أقدم من 3.27 استبدل WidgetState/CardThemeData
// بـ MaterialState/CardTheme و withValues(alpha:) بـ withOpacity().
