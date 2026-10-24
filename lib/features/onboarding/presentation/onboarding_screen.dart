import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

/// البداية — ٥ خطوات (المرحلة ١: استكمال ربط الموقع والأساليب)
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _steps = [
    ('﴿وَمَا خَلَقْتُ الْجِنَّ وَالْإِنسَ إِلَّا لِيَعْبُدُونِ﴾',
     'أهلاً بك في «مُلتزم» — رفيقك اليومي نحو حياة ملتزمة، بلا إعلانات وبلا تشتيت.'),
    ('تحديد موقعك 📍', 'نستخدمه لحساب المواقيت والقبلة بدقة، ويبقى على جهازك فقط.'),
    ('طريقة حساب المواقيت 🕌', 'أم القرى، رابطة العالم الإسلامي، الهيئة المصرية… مع اختيار المذهب لحساب العصر.'),
    ('صوت مؤذنك المفضل 🎙️', 'الحرم المكي، ناصر القطامي، مشاري العفاسي، علي أحمد ملا، والمدينة المنورة.'),
    ('ماذا نذكّرك به؟ 🔔', 'أذكار الصباح والمساء، ورد القرآن، صيام الاثنين والخميس، صدقة الجمعة… اختر بحرّية كاملة.'),
  ];

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _steps.length - 1;
    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _steps.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('۞', style: TextStyle(color: AppColors.gold, fontSize: 42)),
                    const SizedBox(height: 24),
                    Text(_steps[i].$1,
                        textAlign: TextAlign.center,
                        style: AppTheme.amiri(24, color: AppColors.emerald)),
                    const SizedBox(height: 18),
                    Text(_steps[i].$2,
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(fontSize: 15, height: 1.9, color: AppColors.inkSoft)),
                  ],
                ),
              ),
            ),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < _steps.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == _page ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == _page ? AppColors.emerald : AppColors.gold.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ]),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.emerald,
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: () {
                if (isLast) {
                  // TODO: حفظ اختيارات البداية ثم الانتقال
                  context.go('/home');
                } else {
                  _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                }
              },
              child: Text(isLast ? 'ابدأ رحلتك 🤍' : 'التالي'),
            ),
          ),
        ]),
      ),
    );
  }
}
