// ════════════════════════════════════════════════════════════════════════════
//  APP CONFIG — THE ONLY FILE YOU EVER NEED TO EDIT
//
//  HOW TO BUILD:
//    Basboosa APK → set currentFlavor = AppFlavor.basboosa
//                 → flutter build apk --flavor basboosa -t lib/main.dart --release
//
//    Mint APK     → set currentFlavor = AppFlavor.mint
//                 → flutter build apk --flavor mint -t lib/main.dart --release
//
//  WHAT THIS FILE CONTROLS (everything):
//    • Every string shown anywhere in the app
//    • Easter eggs
//    • Quotes (shown in the Pomodoro timer)
//    • Rewards seeded into the database on first install
// ════════════════════════════════════════════════════════════════════════════

import 'package:bd_project/core/flavor/app_flavor.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  ▶▶  CHANGE THIS ONE LINE BEFORE BUILDING  ◀◀                          │
// └─────────────────────────────────────────────────────────────────────────┘
const AppFlavor currentFlavor = AppFlavor.basboosa;

// ════════════════════════════════════════════════════════════════════════════
//  DO NOT EDIT BELOW THIS LINE — unless adding a brand-new string field
// ════════════════════════════════════════════════════════════════════════════

class AppConfig {
  AppConfig._();

  static const AppFlavor flavor = currentFlavor;
  static bool get _b => flavor == AppFlavor.basboosa;

  // ── App identity ───────────────────────────────────────────────────────

  static String get appName =>
      _b ? 'Basboosa' : 'Mint';

  static String get userName =>
      _b ? 'Basboosa' : '';

  // ── Easter eggs ────────────────────────────────────────────────────────

  static bool get easterEggsEnabled => _b ? true : false;

  /// Title of the hidden message shown when the balance card is long-pressed.
  static String get easterEggBalanceTitle =>
      _b ? 'You found it 🌙' : '';

  /// Body of the hidden message shown when the balance card is long-pressed.
  static String get easterEggBalanceBody =>
      _b ? 'Keep going. Every coin you earn is proof you showed up.' : '';

  // ── Onboarding ─────────────────────────────────────────────────────────

  static String get ob1Title =>
      _b ? 'صباح الخير يا بسبوسة'
          : 'Everything, organised.';

  static String get ob1Subtitle =>
      _b ? 'الابليكشن ده بيجيب م الاخر (على قده يعني مش عاوزين افورة)'
          : 'Tasks, projects and deadlines — all in one place, without the chaos.';

  static String get ob2Title =>
      _b ? 'مفيش زنقات كلاب تاني'
          : 'Focus like you mean it.';

  static String get ob2Subtitle =>
      _b ? 'متتعشميش, الحاجات دي اقدار للي زيك و زيي, انا بكتب الرسالة دي 7 مارس (انا راكمت)'
          : 'A built-in Pomodoro timer that keeps you in the zone and tracks every session.';

  static String get ob3Title =>
      _b ? 'بسبوسة'
          : 'You deserve the reward.';

  static String get ob3Subtitle =>
      _b ? 'من غير كلام كتير, دي كانت المفروض هدية عيد ميلادك, بس انا ملقيتش سبب يخليني اديهالك بعد معمعة ثانوي'
          : 'Earn coins for every session you complete. Spend them on rewards you actually want.';

  static String get obNext       => _b ? 'الي بعدواا'  : 'Next';
  static String get obSkip       => _b ? 'ارجع ورا'    : 'Skip';
  static String get obGetStarted => _b ? 'ليتس جو'     : 'Get started';

  // ── Dashboard ──────────────────────────────────────────────────────────

  /// Appended to the greeting. e.g. "Good morning, Basboosa 🌙"
  /// Leave empty for Mint — the greeting just says "Good morning".
  static String get greetingSuffix =>
      _b ? ', Basboosa 🌙' : '';

  /// Subtitle shown under "Your Projects" on the dashboard.
  static String get projectsSubtitle =>
      _b ? 'شوفي الي عليكي يا بنتي '
          : 'Focus on what matters, one step at a time.';

  // ── Tasks screen ───────────────────────────────────────────────────────

  static String get tasksScreenTitle => _b ? 'الي مراكماه'                  : 'My Tasks';
  static String get tasksEmptyTitle  => _b ? 'روحي نامي خلاص'               : 'Nothing here yet';
  static String get tasksEmptyBody   => _b ? 'المذاكرة مش بتخلص (اي ام مصرية)' : 'Add your first task and get going.';
  static String get tasksAddButton   => _b ? 'راكمي التاسك'                 : 'Add task';
  static String get tasksToday       => _b ? 'انهاردة'                      : 'Today';
  static String get tasksUpcoming    => _b ? 'حاجات هراكمها'                : 'Upcoming';
  static String get tasksOverdue     => _b ? 'ما انا لو مزة كنت اتعملت'    : 'Overdue';
  static String get tasksDone        => _b ? 'فنشن الدنيا'                  : 'Done';

