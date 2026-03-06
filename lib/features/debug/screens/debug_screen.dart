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
  final int projects;
  final int tasks;
  final int sessions;
  final int transactions;
  final double balance;
  const _DebugStats({
    required this.projects,
    required this.tasks,
    required this.sessions,
    required this.transactions,
    required this.balance,
  });
}

final _debugStatsProvider = StreamProvider<_DebugStats>((ref) async* {
  final db = ref.watch(databaseProvider);

  // Combine 4 streams into one by polling on any change
  await for (final _ in Stream.periodic(const Duration(seconds: 1))) {
    final projects = await db.projectDao.getAllProjects();
    final lists = await db.projectDao.getAllLists();
    int taskCount = 0;
    for (final l in lists) {
      final t = await db.taskDao.getTasksForList(l.id);
      taskCount += t.length;
    }
    final sessions = await db.pomodoroDao.getAllPomodoroSessions();
    final txns = await db.transactionDao.getAllTransactions();
    final bal = await db.transactionDao.getBalance();
    yield _DebugStats(
      projects: projects.length,
      tasks: taskCount,
      sessions: sessions.length,
      transactions: txns.length,
      balance: bal,
    );
  }
});

// ── Inject Session Form State ─────────────────────────────────────────────────

class _InjectSessionState {
  final String type;
  final int daysAgo;
  const _InjectSessionState({this.type = 'work', this.daysAgo = 0});
  _InjectSessionState copyWith({String? type, int? daysAgo}) =>
      _InjectSessionState(type: type ?? this.type, daysAgo: daysAgo ?? this.daysAgo);
}

// ── Screen ────────────────────────────────────────────────────────────────────

class DebugScreen extends ConsumerStatefulWidget {
  const DebugScreen({super.key});

