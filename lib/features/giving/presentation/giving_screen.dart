import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hive/hive.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/islamic.dart';

// ── النماذج ────────────────────────────────────────────────────────────
class Donation {
  Donation({required this.amount, required this.type, required this.hidden}) {
    date = DateTime.now();
  }

  final double amount;
  final String type;
  final bool hidden;
  late final DateTime date;

  Map<String, dynamic> toJson() =>
      {'a': amount, 't': type, 'h': hidden, 'd': date.toIso8601String()};

  factory Donation.fromJson(Map<String, dynamic> j) => Donation(
        amount: (j['a'] as num).toDouble(),
        type: j['t'] as String,
        hidden: j['h'] as bool? ?? false,
      )..date = DateTime.parse(j['d'] as String);
}

class Charity {
  Charity({
    required this.name,
    required this.url,
    required this.country,
    required this.categories,
    required this.featured,
  });

  final String name;
  final String url;
  final String country;
  final List<String> categories;
  final bool featured;

  factory Charity.fromJson(Map<String, dynamic> j) => Charity(
        name: j['name'] as String,
        url: j['url'] as String,
        country: j['country'] as String,
        categories: (j['categories'] as List).cast<String>(),
        featured: j['featured'] as bool? ?? false,
      );
}

/// شاشة العطاء — سجلّ محلي سري + جهات رسمية خارجية.
/// (المرحلة ٤: نقل السجل إلى Hive مع تشفير محلي اختياري)
class GivingScreen extends StatefulWidget {
  const GivingScreen({super.key});

  @override
  State<GivingScreen> createState() => _GivingScreenState();
}

class _GivingScreenState extends State<GivingScreen> {
  final List<Donation> _donations = [];
  final TextEditingController _amount = TextEditingController();
  String _type = 'مال';
  bool _hidden = false;

  @override
  void initState() {
    super.initState();
    // سجل الصدقات محفوظ محلياً — يبقى بعد إغلاق التطبيق
    final raw = Hive.box('multazim').get('donations', defaultValue: const []) as List;
    _donations.addAll(raw.map(
        (e) => Donation.fromJson(Map<String, dynamic>.from(e as Map))));
  }

  void _saveDonations() {
    Hive.box('multazim')
        .put('donations', [for (final d in _donations) d.toJson()]);
  }

  double get _monthTotal => _donations
      .where((d) =>
          d.date.month == DateTime.now().month && d.date.year == DateTime.now().year)
      .fold(0, (sum, d) => sum + d.amount);

  Future<List<Charity>> _loadCharities() async {
    final raw = await rootBundle.loadString('assets/data/charities.json');
    final list = (jsonDecode(raw)['charities'] as List).cast<Map<String, dynamic>>();
    return list.map(Charity.fromJson).toList();
  }

  Future<void> _openCharity(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('العطاء')),

      // ── تسجيل صدقة ──────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.emerald,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('سجّل صدقة', style: TextStyle(color: Colors.white)),
        onPressed: _openAddSheet,
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // آية العطاء
          OrnamentedCard(
            color: AppColors.gold.withValues(alpha: 0.08),
            child: Column(children: [
              Text(
                '﴿مَّثَلُ الَّذِينَ يُنفِقُونَ أَمْوَالَهُمْ فِي سَبِيلِ اللَّهِ كَمَثَلِ حَبَّةٍ أَنبَتَتْ سَبْعَ سَنَابِلَ﴾',
                textAlign: TextAlign.center,
                style: AppTheme.amiri(18, bold: false),
              ),
              const SizedBox(height: 4),
              const Text('البقرة ٢٦١',
                  style: TextStyle(fontSize: 11, color: AppColors.inkSoft)),
            ]),
          ),
          const SizedBox(height: 16),