  /// Empty state shown when a project has no tasks yet.
  static String get emptyTasksMessage =>
      _b ? 'الحمد لله مفيش متراكم, يلا ندخل ننام'
          : 'No tasks yet. Tap + to add one.';

  /// Empty state shown when there are no projects yet.
  static String get emptyProjectsMessage =>
      _b ? 'مفيش حاجة هنا يا حبيبتي'
          : 'No projects yet. Tap + to create your first one.';

  // ── Pomodoro screen ────────────────────────────────────────────────────

  static String get pomodoroScreenTitle   => _b ? 'وقت التركيز'                              : 'Focus Session';
  static String get pomodoroPhaseWork     => _b ? 'ركزي'                                     : 'Focus';
  static String get pomodoroPhaseShort    => _b ? 'استريحي شوية'                             : 'Short Break';
  static String get phaseLong             => _b ? 'استريحي كتير'                             : 'Long Break';
  static String get pomodoroMinRemaining  => _b ? 'دقيقة فاضلة'                              : 'minutes remaining';
  static String get pomodoroSessionOf     => _b ? 'جلسة {n} من 4'                            : 'Session {n} of 4';
  static String get pomodoroNoTask        => _b ? 'مفيش مهمة'                                : 'No task attached';
  static String get pomodoroFreeSession   => _b ? 'جلسة حرة يا بسبوسة'                      : 'Free focus session';
  static String get pomodoroCurrentTask   => _b ? 'شغالة على'                                : 'Current Task';
  static String get pomodoroTaskOptions   => _b ? 'الحاجات المتراكمة'                        : 'Task Options';
  static String get pomodoroDetachHint    => _b
      ? 'عشان تشتغلي على مهمة تانية، ارجعي و دوسي على زرار التركيز.'
      : 'To focus on a different task, go back and tap the focus button on any task card.';
  static String get pomodoroDetachBtn     => _b ? 'شيلي المهمة'                              : 'Detach from task';
  static String get pomodoroSessionDone   => _b ? 'خلصتي!'                                   : 'Session complete.';
  static String get pomodoroSessionDoneSub => _b ? 'ستراحة محارب لم يحارب بعد'          : 'Take a breath. You earned it.';
  static String get pomodoroBreakOver     => _b ? 'خلص الاستراحة'                            : 'Break over.';
  static String get pomodoroBreakOverSub  => _b ? 'يلا تاني يا بسبوسة!'                     : "Back to it. Let's go.";
  static String get pomodoroStartingBreak => _b ? 'الاستراحة بدأت...'                        : 'Starting break...';
  static String get pomodoroStartingFocus => _b ? 'يلا CH3COOHيكي معانا هنا'                : 'Starting focus...';

  // ── Rewards screen ─────────────────────────────────────────────────────

  static String get rewardsScreenTitle => _b ? 'حلوياتي'                    : 'My Rewards';
  static String get rewardsEmptyTitle  => _b ? 'الدكان فاضي'                : 'No rewards yet';
  static String get rewardsEmptyBody   => _b ? 'حطي اي حاجة تدي تحفيز'     : 'Add something worth working towards.';
  static String get rewardsAddButton   => _b ? 'عبي الدكان'                 : 'Add reward';
  static String get rewardsRedeem      => _b ? 'توتو على كبوتو'             : 'Redeem';
  static String get rewardsCost        => _b ? 'كويناتي'                    : 'coins';

  // ── Banking screen ─────────────────────────────────────────────────────

  static String get bankingScreenTitle => _b ? 'نقودي يا عالم'              : 'My Balance';
  static String get bankingBalance     => _b ? 'الفلوس كلها'                : 'Total coins';
  static String get bankingEarned      => _b ? 'عرق جبيني'                  : 'Earned';
  static String get bankingSpent       => _b ? 'الي اتبعزق'                 : 'Spent';
  static String get bankingHistory     => _b ? 'تاريخ البعزقة'              : 'History';
  static String get bankingEmpty       => _b ? 'مفيش صفاقات'                : 'No transactions yet.';
  static String get bankingTaskCompleted   => _b ? 'مهمة اتخلصت'                 : 'Task completed';
  static String get bankingRewardPurchased => _b ? 'اشتريتي حاجة'                : 'Reward purchased';
  static String get bankingNoCoinsEarned   => _b ? 'مفيش كوينز لسه.\nخلصي مهمة و اكسبي.' : 'No coins earned yet.\nComplete tasks to start earning.';
  static String get bankingNothingSpent    => _b ? 'مصرفتيش حاجة لسه.\nروحي الريواردز.' : 'Nothing spent yet.\nVisit the Rewards tab to redeem coins.';
  static String get rewardsSubtitle        => _b ? 'حطي اي حاجة تدي نفسك تحفيز' : 'Celebrate your progress with small joys.';
  static String get dashboardEncouragement => _b ? 'اوعي تبطلي, انتي بتعملي حاجة مهمة' : "Small steps are still progress. You're doing just fine.";

