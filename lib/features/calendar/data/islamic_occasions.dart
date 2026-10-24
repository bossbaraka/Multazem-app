/// المناسبات الإسلامية — بصياغة محافظة مبنية على المصادر،
/// وما لم يثبت فيه مستحبٌّ خاص نصرّح بذلك (حماية من البدع).
class IslamicOccasion {
  const IslamicOccasion({
    required this.hijriMonth,
    required this.hijriDay,
    required this.title,
    required this.description,
    this.endDay,
    this.recommended,
  });

  final int hijriMonth;
  final int hijriDay;

  /// للفترات (مثل العشر الأواخر ١٩–٩ رمضان)
  final int? endDay;
  final String title;
  final String description;

  /// ما يُستحب فيه (إن ثبت)
  final String? recommended;

  bool contains(int month, int day) =>
      month == hijriMonth && day >= hijriDay && day <= (endDay ?? hijriDay);
}

const kIslamicOccasions = <IslamicOccasion>[
  IslamicOccasion(
    hijriMonth: 1,
    hijriDay: 1,
    title: 'رأس السنة الهجرية',
    description: 'بداية عام هجري جديد — فرصة لجدولة أهدافك الإيمانية للسنة.',
  ),
  IslamicOccasion(
    hijriMonth: 1,
    hijriDay: 9,
    endDay: 10,
    title: 'تاسوعاء وعاشوراء',
    description: 'ذكرى نجاة موسى عليه السلام وقومه من فرعون.',
    recommended: 'صيام يوم عاشوراء يكفّر السنة الماضية — رواه مسلم ١١٦٢. ويُستحسن الجمع مع التاسع (رواه ابن عباس).',
  ),
  IslamicOccasion(
    hijriMonth: 7,
    hijriDay: 27,
    title: 'ذكرى الإسراء والمعراج',
    description:
        'ذكرى تربوية عظيمة، ولم يثبت مشروعية عبادة مخصوصة فيها — فاقتصروا على ما دلّ عليه الدليل.',
  ),
  IslamicOccasion(
    hijriMonth: 8,
    hijriDay: 15,
    title: 'النصف من شعبان',
    description: 'أكثر الصيام بعد رمضان: شعبان — رواه مسلم ١١٥٦.',
    recommended: 'الإكثار من صيام التطوع في شعبان عامة (مع الغالب: دون تعيين ليلة النصف بعبادة خاصة).',
  ),
  IslamicOccasion(
    hijriMonth: 9,
    hijriDay: 1,
    title: 'أول رمضان 🌙',
    description: 'شهر الصيام والقرآن والقيام — تقبّل الله منا ومنكم.',
    recommended: 'الصيام فريضة، وتُراجع نية الصوم وخطة رمضان (ورد، صدقة، قيام).',
  ),
  IslamicOccasion(
    hijriMonth: 9,
    hijriDay: 19,
    endDay: 29,
    title: 'العشر الأواخر من رمضان',
    description: 'كان ﷺ يجتهد في العشر الأواخر ما لا يجتهد في غيرها — مسلم.',
    recommended: 'تحرّي ليلة القدر في الأوتار + الاعتكاف + قيام الليل + الصدقة.',
  ),
  IslamicOccasion(
    hijriMonth: 9,
    hijriDay: 27,
    title: 'ترجّى ليلة القدر',
    description: 'الأرجح من أقوال العلماء: ليلة ٢٧ — لكنها قد تكون في أي وترٍ من العشر.',
    recommended: 'الدعاء: «اللهم إنك عفوٌّ تحب العفو فاعفُ عنّي» — رواه الترمذي ٣٥١٣.',
  ),
  IslamicOccasion(
    hijriMonth: 10,
    hijriDay: 1,
    endDay: 3,
    title: 'عيد الفطر السعيد 🎉',
    description: 'جائزة الصائمين — تقبّل الله طاعتكم.',
    recommended: 'زكاة الفطر قبل صلاة العيد + التكبير في طريق العيد.',
  ),
  IslamicOccasion(
    hijriMonth: 10,
    hijriDay: 2,
    endDay: 30,
    title: 'صيام الست من شوال',
    description: '«من صام رمضان ثم أتبعه ستاً من شوال كان كصيام الدهر» — مسلم ١١٦٤.',
    recommended: 'ستة أيام متفرقة أو متتابعة في شوال.',
  ),
  IslamicOccasion(
    hijriMonth: 12,
    hijriDay: 9,
    title: 'يوم عرفة',
    description: 'خير الدعاء دعاء يوم عرفة — رواه الترمذي.',
    recommended: 'صيامه لغير الحاج يكفّر سنتين — مسلم ١١٦٢.',
  ),
  IslamicOccasion(
    hijriMonth: 12,
    hijriDay: 10,
    endDay: 13,
    title: 'عيد الأضحى المبارك 🕋',
    description: 'أعظم الأيام عند الله يوم النحر — أبو داود.',
    recommended: 'الأضحية والتكبير المطلق والمقيد في أيام التشريق.',
  ),
];

/// الأيام البيض (١٣-١٤-١٥ من كل شهر هجري)
bool isWhiteDays(int hijriDay) => hijriDay >= 13 && hijriDay <= 15;

String whiteDaysNote = 'الأيام البيض (١٣-١٤-١٥): يُستحب صيامها من كل شهر';
