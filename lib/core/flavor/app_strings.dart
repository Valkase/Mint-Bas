// lib/core/flavor/app_strings.dart
//
// Single source of truth for all user-visible text.
// Every screen reads strings from here — never hard-codes them.
//
// HOW TO USE IN A WIDGET:
//   final s = AppStrings.of(ref);          // in ConsumerWidget / ConsumerState
//   Text(s.pomodoroTitle)
//
// HOW TO USE WITHOUT REF (e.g. a plain StatelessWidget that already has flavor):
//   final s = AppStrings.forFlavor(AppFlavor.basboosa);

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_flavor.dart';

class AppStrings {
  final AppFlavor flavor;
  const AppStrings._(this.flavor);

  // ── Factory ────────────────────────────────────────────────────────────────

  static AppStrings of(WidgetRef ref) =>
      AppStrings._(ref.read(flavorProvider));

  static AppStrings forFlavor(AppFlavor f) => AppStrings._(f);

  bool get _b => flavor == AppFlavor.basboosa;

  // ── App identity ───────────────────────────────────────────────────────────

  String get appName => _b ? 'Basboosa' : 'Mint';

  // ── Onboarding ─────────────────────────────────────────────────────────────

  // Slide 1
  String get ob1Title    => _b ? 'صباح الخير يا بسبوسة'    : 'Everything, organised.';
  String get ob1Subtitle => _b ? 'الابليكشن ده بيجيب م الاخر (على قده يعني مش عاوزين افورة)' :
  'Tasks, projects and deadlines — all in one place, without the chaos.';

  // Slide 2
  String get ob2Title    => _b ? 'مفيش زنقات كلاب تاني'    : 'Focus like you mean it.';
  String get ob2Subtitle => _b ? 'متتعشميش, الحاجات دي اقدار للي زيك و زيي, انا بكتب الرسالة دي 7 مارس (انا راكمت)' :
  'A built-in Pomodoro timer that keeps you in the zone and tracks every session.';

  // Slide 3
  String get ob3Title    => _b ? 'لبسبوسة'    : 'You deserve the reward.';
  String get ob3Subtitle => _b ? 'معرفش جات على بالي ليه, بس ادعي لألاء بالرحمة' :
  'Earn coins for every session you complete. Spend them on rewards you actually want.';

  // Buttons
  String get obNext      => _b ? 'الي بعدواا'         : 'Next';
  String get obSkip      => _b ? 'ارجع ورا'           : 'Skip';
  String get obGetStarted => _b ? 'ليتس جو'      : 'Get started';

  // ── Tasks screen ───────────────────────────────────────────────────────────

  String get tasksScreenTitle  => _b ? 'الي مراكماه'       : 'My Tasks';
  String get tasksEmptyTitle   => _b ? 'روحي نامي خلاص' : 'Nothing here yet';
  String get tasksEmptyBody    => _b ? 'المذاكرة مش بتخلص (اي ام مصرية)'  : 'Add your first task and get going.';
  String get tasksAddButton    => _b ? 'راكمي التاسك'    : 'Add task';
  String get tasksToday        => _b ? 'انهاردة'       : 'Today';
  String get tasksUpcoming     => _b ? 'حاجات هراكمها'    : 'Upcoming';
  String get tasksOverdue      => _b ? 'ما انا لو مزة كنت اتعملت'     : 'Overdue';
  String get tasksDone         => _b ? 'فنشن الدنيا'        : 'Done';

  // ── Pomodoro screen ────────────────────────────────────────────────────────

  String get pomodoroScreenTitle  => _b ? 'وقت التركيز'              : 'Focus Session';
  String get pomodoroPhaseWork    => _b ? 'ركزي'                     : 'Focus';
  String get pomodoroPhaseShort   => _b ? 'استريحي شوية'             : 'Short Break';
  String get phaseLong            => _b ? 'استريحي كتير'             : 'Long Break';
  String get pomodoroMinRemaining => _b ? 'دقيقة فاضلة'              : 'minutes remaining';
  String get pomodoroSessionOf    => _b ? 'جلسة {n} من 4'            : 'Session {n} of 4';
  String get pomodoroNoTask       => _b ? 'مفيش مهمة'                : 'No task attached';
  String get pomodoroFreeSession  => _b ? 'جلسة حرة يا بسبوسة'      : 'Free focus session';
  String get pomodoroCurrentTask  => _b ? 'شغالة على'                : 'Current Task';
  String get pomodoroTaskOptions  => _b ? 'الحاجات المتراكمة'            : 'Task Options';
  String get pomodoroDetachHint   => _b
      ? 'عشان تشتغلي على مهمة تانية، ارجعي و دوسي على زرار التركيز.'
      : 'To focus on a different task, go back and tap the focus button on any task card.';
  String get pomodoroDetachBtn    => _b ? 'شيلي المهمة'              : 'Detach from task';

  // Completion overlay
  String get pomodoroSessionDone  => _b ? 'خلصتي!'               : 'Session complete.';
  String get pomodoroSessionDoneSub => _b ? 'العب بالنار و متلعبش مع بسبوسة'     : 'Take a breath. You earned it.';
  String get pomodoroBreakOver    => _b ? 'خلص الاستراحة'            : 'Break over.';
  String get pomodoroBreakOverSub => _b ? 'يلا تاني يا بسبوسة!'     : "Back to it. Let's go.";
  String get pomodoroStartingBreak => _b ? 'الاستراحة بدأت...'       : 'Starting break...';
  String get pomodoroStartingFocus => _b ? 'يلا CH3COOHيكي معانا هنا'             : 'Starting focus...';

  // Session count helper — replace {n} with actual number
  String sessionOf(int n) =>
      pomodoroSessionOf.replaceAll('{n}', n.toString());

  // ── Rewards screen ─────────────────────────────────────────────────────────

  String get rewardsScreenTitle  => _b ? 'حلوياتي'       : 'My Rewards';
  String get rewardsEmptyTitle   => _b ? 'الدكان فاضي' : 'No rewards yet';
  String get rewardsEmptyBody    => _b ? 'حطي اي حاجة تدي تحفيز'  : 'Add something worth working towards.';
  String get rewardsAddButton    => _b ? 'عبي الدكان'    : 'Add reward';
  String get rewardsRedeem       => _b ? 'توتو على كبوتو'        : 'Redeem';
  String get rewardsCost         => _b ? 'كويناتي'          : 'coins';

  // ── Banking screen ─────────────────────────────────────────────────────────

  String get bankingScreenTitle  => _b ? 'نقودي يا عالم'       : 'My Balance';
  String get bankingBalance       => _b ? 'الفلوس كلها'      : 'Total coins';
  String get bankingEarned       => _b ? 'عرق جبيني'        : 'Earned';
  String get bankingSpent        => _b ? 'الي اتبعزق'         : 'Spent';
  String get bankingHistory      => _b ? 'تاريخ البعزقة'       : 'History';
  String get bankingEmpty        => _b ? 'مفيش صفاقات'       : 'No transactions yet.';

  // ── Shared / generic ───────────────────────────────────────────────────────

  String get cancel  => _b ? 'إلغاء'  : 'Cancel';
  String get save    => _b ? 'حفظ'    : 'Save';
  String get delete  => _b ? 'مسح'    : 'Delete';
  String get confirm => _b ? 'تأكيد'  : 'Confirm';
  String get done    => _b ? 'تمام'   : 'Done';
}