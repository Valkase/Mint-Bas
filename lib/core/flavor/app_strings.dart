// lib/core/flavor/app_strings.dart
//
// Bridge layer — every screen calls AppStrings.of(ref) and gets strings back.
// All actual string values live in app_config.dart — that is the only
// file you ever need to edit.
//
// DO NOT add string values here. Add them in app_config.dart instead.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import 'app_flavor.dart';

class AppStrings {
  final AppFlavor flavor;
  const AppStrings._(this.flavor);

  static AppStrings of(WidgetRef ref) =>
      AppStrings._(ref.read(flavorProvider));

  static AppStrings forFlavor(AppFlavor f) => AppStrings._(f);

  // ── App identity ──────────────────────────────────────────────────────────

  String get appName          => AppConfig.appName;
  String get greetingSuffix   => AppConfig.greetingSuffix;
  String get projectsSubtitle => AppConfig.projectsSubtitle;

  // ── Easter eggs ───────────────────────────────────────────────────────────

  bool   get easterEggsEnabled     => AppConfig.easterEggsEnabled;
  String get easterEggBalanceTitle => AppConfig.easterEggBalanceTitle;
  String get easterEggBalanceBody  => AppConfig.easterEggBalanceBody;

  // ── Onboarding ────────────────────────────────────────────────────────────

  String get ob1Title     => AppConfig.ob1Title;
  String get ob1Subtitle  => AppConfig.ob1Subtitle;
  String get ob2Title     => AppConfig.ob2Title;
  String get ob2Subtitle  => AppConfig.ob2Subtitle;
  String get ob3Title     => AppConfig.ob3Title;
  String get ob3Subtitle  => AppConfig.ob3Subtitle;
  String get obNext       => AppConfig.obNext;
  String get obSkip       => AppConfig.obSkip;
  String get obGetStarted => AppConfig.obGetStarted;

  // ── Tasks screen ──────────────────────────────────────────────────────────

  String get tasksScreenTitle     => AppConfig.tasksScreenTitle;
  String get tasksEmptyTitle      => AppConfig.tasksEmptyTitle;
  String get tasksEmptyBody       => AppConfig.tasksEmptyBody;
  String get tasksAddButton       => AppConfig.tasksAddButton;
  String get tasksToday           => AppConfig.tasksToday;
  String get tasksUpcoming        => AppConfig.tasksUpcoming;
  String get tasksOverdue         => AppConfig.tasksOverdue;
  String get tasksDone            => AppConfig.tasksDone;
  String get emptyTasksMessage    => AppConfig.emptyTasksMessage;
  String get emptyProjectsMessage => AppConfig.emptyProjectsMessage;

  // ── Pomodoro screen ───────────────────────────────────────────────────────

  String get pomodoroScreenTitle    => AppConfig.pomodoroScreenTitle;
  String get pomodoroPhaseWork      => AppConfig.pomodoroPhaseWork;
  String get pomodoroPhaseShort     => AppConfig.pomodoroPhaseShort;
  String get phaseLong              => AppConfig.phaseLong;
  String get pomodoroMinRemaining   => AppConfig.pomodoroMinRemaining;
  String get pomodoroSessionOf      => AppConfig.pomodoroSessionOf;
  String get pomodoroNoTask         => AppConfig.pomodoroNoTask;
  String get pomodoroFreeSession    => AppConfig.pomodoroFreeSession;
  String get pomodoroCurrentTask    => AppConfig.pomodoroCurrentTask;
  String get pomodoroTaskOptions    => AppConfig.pomodoroTaskOptions;
  String get pomodoroDetachHint     => AppConfig.pomodoroDetachHint;
  String get pomodoroDetachBtn      => AppConfig.pomodoroDetachBtn;
  String get pomodoroSessionDone    => AppConfig.pomodoroSessionDone;
  String get pomodoroSessionDoneSub => AppConfig.pomodoroSessionDoneSub;
  String get pomodoroBreakOver      => AppConfig.pomodoroBreakOver;
  String get pomodoroBreakOverSub   => AppConfig.pomodoroBreakOverSub;
  String get pomodoroStartingBreak  => AppConfig.pomodoroStartingBreak;
  String get pomodoroStartingFocus  => AppConfig.pomodoroStartingFocus;

  // Session count helper — replaces {n} with the actual number
  String sessionOf(int n) =>
      AppConfig.pomodoroSessionOf.replaceAll('{n}', n.toString());

  // ── Rewards screen ────────────────────────────────────────────────────────

  String get rewardsScreenTitle => AppConfig.rewardsScreenTitle;
  String get rewardsSubtitle    => AppConfig.rewardsSubtitle;
  String get rewardsEmptyTitle  => AppConfig.rewardsEmptyTitle;
  String get rewardsEmptyBody   => AppConfig.rewardsEmptyBody;
  String get rewardsAddButton   => AppConfig.rewardsAddButton;
  String get rewardsRedeem      => AppConfig.rewardsRedeem;
  String get rewardsCost        => AppConfig.rewardsCost;

  // ── Banking screen ────────────────────────────────────────────────────────

  String get bankingScreenTitle     => AppConfig.bankingScreenTitle;
  String get bankingBalance         => AppConfig.bankingBalance;
  String get bankingEarned          => AppConfig.bankingEarned;
  String get bankingSpent           => AppConfig.bankingSpent;
  String get bankingHistory         => AppConfig.bankingHistory;
  String get bankingEmpty           => AppConfig.bankingEmpty;
  String get bankingTaskCompleted   => AppConfig.bankingTaskCompleted;
  String get bankingRewardPurchased => AppConfig.bankingRewardPurchased;
  String get bankingNoCoinsEarned   => AppConfig.bankingNoCoinsEarned;
  String get bankingNothingSpent    => AppConfig.bankingNothingSpent;

  // ── Dashboard ─────────────────────────────────────────────────────────────

  String get dashboardEncouragement => AppConfig.dashboardEncouragement;

  // ── Generic / shared ──────────────────────────────────────────────────────

  String get cancel  => AppConfig.cancel;
  String get save    => AppConfig.save;
  String get delete  => AppConfig.delete;
  String get confirm => AppConfig.confirm;
  String get done    => AppConfig.done;
}