          // إحصاء الشهر + الإخفاء
          Row(children: [
            Expanded(
              child: OrnamentedCard(
                child: Column(children: [
                  const Text('عطاؤك هذا الشهر',
                      style: TextStyle(fontSize: 13, color: AppColors.inkSoft)),
                  const SizedBox(height: 6),
                  Text(
                    _hidden ? '☆ ☆ ☆' : _monthTotal.toStringAsFixed(0),
                    style: AppTheme.amiri(30, color: AppColors.emerald),
                  ),
                  const Text('بتقوى الله يكبر 💚',
                      style: TextStyle(fontSize: 11, color: AppColors.inkSoft)),
                ]),
              ),
            ),
          ]),
          SwitchListTile(
            value: _hidden,
            onChanged: (v) => setState(() => _hidden = v),
            title: const Text('وضع الإخفاء (اكتم صدقتك)', style: TextStyle(fontSize: 14)),
            subtitle: const Text('﴿وَإِن تُخْفُوهَا وَتُؤْتُوهَا الْفُقَرَاءَ فَهُوَ خَيْرٌ لَّكُمْ﴾',
                style: TextStyle(fontSize: 11)),
            activeThumbColor: AppColors.emerald,
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const OrnamentDivider(),

          // إخلاء المسؤولية (دائم الظهور — شرط البرومبت)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
            ),
            child: const Row(children: [
              Icon(Icons.verified_user_outlined, color: AppColors.warning),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'التبرع يتم عبر المواقع الرسمية للجهات أدناه — لا يجمع «مُلتزم» أي أموال أو عمولات. تحقّق دائماً من رسمية الجهة قبل التبرع.',
                  style: TextStyle(fontSize: 12, height: 1.7),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          const SectionTitle('جهات رسمية موثوقة'),

          // دليل الجهات (من JSON)
          FutureBuilder<List<Charity>>(
            future: _loadCharities(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final list = [...snap.data!]
                ..sort((a, b) => (b.featured ? 1 : 0) - (a.featured ? 1 : 0));
              return Column(children: [
                for (final c in list) ...[
                  const SizedBox(height: 8),
                  OrnamentedCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          if (c.featured)
                            const Padding(
                              padding: EdgeInsets.only(left: 6),
                              child: Icon(Icons.star_rounded,
                                  color: AppColors.gold, size: 18),
                            ),
                          Expanded(
                            child: Text(c.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                        ]),
                        const SizedBox(height: 8),
                        Wrap(spacing: 6, runSpacing: 6, children: [
                          _tag(c.country),
                          for (final cat in c.categories) _tag(cat),
                        ]),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.tonalIcon(
                            icon: const Icon(Icons.open_in_new, size: 18),
                            label: const Text('تبرع عبر الموقع الرسمي'),
                            onPressed: () => _openCharity(c.url),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ]);
            },
          ),
          const SizedBox(height: 16),

          // أفكار صدقة جارية
          const SectionTitle('صدقة جارية تنفعك بعد مماتك 🤍'),
          const SizedBox(height: 8),
          SizedBox(
            height: 110,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                _JariyahCard(Icons.water_drop_rounded, 'حفر بئر ماء'),
                _JariyahCard(Icons.menu_book_rounded, 'طباعة مصاحف'),
                _JariyahCard(Icons.child_care_rounded, 'كفالة يتيم'),
                _JariyahCard(Icons.mosque_rounded, 'مشاركة في بناء مسجد'),
                _JariyahCard(Icons.restaurant_rounded, 'إطعام طعام'),
              ],
            ),
          ),
          const SizedBox(height: 80), // مسافة للـ FAB
        ],
      ),
    );
  }

  Widget _tag(String text) => Chip(
        label: Text(text, style: const TextStyle(fontSize: 11)),
        visualDensity: VisualDensity.compact,
        side: BorderSide(color: AppColors.gold.withValues(alpha: 0.4)),
        backgroundColor: AppColors.gold.withValues(alpha: 0.08),
      );

  void _openAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: StatefulBuilder(
          builder: (ctx, setSheet) => Column(mainAxisSize: MainAxisSize.min, children: [
            Text('سجّل صدقتك 💚', style: AppTheme.amiri(20, color: AppColors.emerald)),
            const SizedBox(height: 14),
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'المبلغ (أو اتركه فارغاً لصدقة غير مالية)',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(spacing: 8, children: [
              for (final t in ['مال', 'طعام', 'وقت', 'عينية', 'أخرى'])
                ChoiceChip(
                  label: Text(t),
                  selected: _type == t,
                  onSelected: (_) => setSheet(() => _type = t),
                ),
            ]),
            SwitchListTile(
              value: _hidden,
              onChanged: (v) => setSheet(() => _hidden = v),
              title: const Text('أخفِها (صدقة سر)', style: TextStyle(fontSize: 14)),
              activeThumbColor: AppColors.emerald,
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.emerald),
                onPressed: () {
                  setState(() {
                    _donations.add(Donation(
                      amount: double.tryParse(_amount.text) ?? 0,
                      type: _type,
                      hidden: _hidden,
                    ));
                  });
                  _saveDonations();
                  _amount.clear();
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('تقبّل الله منك 🤍 (محفوظة على جهازك فقط)')),
                  );
                },
                child: const Text('حفظ'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _JariyahCard extends StatelessWidget {
  const _JariyahCard(this.icon, this.title);

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(left: 10),
      child: Card(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: AppColors.emerald, size: 30),
          const SizedBox(height: 8),
          Text(title,
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
        ]),
      ),
    );
  }
}
