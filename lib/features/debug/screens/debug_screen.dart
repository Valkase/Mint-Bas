// lib/features/debug/screens/debug_screen.dart
//
// Changes vs original:
//   N11 — _debugStatsProvider was declared as StreamProvider (no .autoDispose).
//         It uses Stream.periodic(Duration(seconds:1)) to poll the DB. Once
//         the user navigated away the provider remained alive for the entire
//         session, executing a DB query every second in the background.
//
//         Fix: changed to StreamProvider.autoDispose so Riverpod tears it down
//         automatically when the debug screen is no longer in the widget tree.

import 'dart:async';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/database_seeder.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../pomodoro/providers/pomodoro_notifier.dart';
import '../../tasks/providers/tasks_notifier.dart';

// ── Live Stats Provider ───────────────────────────────────────────────────────

class _DebugStats {
  final int    projects;
  final int    tasks;
  final int    sessions;
  final int    transactions;
  final double balance;
  const _DebugStats({
    required this.projects,
    required this.tasks,
    required this.sessions,
    required this.transactions,
    required this.balance,
  });
}

// ── BUG N11 FIX ──────────────────────────────────────────────────────────────
// Was: StreamProvider<_DebugStats>((ref) async* { ... })
// Fix: StreamProvider.autoDispose so the 1-second DB poll is cancelled as soon
//      as the debug screen leaves the widget tree. Previously the stream kept
//      running for the entire app session after visiting the debug screen once.
// ─────────────────────────────────────────────────────────────────────────────
final _debugStatsProvider = StreamProvider.autoDispose<_DebugStats>((ref) async* {
  final db = ref.watch(databaseProvider);

  await for (final _ in Stream.periodic(const Duration(seconds: 1))) {
    final projects = await db.projectDao.getAllProjects();
    final lists    = await db.projectDao.getAllLists();
    int taskCount  = 0;
    for (final l in lists) {
      final t = await db.taskDao.getTasksForList(l.id);
      taskCount += t.length;
    }
    final sessions = await db.pomodoroDao.getAllPomodoroSessions();
    final txns     = await db.transactionDao.getAllTransactions();
    final bal      = await db.transactionDao.getBalance();
    yield _DebugStats(
      projects    : projects.length,
      tasks       : taskCount,
      sessions    : sessions.length,
      transactions: txns.length,
      balance     : bal,
    );
  }
});

// ── Inject Session Form State ─────────────────────────────────────────────────

class _InjectSessionState {
  final String type;
  final int    daysAgo;
  const _InjectSessionState({this.type = 'work', this.daysAgo = 0});
  _InjectSessionState copyWith({String? type, int? daysAgo}) =>
      _InjectSessionState(
          type   : type    ?? this.type,
          daysAgo: daysAgo ?? this.daysAgo);
}

// ── Screen ────────────────────────────────────────────────────────────────────

class DebugScreen extends ConsumerStatefulWidget {
  const DebugScreen({super.key});

