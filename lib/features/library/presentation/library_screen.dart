import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/islamic.dart';
import '../data/library_content.dart';

/// المكتبة الإسلامية — ٥ أبواب بمحتوى موثّق بمصادره.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المكتبة'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'أركان الدين'),
              Tab(text: 'الأربعون النووية'),
              Tab(text: 'السيرة'),
              Tab(text: 'وضوء وصلاة'),
              Tab(text: 'أسماء الله'),
            ],
          ),
        ),
        body: TabBarView(children: [
          _pillarsTab(),
          _nawawiTab(),
          _seerahTab(),
          _fiqhTab(),
          _namesTab(),
        ]),
      ),
    );
  }

  Widget _pillarsTab() => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          OrnamentedCard(
            color: AppColors.gold.withValues(alpha: 0.08),
            child: const Text(
              'بُنِيَ الإِسْلَامُ عَلَى خَمْسٍ — متفق عليه\nوأركان الإيمان ستة كما في حديث جبريل — مسلم',
              textAlign: TextAlign.center,
              style: TextStyle(height: 1.9, fontSize: 13),
            ),
          ),
          const SizedBox(height: 10),
          const SectionTitle('أركان الإسلام الخمسة'),
          const SizedBox(height: 8),
          for (var i = 0; i < 5; i++) _pillarCard(i + 1, kPillars[i], true),
          const SizedBox(height: 14),
          const SectionTitle('أركان الإيمان الستة'),
          const SizedBox(height: 8),
          for (var i = 5; i < kPillars.length; i++)
            _pillarCard(i - 4, kPillars[i], false),
        ],
      );

  Widget _pillarCard(int order, (String, String, String) p, bool isIslam) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: OrnamentedCard(
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CircleAvatar(
            radius: 16,
            backgroundColor:
                isIslam ? AppColors.emerald : AppColors.gold.withValues(alpha: 0.35),
            child: Text('$order',
                style: TextStyle(
                    color: isIslam ? Colors.white : AppColors.emeraldDeep,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.$1, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text(p.$2, style: const TextStyle(fontSize: 12.5, height: 1.7, color: AppColors.inkSoft)),
              Text(p.$3, style: const TextStyle(fontSize: 11, height: 1.6, color: AppColors.gold)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _nawawiTab() => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          OrnamentedCard(
            color: AppColors.emerald.withValues(alpha: 0.07),
            child: const Text(
              '«الأربعون النووية» للإمام النووي (٦٣١–٦٧٦هـ) — أمهات الأحاديث التي عليها مدار الإسلام، نعرض أهمهنا هنا تدريجاً.',
              textAlign: TextAlign.center,
              style: TextStyle(height: 1.9, fontSize: 12.5),
            ),
          ),
          const SizedBox(height: 10),
          for (final h in kNawawi)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OrnamentedCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Chip(
                      label: Text('حديث ${h.num}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      backgroundColor: AppColors.emerald,
                      visualDensity: VisualDensity.compact,
                      side: BorderSide.none,
                    ),
                    const Spacer(),
                    Text(h.source,
                        style: const TextStyle(fontSize: 10.5, color: AppColors.inkSoft)),
                  ]),
                  const SizedBox(height: 8),
                  SelectableText(h.text,
                      textAlign: TextAlign.justify,
                      style: GoogleFonts.amiri(fontSize: 16.5, height: 1.9)),
                  const Divider(height: 16),
                  Text('🌱 من معانيه: ${h.note}',
                      style: const TextStyle(fontSize: 12.5, height: 1.8, color: AppColors.emerald)),
                ]),
              ),
            ),
          const OrnamentDivider(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'تُضاف بقية الأربعين في التحديثات القادمة بإذن الله — مع شرحها الميسّر',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.inkSoft),
            ),
          ),
        ],
      );

  Widget _seerahTab() => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (var i = 0; i < kSeerah.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OrnamentedCard(
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Column(children: [
                    Container(
                      width: 10, height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.gold, shape: BoxShape.circle),
                    ),
                    if (i < kSeerah.length - 1)
                      Container(width: 2, height: 40, color: AppColors.gold.withValues(alpha: 0.4)),
                  ]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(kSeerah[i].$1,
                          style: AppTheme.amiri(16, color: AppColors.emerald)),
                      const SizedBox(height: 4),
                      Text(kSeerah[i].$2,
                          style: const TextStyle(fontSize: 13, height: 1.8, color: AppColors.ink)),
                    ]),
                  ),
                ]),
              ),
            ),
        ],
      );

  Widget _fiqhTab() => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionTitle('صفة الوضوء — ٨ خطوات'),
          const SizedBox(height: 8),
          for (final (n, step) in kWudu)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: OrnamentedCard(
                child: Row(children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: AppColors.emerald.withValues(alpha: 0.12),
                    child: Text('$n', style: const TextStyle(color: AppColors.emerald, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(step, style: const TextStyle(fontSize: 13.5, height: 1.7))),
                ]),
              ),
            ),
          const SizedBox(height: 14),
          const SectionTitle('صفة الصلاة من التكبير إلى التسليم'),
          const SizedBox(height: 8),
          for (final (part, desc) in kPrayerSteps)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: OrnamentedCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(part, style: AppTheme.amiri(16, color: AppColors.emerald)),
                  const SizedBox(height: 4),
                  Text(desc, style: const TextStyle(fontSize: 13, height: 1.8)),
                ]),
              ),
            ),
          const OrnamentedCard(
            child: Text(
              '٨ مراجع: «صفة صلاة النبي» للألباني — نعرض ما يتفق عليه الفقهاء من الأركان على المذهب الجمهوري (الشافعي/المالكي/الحنبلي)، يتباين الاحناف في تفاصيل اختيارية (Ref. الصرحي المطول).',
              style: TextStyle(fontSize: 11, height: 1.8, color: AppColors.inkSoft),
            ),
          ),
        ],
      );

  Widget _namesTab() {
    final names = kAllahNames.split('،');
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        OrnamentedCard(
          color: AppColors.gold.withValues(alpha: 0.08),
          child: const Text(
            '«إِنَّ لِلَّهِ تِسْعَةً وَتِسْعِينَ اسْمًا، مِائَةً إِلَّا وَاحِدًا، مَنْ أَحْصَاهَا دَخَلَ الجَنَّةَ»\nمتفق عليه — البخاري ٢٧٣٦ ومسلم ٢٦٧٧',
            textAlign: TextAlign.center,
            style: TextStyle(height: 2, fontSize: 12.5),
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.6,
          ),
          itemCount: names.length,
          itemBuilder: (context, i) => Card(
            child: Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(names[i], style: GoogleFonts.amiri(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.emerald)),
                Text('${i + 1}', style: const TextStyle(fontSize: 9, color: AppColors.inkSoft)),
              ]),
            ),
          ),
        ),
      ],
    );
  }
}
