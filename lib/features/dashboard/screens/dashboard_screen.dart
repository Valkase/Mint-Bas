import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/database/app_database.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../banking/providers/banking_notifier.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(balanceStreamProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Header(),
              const SizedBox(height: 8),
              statsAsync.when(
                loading: () => Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primary,
                      strokeWidth: 2,
                    ),
                  ),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Could not load stats.',
                    style: AppTheme.caption.copyWith(color: AppTheme.error),
                  ),
                ),
                data: (stats) => Column(
                  children: [
                    _ProgressRing(sessions: stats.allSessions),
                    _StatChips(
                      minutesFocused: stats.totalMinutesFocused,
                      balance: balanceAsync.value ?? 0,
                      sessionsCompleted: stats.allSessions
                          .where((s) => s.type == 'work')
                          .length,
                    ),
                    _PomodoroTimeline(sessions: stats.allSessions),
                    _FocusBarChart(sessions: stats.allSessions),
                    const _MostProductiveList(),
                    const _EncouragementCard(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header();

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE, MMMM d').format(DateTime.now()),
                style: AppTheme.caption,
              ),
              const SizedBox(height: 4),
              Text(_greeting, style: AppTheme.heading),
            ],
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.surfaceBorder),
            ),
            child:  Icon(
              Icons.notifications_outlined,
              color: AppTheme.textSecondary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Progress Ring ─────────────────────────────────────────────

class _ProgressRing extends StatelessWidget {
  final List<PomodoroSession> sessions;
  const _ProgressRing({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final thisWeek = sessions.where((s) =>
    s.type == 'work' && s.completedAt.isAfter(weekStart)).length;
    final progress = (thisWeek / 20).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOut,
                  builder: (context, value, _) => CustomPaint(
                    size: const Size(200, 200),
                    painter: _RingPainter(progress: value),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: AppTheme.display.copyWith(fontSize: 36),
                    ),
                    Text('this week', style: AppTheme.caption),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$thisWeek focus sessions completed',
            style: AppTheme.body.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFF2C302E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -1.5708,
        2 * 3.14159 * progress,
        false,
        Paint()
          ..color = AppTheme.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

// ── Stat Chips ────────────────────────────────────────────────

class _StatChips extends StatelessWidget {
  final int minutesFocused;
  final double balance;
  final int sessionsCompleted;

  const _StatChips({
    required this.minutesFocused,
    required this.balance,
    required this.sessionsCompleted,
  });

  String _formatTime(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _Chip(
              icon: Icons.timer_outlined,
              iconColor: AppTheme.primary,
              value: _formatTime(minutesFocused),
              label: 'Focused',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _Chip(
              icon: Icons.local_fire_department_outlined,
              iconColor: AppTheme.coral,
              value: '$sessionsCompleted',
              label: 'Sessions',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _Chip(
              icon: Icons.monetization_on_outlined,
              iconColor: const Color(0xFFEAB308),
              value: balance.toStringAsFixed(0),
              label: 'Coins',
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _Chip({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withAlpha(38),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(height: 8),
          Text(value, style: AppTheme.heading.copyWith(fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTheme.caption.copyWith(fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Pomodoro Timeline ─────────────────────────────────────────

class _PomodoroTimeline extends StatelessWidget {
  final List<PomodoroSession> sessions;
  const _PomodoroTimeline({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    final bucketLabels = ['0h', '6h', '12h', '18h'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(title: 'Pomodoro Records', subtitle: 'Last 7 days'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.surfaceBorder),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const SizedBox(width: 40),
                    ...List.generate(
                      4,
                          (i) => Expanded(
                        child: Text(
                          bucketLabels[i],
                          style: AppTheme.caption.copyWith(fontSize: 9),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...days.map((day) {
                  final daySessions = sessions
                      .where((s) =>
                  s.completedAt.year == day.year &&
                      s.completedAt.month == day.month &&
                      s.completedAt.day == day.day)
                      .toList();

                  final buckets = List.generate(4, (bucket) {
                    final startHour = bucket * 6;
                    final endHour = startHour + 6;
                    return daySessions
                        .where((s) =>
                    s.completedAt.hour >= startHour &&
                        s.completedAt.hour < endHour)
                        .length;
                  });

                  final isToday = day.day == now.day &&
                      day.month == now.month &&
                      day.year == now.year;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 40,
                          child: Text(
                            isToday ? 'Today' : DateFormat('E').format(day),
                            style: AppTheme.caption.copyWith(
                              fontSize: 10,
                              color: isToday
                                  ? AppTheme.primary
                                  : AppTheme.textSecondary,
                              fontWeight: isToday
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        ...List.generate(4, (i) {
                          final count = buckets[i];
                          return Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              height: 24,
                              decoration: BoxDecoration(
                                color: count == 0
                                    ? AppTheme.primary.withAlpha(15)
                                    : AppTheme.primary.withAlpha(
                                    (count * 51).clamp(38, 230)),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: count > 0
                                  ? Center(
                                child: Text(
                                  '$count',
                                  style: AppTheme.caption.copyWith(
                                    fontSize: 9,
                                    color: Colors.white.withAlpha(230),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                                  : null,
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('Less', style: AppTheme.caption.copyWith(fontSize: 9)),
                    const SizedBox(width: 4),
                    ...List.generate(5, (i) => Container(
                      margin: const EdgeInsets.only(right: 3),
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withAlpha(25 + i * 46),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    )),
                    Text('More', style: AppTheme.caption.copyWith(fontSize: 9)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Focus Bar Chart ───────────────────────────────────────────

class _FocusBarChart extends StatelessWidget {
  final List<PomodoroSession> sessions;
  const _FocusBarChart({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));

    final dayHours = List.generate(days.length, (i) {
      final day = days[i];
      final minutes = sessions
          .where((s) =>
      s.type == 'work' &&
          s.completedAt.year == day.year &&
          s.completedAt.month == day.month &&
          s.completedAt.day == day.day)
      // FIX: duration is stored in minutes — dividing by 60 gave 0 for every
      // session under an hour, making all bars invisible.
          .fold<int>(0, (sum, s) => sum + s.duration);
      return minutes / 60.0;
    });

    final maxDayHours = dayHours.reduce((a, b) => a > b ? a : b);
    final maxY = (maxDayHours + 1.0).clamp(4.0, 24.0);

    final barGroups = List.generate(days.length, (i) {
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: dayHours[i],
            color: i == days.length - 1 ? AppTheme.coral : AppTheme.primary,
            width: 18,
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(4)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxY,
              color: AppTheme.primary.withAlpha(15),
            ),
          ),
        ],
      );
    });

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Focus Time',
            subtitle: 'Hours per day this week',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.surfaceBorder),
            ),
            child: SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  minY: 0,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY / 4,
                    getDrawingHorizontalLine: (_) =>  FlLine(
                      color: AppTheme.surfaceBorder,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: 1,
                        getTitlesWidget: (value, _) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            '${value.toInt()}h',
                            style: AppTheme.caption.copyWith(fontSize: 9),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          final day = days[value.toInt()];
                          final isToday = value.toInt() == 6;
                          return Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              isToday ? 'Today' : DateFormat('E').format(day),
                              style: AppTheme.caption.copyWith(
                                fontSize: 9,
                                color: isToday
                                    ? AppTheme.coral
                                    : AppTheme.textSecondary,
                                fontWeight: isToday
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: barGroups,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => AppTheme.elevated,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final hours = rod.toY;
                        final mins = ((hours % 1) * 60).round();
                        final label = mins == 0
                            ? '${hours.toInt()}h'
                            : '${hours.toInt()}h ${mins}m';
                        return BarTooltipItem(
                          label,
                          AppTheme.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Most Productive List ──────────────────────────────────────

class _ListStat {
  final TaskList list;
  final int total;
  final int completed;

  const _ListStat({
    required this.list,
    required this.total,
    required this.completed,
  });

  double get rate => total == 0 ? 0.0 : completed / total;
}

// FIX: StreamProvider so rankings update live when tasks are completed,
// instead of freezing at whatever state they were in at app startup.
final _listStatsProvider = StreamProvider<List<_ListStat>>((ref) {
  final taskDao    = ref.watch(taskDaoProvider);
  final projectDao = ref.watch(projectDaoProvider);

  // Watch all lists reactively; rebuild whenever any list/task changes
  return projectDao.watchAllLists().asyncMap((allLists) async {
    final stats = <_ListStat>[];
    for (final list in allLists) {
      final tasks = await taskDao.watchTasksForList(list.id).first;
      if (tasks.isEmpty) continue;
      stats.add(_ListStat(
        list:      list,
        total:     tasks.length,
        completed: tasks.where((t) => t.isCompleted).length,
      ));
    }
    stats.sort((a, b) => b.rate.compareTo(a.rate));
    return stats.take(5).toList();
  });
});

class _MostProductiveList extends ConsumerWidget {
  const _MostProductiveList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(_listStatsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Most Productive Lists',
            subtitle: 'By completion rate',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.surfaceBorder),
            ),
            child: statsAsync.when(
              loading: () =>  SizedBox(
                height: 80,
                child: Center(
                  child: CircularProgressIndicator(
                      color: AppTheme.primary, strokeWidth: 2),
                ),
              ),
              error: (e, _) => Text(
                'Could not load list stats.',
                style: AppTheme.caption.copyWith(color: AppTheme.error),
              ),
              data: (stats) {
                if (stats.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      children: [
                         Icon(Icons.checklist_outlined,
                            color: AppTheme.textDisabled, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Complete some tasks to see rankings.',
                          style: AppTheme.caption,
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: stats.asMap().entries.map((entry) {
                    final rank = entry.key;
                    final stat = entry.value;
                    return _ListRankRow(
                      stat: stat,
                      rank: rank,
                      isLast: rank == stats.length - 1,
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ListRankRow extends StatelessWidget {
  final _ListStat stat;
  final int rank;
  final bool isLast;

  const _ListRankRow({
    required this.stat,
    required this.rank,
    required this.isLast,
  });

  Color _rankColor(int rank) => switch (rank) {
    0 => const Color(0xFFEAB308), // gold
    1 => const Color(0xFF94A3B8), // silver
    2 => const Color(0xFFB45309), // bronze
    _ => AppTheme.textDisabled,
  };

  @override
  Widget build(BuildContext context) {
    final pct = (stat.rate * 100).round();
    final rankColor = _rankColor(rank);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: rankColor.withAlpha(rank < 3 ? 38 : 20),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${rank + 1}',
                    style: AppTheme.label.copyWith(
                      color: rankColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stat.list.name,
                      style: AppTheme.body.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: stat.rate),
                        duration: Duration(milliseconds: 700 + rank * 100),
                        curve: Curves.easeOut,
                        builder: (_, value, __) => LinearProgressIndicator(
                          value: value,
                          minHeight: 5,
                          backgroundColor: AppTheme.primary.withAlpha(20),
                          valueColor: AlwaysStoppedAnimation(
                            rank == 0
                                ? AppTheme.primary
                                : AppTheme.primary.withAlpha(180),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$pct%',
                    style: AppTheme.body.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${stat.completed}/${stat.total}',
                    style: AppTheme.caption.copyWith(fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (!isLast) Divider(color: AppTheme.surfaceBorder, height: 1),
      ],
    );
  }
}

// ── Encouragement Card ────────────────────────────────────────

class _EncouragementCard extends StatelessWidget {
  const _EncouragementCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primary.withAlpha(31),
              AppTheme.primary.withAlpha(8),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primary.withAlpha(38)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Icon(Icons.spa_outlined, color: AppTheme.primary, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '"Small steps are still progress. You\'re doing just fine."',
                style: AppTheme.body.copyWith(
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          style: AppTheme.body.copyWith(fontWeight: FontWeight.w600),
        ),
        Text(subtitle, style: AppTheme.caption.copyWith(fontSize: 11)),
      ],
    );
  }
}