  @override
  ConsumerState<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends ConsumerState<DebugScreen> {
  int                 _speedMultiplier = 1;
  _InjectSessionState _injectState     = const _InjectSessionState();

  bool _showTransactions = false;
  bool _showSessions     = false;
  bool _showTasks        = false;

  List<Transaction>     _transactions = [];
  List<PomodoroSession> _sessions     = [];
  List<Task>            _allTasks     = [];

  // ── Helpers ─────────────────────────────────────────────────────────────────

  AppDatabase get _db => ref.read(databaseProvider);

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.poppins(
              fontSize: 13, color: AppTheme.textPrimary),
        ),
        backgroundColor: AppTheme.surface,
        behavior       : SnackBarBehavior.floating,
        duration       : const Duration(seconds: 2),
        shape          : RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side        : BorderSide(color: AppTheme.surfaceBorder),
        ),
      ),
    );
  }

  // ── Pomodoro actions ────────────────────────────────────────────────────────

  void _skipToEnd() {
    HapticFeedback.heavyImpact();
    ref.read(pomodoroNotifierProvider.notifier).triggerSessionComplete();
    _toast('Session complete triggered');
  }

  void _setSpeed(int multiplier) {
    setState(() => _speedMultiplier = multiplier);
    HapticFeedback.selectionClick();
    ref.read(pomodoroNotifierProvider.notifier).setSpeed(multiplier);
    _toast('Speed set to ${multiplier}×');
  }

  void _resetTimer() {
    ref.read(pomodoroNotifierProvider.notifier).reset();
    setState(() => _speedMultiplier = 1);
    _toast('Timer reset');
  }

  // ── Data Factory actions ────────────────────────────────────────────────────

  Future<void> _seed7DayHistory() async {
    HapticFeedback.mediumImpact();
    final rng = DateTime.now();
    for (int day = 6; day >= 0; day--) {
      final base  = rng.subtract(Duration(days: day));
      final count = 2 + (day % 4);
      for (int i = 0; i < count; i++) {
        final ts = DateTime(base.year, base.month, base.day, 9 + i * 2);
        await _db.pomodoroDao.insertPomodoroSession(
          PomodoroSessionsCompanion(
            id         : Value(const Uuid().v4()),
            duration   : const Value(25),
            type       : const Value('work'),
            completedAt: Value(ts),
          ),
        );
      }
    }
    _toast('7-day session history seeded');
  }

  Future<void> _completeRandomTasks(int n) async {
    HapticFeedback.mediumImpact();
    final lists    = await _db.projectDao.getAllLists();
    final List<Task> incomplete = [];
    for (final l in lists) {
      final tasks = await _db.taskDao.getTasksForList(l.id);
      incomplete.addAll(tasks.where((t) => !t.isCompleted));
    }
    final toComplete = incomplete.take(n).toList();
    for (final t in toComplete) {
      await ref.read(taskRepositoryProvider).completeTask(t.id);
    }
    _toast(
        'Completed ${toComplete.length} task${toComplete.length == 1 ? '' : 's'}');
  }

  Future<void> _injectSession() async {
    HapticFeedback.mediumImpact();
    final now = DateTime.now();
    final ts  = now.subtract(Duration(days: _injectState.daysAgo));
    await _db.pomodoroDao.insertPomodoroSession(
      PomodoroSessionsCompanion(
        id         : Value(const Uuid().v4()),
        duration   : const Value(25),
        type       : Value(_injectState.type),
        completedAt: Value(ts),
      ),
    );
    _toast('Session injected (${_injectState.type}, ${_injectState.daysAgo}d ago)');
  }

  Future<void> _wipeAndReseed() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.elevated,
        title  : Text('Wipe everything?',
            style: AppTheme.heading.copyWith(fontSize: 18)),
        content: Text(
          'This deletes ALL data — projects, tasks, sessions, transactions — '
              'and re-seeds the database from scratch. This cannot be undone.',
          style: AppTheme.body.copyWith(
              fontSize: 14, color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: AppTheme.label
                    .copyWith(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Wipe',
                style:
                AppTheme.label.copyWith(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    HapticFeedback.heavyImpact();
    final db = _db;

    await db.transactionDao.deleteAllTransactions();
    await db.pomodoroDao.deleteAllSessions();

    final lists = await db.projectDao.getAllLists();
    for (final l in lists) {
      final tasks = await db.taskDao.getTasksForList(l.id);
      for (final t in tasks) {
        await db.taskDao.deleteTask(t.id);
      }
    }
    final projects = await db.projectDao.getAllProjects();
    for (final p in projects) {
      await db.projectDao.deleteProject(p.id);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isSeeded');
    await DatabaseSeeder(db).seed();

    ref.read(pomodoroNotifierProvider.notifier).reset();
    _toast('Everything wiped and re-seeded');
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(_debugStatsProvider);
    final pomState   = ref.watch(pomodoroNotifierProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                children: [
                  _buildLiveStats(statsAsync),
                  const SizedBox(height: 20),
                  _buildSection(
                    title   : 'Timer Controls',
                    children: [
                      _buildSpeedSelector(pomState),
                      const SizedBox(height: 8),
                      _buildActionRow([
                        _DebugButton(
                            label: 'Skip to End',
                            icon : Icons.skip_next_rounded,
                            color: AppTheme.primary,
                            onTap: _skipToEnd),
                        _DebugButton(
                            label: 'Reset Timer',
                            icon : Icons.replay_rounded,
                            color: AppTheme.textSecondary,
                            onTap: _resetTimer),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    title   : 'Data Factory',
                    children: [
                      _buildInjectForm(),
                      const SizedBox(height: 8),
                      _buildActionRow([
                        _DebugButton(
                            label: 'Seed 7-Day History',
                            icon : Icons.history_rounded,
                            color: AppTheme.primary,
                            onTap: _seed7DayHistory),
                        _DebugButton(
                            label: 'Complete 3 Tasks',
                            icon : Icons.check_circle_outline_rounded,
                            color: const Color(0xFF5A9E8A),
                            onTap: () => _completeRandomTasks(3)),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    title   : 'Database',
                    children: [
                      _buildExpandable(
                        label    : 'Transactions',
                        isOpen   : _showTransactions,
                        onToggle : () async {
                          if (!_showTransactions) {
                            _transactions =
                            await _db.transactionDao.getAllTransactions();
                          }
                          setState(
                                  () => _showTransactions = !_showTransactions);
                        },
                        items: _transactions
                            .map((t) =>
                        '${t.type.toUpperCase()}  ${t.amount.toStringAsFixed(0)}  ${t.note ?? ''}')
                            .toList(),
                      ),
                      _buildExpandable(
                        label    : 'Sessions',
                        isOpen   : _showSessions,
                        onToggle : () async {
                          if (!_showSessions) {
                            _sessions =
                            await _db.pomodoroDao.getAllPomodoroSessions();
                          }
                          setState(() => _showSessions = !_showSessions);
                        },
                        items: _sessions
                            .map((s) =>
                        '${s.type}  ${s.duration}min  ${DateFormat('MM/dd HH:mm').format(s.completedAt)}')
                            .toList(),
                      ),
                      _buildExpandable(
                        label    : 'Tasks',
                        isOpen   : _showTasks,
                        onToggle : () async {
                          if (!_showTasks) {
                            final lists =
                            await _db.projectDao.getAllLists();
                            _allTasks = [];
                            for (final l in lists) {
                              _allTasks.addAll(
                                  await _db.taskDao.getTasksForList(l.id));
                            }
                          }
                          setState(() => _showTasks = !_showTasks);
                        },
                        items: _allTasks
                            .map((t) =>
                        '${t.isCompleted ? '✓' : '○'}  ${t.title}  (${t.price.toInt()}¢)')
                            .toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    title   : 'Danger Zone',
                    children: [
                      _DebugButton(
                        label: 'Wipe & Re-seed',
                        icon : Icons.delete_forever_rounded,
                        color: AppTheme.error,
                        onTap: _wipeAndReseed,
                        wide : true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build helpers ───────────────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(color: AppTheme.surfaceBorder)),
      ),
      child: Row(
        children: [
          IconButton(
            icon : const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            color: AppTheme.textSecondary,
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 4),
          Icon(Icons.bug_report_rounded, size: 20, color: AppTheme.coral),
          const SizedBox(width: 8),
          Text('Debug Panel',
              style: AppTheme.heading.copyWith(fontSize: 18)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color       : AppTheme.error.withAlpha(30),
              borderRadius: BorderRadius.circular(6),
              border      : Border.all(color: AppTheme.error.withAlpha(80)),
            ),
            child: Text(
              'DEV ONLY',
              style: AppTheme.caption.copyWith(
                color        : AppTheme.error,
                fontWeight   : FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveStats(AsyncValue<_DebugStats> statsAsync) {
    return statsAsync.when(
      loading: () => const SizedBox(height: 56),
      error  : (e, _) => const SizedBox.shrink(),
      data   : (s) => Container(
        margin   : const EdgeInsets.only(top: 16),
        padding  : const EdgeInsets.symmetric(
            horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color       : AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border      : Border.all(color: AppTheme.surfaceBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatChip(label: 'Projects',     value: '${s.projects}'),
            _StatDivider(),
            _StatChip(label: 'Tasks',        value: '${s.tasks}'),
            _StatDivider(),
            _StatChip(label: 'Sessions',     value: '${s.sessions}'),
            _StatDivider(),
            _StatChip(label: 'Balance',      value: s.balance.toStringAsFixed(0)),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
      {required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children          : [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child  : Text(
            title.toUpperCase(),
            style: AppTheme.caption.copyWith(
              color        : AppTheme.textDisabled,
              fontSize     : 11,
              letterSpacing: 1.2,
              fontWeight   : FontWeight.w600,
            ),
          ),
        ),
        Container(
          padding   : const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color       : AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border      : Border.all(color: AppTheme.surfaceBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children          : children,
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedSelector(PomodoroState pomState) {
    return Row(
      children: [
        Text('Speed:', style: AppTheme.caption),
        const SizedBox(width: 12),
        ...([1, 5, 10, 60]).map((x) {
          final active = _speedMultiplier == x;
          return GestureDetector(
            onTap: () => _setSpeed(x),
            child: AnimatedContainer(
              duration : const Duration(milliseconds: 120),
              margin   : const EdgeInsets.only(right: 6),
              padding  : const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color       : active
                    ? AppTheme.primary.withAlpha(30)
                    : AppTheme.background,
                borderRadius: BorderRadius.circular(8),
                border      : Border.all(
                  color: active
                      ? AppTheme.primary
                      : AppTheme.surfaceBorder,
                ),
              ),
              child: Text(
                '${x}×',
                style: AppTheme.caption.copyWith(
                  color     : active
                      ? AppTheme.primary
                      : AppTheme.textSecondary,
                  fontWeight: active
                      ? FontWeight.w700
                      : FontWeight.w400,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildInjectForm() {
    return Row(
      children: [
        // Type selector
        Expanded(
          child: DropdownButton<String>(
            value           : _injectState.type,
            isExpanded      : true,
            dropdownColor   : AppTheme.elevated,
            style           : AppTheme.caption
                .copyWith(color: AppTheme.textPrimary),
            underline       : const SizedBox.shrink(),
            items: ['work', 'shortBreak', 'longBreak'].map((t) {
              return DropdownMenuItem(value: t, child: Text(t));
            }).toList(),
            onChanged: (v) {
              if (v != null) {
                setState(() =>
                _injectState = _injectState.copyWith(type: v));
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        // Days ago
        Text('${_injectState.daysAgo}d ago',
            style: AppTheme.caption),
        const SizedBox(width: 8),
        _CircleMiniBtn(
            icon : Icons.remove,
            onTap: () => setState(() => _injectState =
                _injectState.copyWith(
                    daysAgo: (_injectState.daysAgo - 1).clamp(0, 30)))),
        const SizedBox(width: 4),
        _CircleMiniBtn(
            icon : Icons.add,
            onTap: () => setState(() => _injectState =
                _injectState.copyWith(
                    daysAgo: (_injectState.daysAgo + 1).clamp(0, 30)))),
        const SizedBox(width: 12),
        _DebugButton(
            label: 'Inject',
            icon : Icons.add_circle_outline_rounded,
            color: AppTheme.primary,
            onTap: _injectSession),
      ],
    );
  }

  Widget _buildActionRow(List<Widget> actions) {
    return Row(
      children: actions
          .expand((w) => [w, const SizedBox(width: 8)])
          .toList()
        ..removeLast(),
    );
  }

  Widget _buildExpandable({
    required String        label,
    required bool          isOpen,
    required VoidCallback  onToggle,
    required List<String>  items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children          : [
        GestureDetector(
          onTap: onToggle,
          child: Row(
            children: [
              Icon(
                isOpen
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                color: AppTheme.textSecondary,
                size : 18,
              ),
              const SizedBox(width: 6),
              Text(label, style: AppTheme.caption),
              const SizedBox(width: 6),
              Text(
                '(${items.length})',
                style: AppTheme.caption
                    .copyWith(color: AppTheme.textDisabled),
              ),
            ],
          ),
        ),
        if (isOpen && items.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 180),
            child: ListView.builder(
              shrinkWrap  : true,
              itemCount   : items.length,
              itemBuilder : (_, i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child  : Text(
                  items[i],
                  style  : AppTheme.caption.copyWith(fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
        if (isOpen && items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child  : Text('(empty)',
                style: AppTheme.caption
                    .copyWith(color: AppTheme.textDisabled)),
          ),
        const SizedBox(height: 4),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small shared widgets
// ─────────────────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children    : [
        Text(value,
            style: AppTheme.body.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label,
            style: AppTheme.caption.copyWith(fontSize: 10)),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      width : 1,
      color : AppTheme.surfaceBorder,
    );
  }
}

class _DebugButton extends StatelessWidget {
  final String       label;
  final IconData     icon;
  final Color        color;
  final VoidCallback onTap;
  final bool         wide;

  const _DebugButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width  : wide ? double.infinity : null,
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color       : color.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
          border      : Border.all(color: color.withAlpha(60)),
        ),
        child: Row(
          mainAxisSize: wide ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: wide
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(label,
                style: AppTheme.caption
                    .copyWith(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _CircleMiniBtn extends StatelessWidget {
  final IconData     icon;
  final VoidCallback onTap;

  const _CircleMiniBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width     : 26,
        height    : 26,
        decoration: BoxDecoration(
          color : AppTheme.surface,
          shape : BoxShape.circle,
          border: Border.all(color: AppTheme.surfaceBorder),
        ),
        child: Icon(icon, size: 14, color: AppTheme.textSecondary),
      ),
    );
  }
}