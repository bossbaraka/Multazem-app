import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

class MultazimApp extends StatelessWidget {
  const MultazimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'مُلتزم',
      debugShowCheckedModeBanner: false,
      // العربية افتراضية + RTL كامل
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system, // TODO(المرحلة ٥): ربطها بإعدادات المستخدم
      routerConfig: appRouter,
    );
  }
}
