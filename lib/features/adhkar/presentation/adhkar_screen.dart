import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/islamic.dart';
import '../data/adhkar_seed.dart';

class AdhkarScreen extends StatelessWidget {
  const AdhkarScreen({super.key});

  static const _icons = {
    'morning': Icons.wb_twilight,
    'evening': Icons.wb_sunny_outlined,
    'after_prayer': Icons.mosque_rounded,
    'sleep': Icons.bedtime_rounded,
    'waking': Icons.alarm,
    'travel': Icons.flight_takeoff,
    'ruqyah': Icons.healing,
    'misc': Icons.auto_stories,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الأذكار')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'tasbih',
        backgroundColor: AppColors.gold,
        icon: const Icon(Icons.fingerprint, color: AppColors.emeraldDeep),
        label: const Text('السبحة', style: TextStyle(color: AppColors.emeraldDeep)),
        onPressed: () => context.push('/tasbih'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.15,
        ),
        itemCount: kAdhkarCategories.length,
        itemBuilder: (context, i) {
          final cat = kAdhkarCategories[i];
          final ready = cat.adhkar.isNotEmpty;
          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DhikrListScreen(category: cat)),
            ),
            child: Card(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(_icons[cat.id], size: 34, color: AppColors.emerald),
                const SizedBox(height: 10),
                Text(cat.title, style: AppTheme.amiri(17)),
                if (ready)
                  Text('${cat.adhkar.length} أذكار',
                      style: const TextStyle(fontSize: 11, color: AppColors.inkSoft))
                else
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('المرحلة ٣',
                        style: TextStyle(fontSize: 10, color: AppColors.gold)),
                  ),
              ]),
            ),
          );
        },
      ),
    );
  }
}

/// شاشة قراءة الأذكار بعدّاد لمس لكل ذكر
class DhikrListScreen extends StatelessWidget {
  const DhikrListScreen({super.key, required this.category});

  final DhikrCategory category;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(category.title)),
      body: category.adhkar.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'تُضاف هذه الفئة كاملة من حصن المسلم في المرحلة ٣،\nوبكل ذكر مصدره وفضله 🤍',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.inkSoft, height: 1.9),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: category.adhkar.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _DhikrCard(dhikr: category.adhkar[i]),
            ),
    );
  }
}

class _DhikrCard extends StatefulWidget {
  const _DhikrCard({required this.dhikr});

  final Dhikr dhikr;

  @override
  State<_DhikrCard> createState() => _DhikrCardState();
}

class _DhikrCardState extends State<_DhikrCard> {
  int _done = 0;

  @override
  Widget build(BuildContext context) {
    final d = widget.dhikr;
    final complete = _done >= d.count;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        if (complete) return;
        HapticFeedback.lightImpact(); // لمسة خفيفة مع العدّ
        setState(() => _done++);
      },
      child: OrnamentedCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(d.text, style: AppTheme.amiri(17, bold: false)),
          if (d.virtue != null) ...[
            const SizedBox(height: 8),
            Text('الفضل: ${d.virtue}',
                style: const TextStyle(fontSize: 12, color: AppColors.emerald)),
          ],
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: Text(
                '${d.source} · التكرار: ${d.count}',
                style: const TextStyle(fontSize: 11, color: AppColors.inkSoft),
              ),
            ),
            Stack(alignment: Alignment.center, children: [
              CircularProgressIndicator(
                value: d.count == 0 ? 1 : _done / d.count,
                strokeWidth: 3,
                backgroundColor: AppColors.gold.withValues(alpha: 0.2),
                color: complete ? AppColors.success : AppColors.gold,
              ),
              Icon(
                complete ? Icons.check : Icons.touch_app_outlined,
                size: 16,
                color: complete ? AppColors.success : AppColors.emerald,
              ),
            ]),
            const SizedBox(width: 6),
            Text('$_done/${d.count}', style: const TextStyle(fontSize: 12)),
          ]),
        ]),
      ),
    );
  }
}
