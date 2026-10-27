import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// بطاقة مُزخرفة بهوية «مُلتزم»: إطار ذهبي + نقشة هندسية إسلامية خافتة.
class OrnamentedCard extends StatelessWidget {
  const OrnamentedCard({super.key, required this.child, this.padding, this.color});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: _IslamicPatternPainter(
          color: AppColors.gold.withValues(alpha: isDark ? 0.06 : 0.05),
        ),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}

/// نقشة ثمانية الأضلاع متكررة (روح الزخرفة الإسلامية) — خفيفة وغير مُلهية.
class _IslamicPatternPainter extends CustomPainter {
  _IslamicPatternPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const cell = 54.0;
    for (var y = cell / 2; y < size.height + cell; y += cell) {
      final rowOffset = ((y / cell).floor().isOdd) ? cell / 2 : 0.0;
      for (var x = cell / 2 + rowOffset; x < size.width + cell; x += cell) {
        // نجمة ثمانية = مربعان متقاطعان بزاوية ٤٥°
        const r = cell * 0.28;
        final path = Path()
          ..addPolygon([
            for (var i = 0; i < 8; i++)
              Offset(
                x + r * (i.isEven ? 1 : 0.55) * _cos(i),
                y + r * (i.isEven ? 1 : 0.55) * _sin(i),
              ),
          ], true);
        canvas.drawPath(path, paint);
      }
    }
  }

  static double _cos(int i) =>
      const [1.0, .71, 0.0, -.71, -1.0, -.71, 0.0, .71][i];
  static double _sin(int i) =>
      const [0.0, .71, 1.0, .71, 0.0, -.71, -1.0, -.71][i];

  @override
  bool shouldRepaint(covariant _IslamicPatternPainter old) => old.color != color;
}

/// فاصل مزخرف: ── ۞ ──
class OrnamentDivider extends StatelessWidget {
  const OrnamentDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Container(height: 1, color: AppColors.gold.withValues(alpha: 0.4)),
    );
    return Row(children: [
      line,
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: Text('۞', style: TextStyle(color: AppColors.gold, fontSize: 16)),
      ),
      line,
    ]);
  }
}

/// عنوان قسم بخط أميري مع شارة ذهبية صغيرة
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 6, height: 26,
        decoration: BoxDecoration(
          color: AppColors.gold,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 10),
      Text(title, style: AppTheme.amiri(19, color: AppColors.emerald)),
      const Spacer(),
      if (trailing != null) trailing!,
    ]);
  }
}