  // ── Generic / shared ───────────────────────────────────────────────────

  static String get cancel  => _b ? 'إلغاء' : 'Cancel';
  static String get save    => _b ? 'حفظ'   : 'Save';
  static String get delete  => _b ? 'مسح'   : 'Delete';
  static String get confirm => _b ? 'تأكيد' : 'Confirm';
  static String get done    => _b ? 'تمام'  : 'Done';

  // ── Quotes ─────────────────────────────────────────────────────────────
  //
  //  Shown in the Pomodoro timer screen, rotating every 5 minutes.
  //  Format: (quote: '...', author: '...')

  static List<({String quote, String author})> get quotes =>
      _b ? _basboosaQuotes : _mintQuotes;

  // ─── Mint quotes (don't touch) ──────────────────────────────────────────
  static const _mintQuotes = [
    (quote: 'The secret of getting ahead is getting started.',       author: 'Mark Twain'),
    (quote: 'Live as if you were to die tomorrow. Learn as if you were to live forever.', author: 'Mahatma Gandhi'),
    (quote: 'The beautiful thing about learning is that no one can take it away from you.', author: 'B. B. King'),
    (quote: 'An investment in knowledge pays the best interest.',     author: 'Benjamin Franklin'),
    (quote: 'Success is the sum of small efforts, repeated day in and day out.', author: 'Robert Collier'),
    (quote: 'The expert in anything was once a beginner.',           author: 'Helen Hayes'),
    (quote: "Don't let what you cannot do interfere with what you can do.", author: 'John Wooden'),
    (quote: 'Education is the most powerful weapon which you can use to change the world.', author: 'Nelson Mandela'),
  ];

  // ─── ✏️ Basboosa quotes — edit freely ──────────────────────────────────
  static const _basboosaQuotes = [
    (quote: 'العب بالنار و متلعبش مع بسبوسة',    author: 'بسبوسة هانم و هي بتصارع الحياة'),
    (quote: 'من طلب العلا سهر الليالي',           author: 'ضميري الدراسي'),
    (quote: 'هخلي حبيبة تعلمك الادب, ركزي بقا', author: 'ضمير بسبوسة الدراسي'),
    (quote: 'توت توت توت توت, شد حيلك يا كتكوت', author: 'واحدة سايقها العبط (بسبوسة)'),
    (quote: 'احلا ضقطورة بتذاكر ولا ايه',        author: 'بسبوسة قدام المراية'),
    (quote: 'لو مركزتيش, هرزعك على قفاكي',       author: 'اخويا عبدو'),
    (quote: 'لو ركزتي, هشتريلك مرسيدس في الجامعة', author: 'باباكي (في احلامك)'),
    // ← add more here in the same format
  ];

  // ── Rewards ────────────────────────────────────────────────────────────
  //
  //  Seeded into the database on first install — cannot be changed after that
  //  without uninstalling the app.
  //  Format: (name: '...', description: '...', price: 10.0)

  static List<({String name, String description, double price})> get rewards =>
      _b ? _basboosaRewards : _mintRewards;

  // ─── Mint rewards (don't touch) ─────────────────────────────────────────
  static const _mintRewards = [
    (name: 'TikTok',   description: '25 minutes of TikTok', price: 5.0),
    (name: 'Gaming',   description: '30 minutes of gaming', price: 5.0),
    (name: 'Reading',  description: '30 minutes of reading', price: 5.0),
  ];

  // ─── ✏️ Basboosa rewards — edit freely ──────────────────────────────────
  static const _basboosaRewards = [
    (name: 'شكلولاتة',        description: 'هو مكعب مش هنفتري',            price: 20.0),
    (name: 'مرقعة على الفون', description: 'هي نص ساعة',                   price: 30.0),
    (name: 'فلم و سناكس',    description: 'اتفرج على فلم محترم و سناكسي المحترمة', price: 50.0),
    // ← add more here in the same format
  ];
}