  @override
  ConsumerState<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends ConsumerState<DebugScreen> {
  int _speedMultiplier = 1;
  _InjectSessionState _injectState = const _InjectSessionState();

  bool _showTransactions = false;
  bool _showSessions = false;
  bool _showTasks = false;

  List<Transaction> _transactions = [];
  List<PomodoroSession> _sessions = [];
  List<Task> _allTasks = [];

  // ── Helpers ─────────────────────────────────────────────────────────────────

  AppDatabase get _db => ref.read(databaseProvider);

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textPrimary)),
        backgroundColor: AppTheme.surface,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: AppTheme.surfaceBorder),
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
      final base = rng.subtract(Duration(days: day));
      final count = 2 + (day % 4); // 2–5 sessions per day
      for (int i = 0; i < count; i++) {
        final ts = DateTime(base.year, base.month, base.day, 9 + i * 2);
        await _db.pomodoroDao.insertPomodoroSession(
          PomodoroSessionsCompanion(
            id: Value(const Uuid().v4()),
            duration: const Value(25),
            type: const Value('work'),
            completedAt: Value(ts),
          ),
        );
      }
    }
    _toast('7-day session history seeded');
  }

  Future<void> _completeRandomTasks(int n) async {
    HapticFeedback.mediumImpact();
    final lists = await _db.projectDao.getAllLists();
    final List<Task> incomplete = [];
    for (final l in lists) {
      final tasks = await _db.taskDao.getTasksForList(l.id);
      incomplete.addAll(tasks.where((t) => !t.isCompleted));
    }
    final toComplete = incomplete.take(n).toList();
    for (final t in toComplete) {
      await ref.read(taskRepositoryProvider).completeTask(t.id);
    }
    _toast('Completed ${toComplete.length} task${toComplete.length == 1 ? '' : 's'}');
  }

  Future<void> _addCoins(double amount) async {
    HapticFeedback.lightImpact();
    await ref.read(bankingRepositoryProvider).earn(
      amount,
      note: 'Debug: +${amount.toInt()} coins',
    );
    _toast('+${amount.toInt()} coins added');
  }

  Future<void> _spendCoins(double amount) async {
    HapticFeedback.lightImpact();
    try {
      await ref.read(bankingRepositoryProvider).spend(
        amount,
        note: 'Debug: −${amount.toInt()} coins',
      );
      _toast('−${amount.toInt()} coins spent');
    } catch (e) {
      _toast('Insufficient balance');
    }
  }

  Future<void> _injectSession() async {
    HapticFeedback.mediumImpact();
    final base = DateTime.now().subtract(Duration(days: _injectState.daysAgo));
    await _db.pomodoroDao.insertPomodoroSession(
      PomodoroSessionsCompanion(
        id: Value(const Uuid().v4()),
        duration: const Value(25),
        type: Value(_injectState.type),
        completedAt: Value(base),
      ),
    );
    _toast('Session injected (${_injectState.type}, ${_injectState.daysAgo}d ago)');
  }

  // ── Inspector loads ─────────────────────────────────────────────────────────

  Future<void> _loadTransactions() async {
    _transactions = await _db.transactionDao.getAllTransactions();
    setState(() => _showTransactions = true);
  }

  Future<void> _loadSessions() async {
    _sessions = await _db.pomodoroDao.getAllPomodoroSessions();
    setState(() => _showSessions = true);
  }

  Future<void> _loadTasks() async {
    final lists = await _db.projectDao.getAllLists();
    _allTasks = [];
    for (final l in lists) {
      _allTasks.addAll(await _db.taskDao.getTasksForList(l.id));
    }
    setState(() => _showTasks = true);
  }

  // ── Reset actions ───────────────────────────────────────────────────────────

  Future<void> _clearSessions() async {
    await _db.pomodoroDao.deleteAllSessions();
    _toast('All sessions cleared');
  }

  Future<void> _clearTransactions() async {
    await _db.transactionDao.deleteAllTransactions();
    _toast('All transactions cleared');
  }

  Future<void> _wipeEverything() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Wipe Everything?', style: AppTheme.heading.copyWith(fontSize: 18)),
        content: Text(
          'This deletes ALL data — projects, tasks, sessions, transactions — and re-seeds the database from scratch. This cannot be undone.',
          style: AppTheme.body.copyWith(fontSize: 14, color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: AppTheme.label.copyWith(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Wipe', style: AppTheme.label.copyWith(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    HapticFeedback.heavyImpact();
    final db = _db;

    // Delete in order (FK constraints: tasks before lists, lists before projects)
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

    // Force re-seed
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
    final pomState = ref.watch(pomodoroNotifierProvider);

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
                    icon: Icons.timer_outlined,
                    title: 'Pomodoro Controls',
                    color: AppTheme.pomodoroWork,
                    children: [
                      _buildPomodoroState(pomState),
                      const SizedBox(height: 12),
                      _buildSpeedRow(),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              label: 'Skip to End',
                              icon: Icons.skip_next_rounded,
                              color: AppTheme.pomodoroWork,
                              onTap: _skipToEnd,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _ActionButton(
                              label: 'Reset Timer',
                              icon: Icons.restart_alt_rounded,
                              color: AppTheme.textSecondary,
                              onTap: _resetTimer,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    icon: Icons.science_outlined,
                    title: 'Data Factory',
                    color: AppTheme.primaryLight,
                    children: [
                      _ActionButton(
                        label: 'Seed 7-Day Session History',
                        icon: Icons.calendar_today_outlined,
                        color: AppTheme.primaryLight,
                        onTap: _seed7DayHistory,
                        fullWidth: true,
                      ),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(child: _ActionButton(label: 'Complete 1 Task', icon: Icons.check_circle_outline, color: AppTheme.success, onTap: () => _completeRandomTasks(1))),
                        const SizedBox(width: 8),
                        Expanded(child: _ActionButton(label: 'Complete 5 Tasks', icon: Icons.checklist_rounded, color: AppTheme.success, onTap: () => _completeRandomTasks(5))),
                      ]),
                      const SizedBox(height: 8),
                      Text('Coins', style: AppTheme.label.copyWith(color: AppTheme.textSecondary)),
                      const SizedBox(height: 6),
                      Row(children: [
                        Expanded(child: _ActionButton(label: '+10', icon: Icons.add_circle_outline, color: AppTheme.warning, onTap: () => _addCoins(10))),
                        const SizedBox(width: 6),
                        Expanded(child: _ActionButton(label: '+50', icon: Icons.add_circle_outline, color: AppTheme.warning, onTap: () => _addCoins(50))),
                        const SizedBox(width: 6),
                        Expanded(child: _ActionButton(label: '+100', icon: Icons.add_circle_outline, color: AppTheme.warning, onTap: () => _addCoins(100))),
                        const SizedBox(width: 6),
                        Expanded(child: _ActionButton(label: '−25', icon: Icons.remove_circle_outline, color: AppTheme.coral, onTap: () => _spendCoins(25))),
                      ]),
                      const SizedBox(height: 12),
                      _buildInjectSessionForm(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    icon: Icons.storage_outlined,
                    title: 'Database Inspector',
                    color: AppTheme.pomodoroBreak,
                    children: [
                      _buildInspectorBlock(
                        label: 'Transactions',
                        isOpen: _showTransactions,
                        onOpen: _loadTransactions,
                        onClose: () => setState(() => _showTransactions = false),
                        child: _buildTransactionList(),
                      ),
                      const SizedBox(height: 8),
                      _buildInspectorBlock(
                        label: 'Pomodoro Sessions',
                        isOpen: _showSessions,
                        onOpen: _loadSessions,
                        onClose: () => setState(() => _showSessions = false),
                        child: _buildSessionList(),
                      ),
                      const SizedBox(height: 8),
                      _buildInspectorBlock(
                        label: 'All Tasks',
                        isOpen: _showTasks,
                        onOpen: _loadTasks,
                        onClose: () => setState(() => _showTasks = false),
                        child: _buildTaskList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    icon: Icons.warning_amber_rounded,
                    title: 'Reset Controls',
                    color: AppTheme.error,
                    children: [
                      Row(children: [
                        Expanded(child: _ActionButton(label: 'Clear Sessions', icon: Icons.delete_outline, color: AppTheme.error, onTap: _clearSessions)),
                        const SizedBox(width: 8),
                        Expanded(child: _ActionButton(label: 'Clear Transactions', icon: Icons.delete_outline, color: AppTheme.error, onTap: _clearTransactions)),
                      ]),
                      const SizedBox(height: 8),
                      _ActionButton(
                        label: 'WIPE EVERYTHING + Re-seed',
                        icon: Icons.local_fire_department_rounded,
                        color: AppTheme.error,
                        onTap: _wipeEverything,
                        fullWidth: true,
                        bold: true,
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

  // ── Sub-widgets ──────────────────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.surfaceBorder)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            color: AppTheme.textSecondary,
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 4),
          Icon(Icons.bug_report_rounded, size: 20, color: AppTheme.coral),
          const SizedBox(width: 8),
          Text('Debug Panel', style: AppTheme.heading.copyWith(fontSize: 18)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.error.withAlpha(30),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.error.withAlpha(80)),
            ),
            child: Text(
              'DEV ONLY',
              style: AppTheme.caption.copyWith(
                color: AppTheme.error,
                fontWeight: FontWeight.w700,
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
      error: (e, _) => const SizedBox.shrink(),
      data: (s) => Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.surfaceBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatChip(label: 'Projects', value: '${s.projects}'),
            _StatDivider(),
            _StatChip(label: 'Tasks', value: '${s.tasks}'),
            _StatDivider(),
            _StatChip(label: 'Sessions', value: '${s.sessions}'),
            _StatDivider(),
            _StatChip(label: 'Txns', value: '${s.transactions}'),
            _StatDivider(),
            _StatChip(label: 'Balance', value: '${s.balance.toStringAsFixed(0)}🪙'),
          ],
        ),
      ),
    );
  }

  Widget _buildPomodoroState(PomodoroState s) {
    String fmt(int sec) {
      final m = sec ~/ 60;
      final ss = sec % 60;
      return '${m.toString().padLeft(2, '0')}:${ss.toString().padLeft(2, '0')}';
    }

    final statusColor = switch (s.status) {
      PomodoroStatus.running => AppTheme.success,
      PomodoroStatus.paused => AppTheme.warning,
      PomodoroStatus.completed => AppTheme.coral,
      PomodoroStatus.idle => AppTheme.textDisabled,
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.elevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(fmt(s.secondsLeft),
                  style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              const SizedBox(height: 2),
              Row(children: [
                Container(
                  width: 7, height: 7,
                  decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 5),
                Text(s.status.name, style: AppTheme.caption.copyWith(color: statusColor)),
              ]),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _InfoRow(label: 'Phase', value: s.phase.name),
              _InfoRow(label: 'Sessions', value: '${s.completedSessions}'),
              _InfoRow(label: 'Task', value: s.attachedTaskId?.substring(0, 8) ?? 'none'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Timer Speed (applies when running)', style: AppTheme.caption),
        const SizedBox(height: 6),
        Row(
          children: [1, 10, 30, 60].map((m) {
            final selected = _speedMultiplier == m;
            return Expanded(
              child: GestureDetector(
                onTap: () => _setSpeed(m),
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? AppTheme.pomodoroWork.withAlpha(40) : AppTheme.elevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected ? AppTheme.pomodoroWork : AppTheme.surfaceBorder,
                    ),
                  ),
                  child: Text(
                    '${m}×',
                    textAlign: TextAlign.center,
                    style: AppTheme.label.copyWith(
                      color: selected ? AppTheme.pomodoroWork : AppTheme.textSecondary,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInjectSessionForm() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.elevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Inject Single Session', style: AppTheme.label.copyWith(color: AppTheme.textPrimary)),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('Type:', style: AppTheme.caption),
              const SizedBox(width: 8),
              ...['work', 'shortBreak', 'longBreak'].map((t) {
                final sel = _injectState.type == t;
                return GestureDetector(
                  onTap: () => setState(() => _injectState = _injectState.copyWith(type: t)),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: sel ? AppTheme.primary.withAlpha(40) : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: sel ? AppTheme.primary : AppTheme.surfaceBorder),
                    ),
                    child: Text(t, style: AppTheme.caption.copyWith(
                        color: sel ? AppTheme.primaryLight : AppTheme.textSecondary)),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Days ago:', style: AppTheme.caption),
              const SizedBox(width: 8),
              ...[0, 1, 2, 3, 5, 7].map((d) {
                final sel = _injectState.daysAgo == d;
                return GestureDetector(
                  onTap: () => setState(() => _injectState = _injectState.copyWith(daysAgo: d)),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: sel ? AppTheme.primary.withAlpha(40) : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: sel ? AppTheme.primary : AppTheme.surfaceBorder),
                    ),
                    child: Text('$d', style: AppTheme.caption.copyWith(
                        color: sel ? AppTheme.primaryLight : AppTheme.textSecondary)),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 10),
          _ActionButton(
            label: 'Inject Session',
            icon: Icons.add_circle_outline,
            color: AppTheme.primaryLight,
            onTap: _injectSession,
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInspectorBlock({
    required String label,
    required bool isOpen,
    required VoidCallback onOpen,
    required VoidCallback onClose,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: isOpen ? onClose : onOpen,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.elevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.surfaceBorder),
            ),
            child: Row(
              children: [
                Text(label, style: AppTheme.label.copyWith(color: AppTheme.textPrimary)),
                const Spacer(),
                Icon(
                  isOpen ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  color: AppTheme.textSecondary,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        if (isOpen)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.surfaceBorder),
            ),
            constraints: const BoxConstraints(maxHeight: 220),
            child: child,
          ),
      ],
    );
  }

  Widget _buildTransactionList() {
    if (_transactions.isEmpty) {
      return Center(child: Text('No transactions', style: AppTheme.caption));
    }
    final fmt = DateFormat('MMM d HH:mm');
    return ListView.separated(
      itemCount: _transactions.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: AppTheme.surfaceBorder),
      itemBuilder: (_, i) {
        final t = _transactions[i];
        final isEarn = t.type == 'earn';
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Icon(
                isEarn ? Icons.add_circle_outline : Icons.remove_circle_outline,
                size: 14,
                color: isEarn ? AppTheme.success : AppTheme.coral,
              ),
              const SizedBox(width: 6),
              Expanded(child: Text(t.note ?? '—', style: AppTheme.caption.copyWith(fontSize: 11))),
              Text(
                '${isEarn ? '+' : '−'}${t.amount.toInt()}',
                style: AppTheme.label.copyWith(
                    fontSize: 11,
                    color: isEarn ? AppTheme.success : AppTheme.coral),
              ),
              const SizedBox(width: 8),
              Text(fmt.format(t.createdAt), style: AppTheme.caption.copyWith(fontSize: 10)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSessionList() {
    if (_sessions.isEmpty) {
      return Center(child: Text('No sessions', style: AppTheme.caption));
    }
    final fmt = DateFormat('MMM d HH:mm');
    return ListView.separated(
      itemCount: _sessions.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: AppTheme.surfaceBorder),
      itemBuilder: (_, i) {
        final s = _sessions[i];
        final isWork = s.type == 'work';
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Icon(
                Icons.timer_outlined,
                size: 13,
                color: isWork ? AppTheme.pomodoroWork : AppTheme.pomodoroBreak,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  s.type + (s.taskId != null ? ' · ${s.taskId!.substring(0, 8)}' : ''),
                  style: AppTheme.caption.copyWith(fontSize: 11),
                ),
              ),
              Text('${s.duration}m', style: AppTheme.caption.copyWith(fontSize: 11)),
              const SizedBox(width: 8),
              Text(fmt.format(s.completedAt), style: AppTheme.caption.copyWith(fontSize: 10)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaskList() {
    if (_allTasks.isEmpty) {
      return Center(child: Text('No tasks', style: AppTheme.caption));
    }
    return ListView.separated(
      itemCount: _allTasks.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: AppTheme.surfaceBorder),
      itemBuilder: (_, i) {
        final t = _allTasks[i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Icon(
                t.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                size: 13,
                color: t.isCompleted ? AppTheme.success : AppTheme.textDisabled,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(t.title, style: AppTheme.caption.copyWith(fontSize: 11)),
              ),
              Text(
                '${t.completedPomodoro}/${t.estimatedPomodoro}🍅  ${t.price.toInt()}🪙',
                style: AppTheme.caption.copyWith(fontSize: 10),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Text(title, style: AppTheme.label.copyWith(color: color, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Divider(height: 1, color: AppTheme.surfaceBorder),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable Widgets ──────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool fullWidth;
  final bool bold;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.fullWidth = false,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: color.withAlpha(22),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: color.withAlpha(70)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        Text(label, style: AppTheme.caption.copyWith(fontSize: 10)),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 24, color: AppTheme.surfaceBorder);
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Text('$label  ', style: AppTheme.caption.copyWith(fontSize: 11)),
          Text(value, style: AppTheme.label.copyWith(fontSize: 11, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}