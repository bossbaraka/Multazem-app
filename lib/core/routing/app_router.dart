import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/achievements/presentation/achievements_screen.dart';
import '../../features/adhkar/presentation/adhkar_screen.dart';
import '../../features/adhkar/presentation/tasbih_screen.dart';
import '../../features/calendar/presentation/hijri_calendar_screen.dart';
import '../../features/giving/presentation/giving_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/khatmah/presentation/khatmah_screen.dart';
import '../../features/learn_quran/presentation/learn_quran_screen.dart';
import '../../features/library/presentation/library_screen.dart';
import '../../features/morals/presentation/morals_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/prayer/presentation/prayer_screen.dart';
import '../../features/quran/presentation/quran_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/home', // TODO: توجيه لـ /onboarding عند أول تشغيل (SharedPreferences)
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => MainShell(shell: shell),
      branches: [
        _branch('/home', const HomeScreen()),
        _branch('/prayer', const PrayerScreen()),
        _branch('/quran', const QuranScreen()),
        _branch('/adhkar', const AdhkarScreen()),
        _branch('/giving', const GivingScreen()),
      ],
    ),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    GoRoute(path: '/tasbih', builder: (_, __) => const TasbihScreen()),
    GoRoute(path: '/khatmah', builder: (_, __) => const KhatmahScreen()),
    GoRoute(path: '/calendar', builder: (_, __) => const HijriCalendarScreen()),
    GoRoute(path: '/achievements', builder: (_, __) => const AchievementsScreen()),
    GoRoute(path: '/learn-quran', builder: (_, __) => const LearnQuranScreen()),
    GoRoute(path: '/library', builder: (_, __) => const LibraryScreen()),
    GoRoute(path: '/morals', builder: (_, __) => const MoralsScreen()),
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
  ],
);

StatefulShellBranch _branch(String path, Widget child) => StatefulShellBranch(
      routes: [GoRoute(path: path, builder: (_, __) => child)],
    );

/// الهيكل الرئيسي بالشريط السفلي (٥ تبويبات)
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const _items = [
    (Icons.today_rounded, 'يومي'),
    (Icons.mosque_rounded, 'الصلاة'),
    (Icons.menu_book_rounded, 'القرآن'),
    (Icons.self_improvement_rounded, 'الأذكار'),
    (Icons.volunteer_activism_rounded, 'العطاء'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: [
          for (final (icon, label) in _items)
            NavigationDestination(icon: Icon(icon), label: label),
        ],
      ),
    );
  }
}
