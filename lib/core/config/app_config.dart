// ════════════════════════════════════════════════════════════════════════════
//  APP FLAVOR CONFIG
//  This is the only file you need to edit before building.
//
//  HOW TO BUILD:
//    Basboosa edition  →  set currentFlavor = AppFlavor.basboosa  →  flutter build apk --flavor basboosa
//    Mint edition      →  set currentFlavor = AppFlavor.mint      →  flutter build apk --flavor mint
//
//  WHAT THIS FILE CONTROLS:
//    • App name & username
//    • Easter eggs (on/off + messages)
//    • Inside joke strings throughout the UI
//    • Quotes seeded into the database
//    • Rewards seeded into the database
// ════════════════════════════════════════════════════════════════════════════

enum AppFlavor { mint, basboosa }

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  ▶▶  CHANGE THIS ONE LINE BEFORE BUILDING  ◀◀                          │
// └─────────────────────────────────────────────────────────────────────────┘
const AppFlavor currentFlavor = AppFlavor.basboosa;

// ════════════════════════════════════════════════════════════════════════════
//  DO NOT EDIT BELOW UNLESS ADDING NEW CONFIG FIELDS
// ════════════════════════════════════════════════════════════════════════════

class AppConfig {
  AppConfig._();

  static const AppFlavor flavor = currentFlavor;

  // ── App Identity ────────────────────────────────────────────────────────

  /// The title shown in the OS task switcher and used as the app name.
  static String get appName => switch (flavor) {
    AppFlavor.mint => 'Mint',
    AppFlavor.basboosa => 'Basboosa',
  };

  /// The name used in greetings ("Good morning, [userName]").
  /// Leave empty for the Mint flavor — it will just say "Good morning".
  static String get userName => switch (flavor) {
    AppFlavor.mint => '',
    AppFlavor.basboosa => 'Basboosa',
  };

  // ── Easter Eggs ─────────────────────────────────────────────────────────

  /// Master switch — set to false to completely disable all easter eggs.
  static bool get easterEggsEnabled => switch (flavor) {
    AppFlavor.mint => false,
    AppFlavor.basboosa => true,
  };

  /// Message shown when the balance card easter egg is triggered (long press).
  static String get easterEggBalanceTitle => switch (flavor) {
    AppFlavor.mint => '',
    AppFlavor.basboosa => 'You found it 🌙', // ← your personal message title
  };

  static String get easterEggBalanceBody => switch (flavor) {
    AppFlavor.mint => '',
    AppFlavor.basboosa =>
    'Keep going. Every coin you earn is proof you showed up.', // ← personal message body
  };

  // ── Inside Jokes & Custom Strings ───────────────────────────────────────

  /// Subtitle shown under "Your Projects" on the main screen.
  static String get projectsSubtitle => switch (flavor) {
    AppFlavor.mint => 'Focus on what matters, one step at a time.',
    AppFlavor.basboosa =>
    'Your inside joke goes here 😄', // ← replace with your inside joke
  };

  /// Suffix appended to the dashboard greeting.
  /// Mint:     "Good morning"
  /// Basboosa: "Good morning, Basboosa 🌙"
  static String get greetingSuffix => switch (flavor) {
    AppFlavor.mint => '',
    AppFlavor.basboosa => ', Basboosa 🌙', // ← customize the emoji or text
  };

  /// Shown on the empty state when no projects exist yet.
  static String get emptyProjectsMessage => switch (flavor) {
    AppFlavor.mint => 'No projects yet. Tap + to create your first one.',
    AppFlavor.basboosa =>
    'Nothing here yet, habibti. Tap + and start.', // ← your inside joke
  };

  /// Shown on the empty state when no tasks exist in a list.
  static String get emptyTasksMessage => switch (flavor) {
    AppFlavor.mint => 'No tasks yet. Tap + to add one.',
    AppFlavor.basboosa => 'Empty as your excuses. Add a task.', // ← your inside joke
  };

  // ── Quotes ──────────────────────────────────────────────────────────────
  //
  //  Format: (quote: '...', author: '...')
  //  Add as many as you want. They are shown on the Pomodoro timer screen
  //  and rotate every 5 minutes.

  static List<({String quote, String author})> get quotes => switch (flavor) {
    AppFlavor.mint => _mintQuotes,
    AppFlavor.basboosa => _basboosaQuotes,
  };

  static const _mintQuotes = [
    (
    quote: 'The secret of getting ahead is getting started.',
    author: 'Mark Twain'
    ),
    (
    quote:
    'Live as if you were to die tomorrow. Learn as if you were to live forever.',
    author: 'Mahatma Gandhi'
    ),
    (
    quote:
    'The beautiful thing about learning is that no one can take it away from you.',
    author: 'B. B. King'
    ),
    (
    quote: 'An investment in knowledge pays the best interest.',
    author: 'Benjamin Franklin'
    ),
    (
    quote:
    'Success is the sum of small efforts, repeated day in and day out.',
    author: 'Robert Collier'
    ),
    (
    quote: 'The expert in anything was once a beginner.',
    author: 'Helen Hayes'
    ),
    (
    quote:
    'Don\'t let what you cannot do interfere with what you can do.',
    author: 'John Wooden'
    ),
    (
    quote:
    'Education is the most powerful weapon which you can use to change the world.',
    author: 'Nelson Mandela'
    ),
  ];

  // ─────────────────────────────────────────────────────────────────────────
  //  ✏️  BASBOOSA QUOTES — add your personal/inside-joke quotes here
  // ─────────────────────────────────────────────────────────────────────────
  static const _basboosaQuotes = [
    (
    quote: 'Add your first personal quote here.',
    author: 'The Author'
    ),
    (
    quote: 'Add your second personal quote here.',
    author: 'The Author'
    ),
    (
    quote: 'Add your third personal quote here.',
    author: 'The Author'
    ),
    // ← keep adding as many as you want in this same format
  ];

  // ── Rewards ─────────────────────────────────────────────────────────────
  //
  //  Format: (name: '...', description: '...', price: 10.0)
  //  Price is in coins.

  static List<({String name, String description, double price})> get rewards =>
      switch (flavor) {
        AppFlavor.mint => _mintRewards,
        AppFlavor.basboosa => _basboosaRewards,
      };

  static const _mintRewards = [
    (name: 'TikTok', description: '25 minutes of TikTok', price: 5.0),
    (name: 'Gaming', description: '30 minutes of gaming', price: 5.0),
    (name: 'Reading', description: '30 minutes of reading', price: 5.0),
  ];

  // ─────────────────────────────────────────────────────────────────────────
  //  ✏️  BASBOOSA REWARDS — add personal rewards here
  // ─────────────────────────────────────────────────────────────────────────
  static const _basboosaRewards = [
    (
    name: 'Your Reward 1',
    description: 'Describe the reward here',
    price: 5.0
    ),
    (
    name: 'Your Reward 2',
    description: 'Describe the reward here',
    price: 10.0
    ),
    (
    name: 'Your Reward 3',
    description: 'Describe the reward here',
    price: 20.0
    ),
    // ← keep adding as many as you want in this same format
  ];
}