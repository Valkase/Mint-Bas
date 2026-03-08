import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/flavor/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/database/app_database.dart';
import '../providers/tag_providers.dart';
import '../providers/tasks_notifier.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  final String listId;
  const TaskListScreen({super.key, required this.listId});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  final Set<String> _completing = {};

  @override
  Widget build(BuildContext context) {
    // Use the formal provider from tasks_notifier.dart
    final listAsync = ref.watch(listByIdProvider(widget.listId));
    final tasksAsync = ref.watch(tasksStreamProvider(widget.listId));

    final s = AppStrings.of(ref);
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: listAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Error: $e')),
          data: (list) {
            if (list == null) {
              return const Center(child: Text('List not found'));
            }
            return _buildBody(context, list, tasksAsync, s);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateTaskSheet(context),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context,
      TaskList list,
      AsyncValue<List<Task>> tasksAsync,
      AppStrings s,
      ) {
    return tasksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
      data: (tasks) {
        final incomplete = tasks.where((t) => !t.isCompleted).toList();
        final completed = tasks.where((t) => t.isCompleted).toList();

        final pct = tasks.isEmpty ? 0.0 : completed.length / tasks.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration:  BoxDecoration(
                              color: AppTheme.surface, shape: BoxShape.circle),
                          child:  Icon(Icons.arrow_back,
                              color: AppTheme.textSecondary, size: 18),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(list.name,
                              style: AppTheme.heading,
                              overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 6,
                            backgroundColor: AppTheme.surface,
                            valueColor:
                            AlwaysStoppedAnimation(AppTheme.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('${(pct * 100).round()}%',
                          style: AppTheme.caption.copyWith(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                      '${completed.length}/${tasks.length} tasks',
                      style: AppTheme.caption.copyWith(fontSize: 11)),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Expanded(
              child: tasks.isEmpty
                  ? _EmptyState(s: s, onAdd: () => _showCreateTaskSheet(context))
                  : ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                children: [
                  ...incomplete.map((task) => Dismissible(
                    key: ValueKey(task.id),
                    direction: DismissDirection.startToEnd,
                    onDismissed: (_) => _completeTask(task),
                    background: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(16)),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 24),
                      child: Row(children: [
                        const Icon(Icons.check_circle_outline,
                            color: Colors.white, size: 22),
                        const SizedBox(width: 10),
                        Text(s.tasksDone,
                            style: AppTheme.label.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ]),
                    ),
                    child: _TaskCard(
                      task: task,
                      completing: _completing.contains(task.id),
                      onTap: () => context.push('/task/${task.id}'),
                      onComplete: () => _completeTask(task),
                      onFocus: () => _startFocus(context, task),
                      s: s,
                    ),
                  )),
                  if (completed.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Row(children: [
                      Expanded(
                          child: Divider(
                              color: AppTheme.surfaceBorder, thickness: 1)),
                      Padding(
                          padding:
                          const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(s.tasksDone.toUpperCase(),
                              style: AppTheme.caption.copyWith(
                                  fontSize: 10, letterSpacing: 1.2))),
                      Expanded(
                          child: Divider(
                              color: AppTheme.surfaceBorder, thickness: 1)),
                    ]),
                    const SizedBox(height: 8),
                    ...completed.map((task) => Opacity(
                        opacity: 0.5,
                        child: _TaskCard(
                            task: task,
                            completing: false,
                            onTap: () => context.push('/task/${task.id}'),
                            onComplete: () {},
                            onFocus: null,
                            s: s))),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _completeTask(Task task) async {
    if (task.isCompleted) return;
    setState(() => _completing.add(task.id));
    HapticFeedback.mediumImpact();
    await ref.read(tasksNotifierProvider.notifier).completeTask(task.id);
    if (mounted) {
      setState(() => _completing.remove(task.id));
      _showCoinEarned(task.price.toInt());
    }
  }

  void _startFocus(BuildContext context, Task task) {
    HapticFeedback.mediumImpact();
    context.push('/pomodoro?taskId=${task.id}');
  }

  void _showCoinEarned(int coins) {
    if (coins <= 0) return;
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
        builder: (ctx) =>
            _CoinEarnedOverlay(coins: coins, onDone: () => entry.remove()));
    overlay.insert(entry);
  }

  void _showCreateTaskSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.elevated,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _CreateTaskSheet(listId: widget.listId),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;
  final bool completing;
  final VoidCallback onTap;
  final VoidCallback onComplete;
  final VoidCallback? onFocus;
  final AppStrings s;
  const _TaskCard(
      {required this.task,
        required this.completing,
        required this.onTap,
        required this.onComplete,
        required this.onFocus,
        required this.s});

  Color get _priorityColor {
    return switch (task.priority) {
      1 => AppTheme.error,
      2 => AppTheme.warning,
      3 => AppTheme.primary,
      _ => AppTheme.surfaceBorder,
    };
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border(left: BorderSide(color: _priorityColor, width: 3))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: onComplete,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: task.isCompleted || completing
                              ? AppTheme.primary
                              : Colors.transparent,
                          border: Border.all(
                              color: task.isCompleted || completing
                                  ? AppTheme.primary
                                  : AppTheme.textDisabled,
                              width: 1.5)),
                      child: task.isCompleted || completing
                          ? const Icon(Icons.check,
                          color: Colors.white, size: 13)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(task.title,
                          style: AppTheme.body.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              color: task.isCompleted
                                  ? AppTheme.textSecondary
                                  : AppTheme.textPrimary))),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [

                  if (task.price > 0) _CoinBadge(coins: task.price.toInt()),
                  if (task.deadline != null) ...[
                    const SizedBox(width: 6),
                    _DeadlineBadge(deadline: task.deadline!, s: s)
                  ],
                  const Spacer(),
                  if (onFocus != null)
                    GestureDetector(
                      onTap: onFocus,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                            color: AppTheme.primary.withAlpha(31),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppTheme.primary.withAlpha(76))),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.timer_outlined,
                              color: AppTheme.primary, size: 13),
                          const SizedBox(width: 4),
                          Text('Focus',
                              style: AppTheme.label.copyWith(
                                  color: AppTheme.primary, fontSize: 12)),
                        ]),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoinBadge extends StatelessWidget {
  final int coins;
  const _CoinBadge({required this.coins});
  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
            color: AppTheme.coral.withAlpha(38),
            borderRadius: BorderRadius.circular(6)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.monetization_on_outlined,
              size: 11, color: AppTheme.coral),
          const SizedBox(width: 3),
          Text('$coins',
              style: AppTheme.label.copyWith(color: AppTheme.coral, fontSize: 11))
        ]));
  }
}

class _DeadlineBadge extends StatelessWidget {
  final DateTime deadline;
  final AppStrings s;
  const _DeadlineBadge({required this.deadline, required this.s});
  @override
  Widget build(BuildContext context) {
    final diff = deadline.difference(DateTime.now()).inDays;
    final color = diff < 0
        ? AppTheme.error
        : diff == 0
        ? AppTheme.warning
        : AppTheme.textSecondary;
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
            color: color.withAlpha(25), borderRadius: BorderRadius.circular(6)),
        child: Text(diff < 0 ? s.tasksOverdue : diff == 0 ? s.tasksToday : '${diff}d left',
            style: AppTheme.label.copyWith(color: color, fontSize: 11)));
  }
}

class _CoinEarnedOverlay extends StatefulWidget {
  final int coins;
  final VoidCallback onDone;
  const _CoinEarnedOverlay({required this.coins, required this.onDone});
  @override
  State<_CoinEarnedOverlay> createState() => _CoinEarnedOverlayState();
}

class _CoinEarnedOverlayState extends State<_CoinEarnedOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _scale = Tween<double>(begin: 0.6, end: 1.1).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.4)));
    _opacity = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.3)));
    _offset = Tween<Offset>(begin: Offset.zero, end: const Offset(0, -0.3))
        .animate(CurvedAnimation(
        parent: _ctrl, curve: const Interval(0.5, 1, curve: Curves.easeIn)));
    _ctrl.forward().then((_) => widget.onDone());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
        bottom: 120,
        left: 0,
        right: 0,
        child: Center(
            child: AnimatedBuilder(
                animation: _ctrl,
                builder: (ctx, _) => FadeTransition(
                    opacity: _opacity,
                    child: SlideTransition(
                        position: _offset,
                        child: ScaleTransition(
                            scale: _scale,
                            child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                    color: AppTheme.elevated,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                        color: AppTheme.coral.withAlpha(102)),
                                    boxShadow: [
                                      BoxShadow(
                                          color: AppTheme.coral.withAlpha(51),
                                          blurRadius: 20)
                                    ]),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(Icons.monetization_on,
                                      color: AppTheme.coral, size: 18),
                                  const SizedBox(width: 6),
                                  Text('+${widget.coins} coins',
                                      style: AppTheme.label.copyWith(
                                          color: AppTheme.coral,
                                          fontWeight: FontWeight.w600))
                                ]))))))));
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  final AppStrings s;
  const _EmptyState({required this.onAdd, required this.s});
  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.checklist_rtl_outlined,
              size: 48, color: AppTheme.textDisabled),
          const SizedBox(height: 16),
          Text(s.tasksEmptyTitle, style: AppTheme.body),
          const SizedBox(height: 6),
          Text(s.tasksEmptyBody,
              style: AppTheme.caption, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          GestureDetector(
              onTap: onAdd,
              child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(12)),
                  child: Text(s.tasksAddButton,
                      style: AppTheme.label.copyWith(color: Colors.white))))
        ]));
  }
}

class _CreateTaskSheet extends ConsumerStatefulWidget {
  final String listId;
  const _CreateTaskSheet({required this.listId});
  @override
  ConsumerState<_CreateTaskSheet> createState() => _CreateTaskSheetState();
}

class _CreateTaskSheetState extends ConsumerState<_CreateTaskSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  int _priority = 3;
  int _coins = 10;
  int _pomodoros = 1;
  DateTime? _deadline;
  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppTheme.primary,
            surface: AppTheme.elevated,
            onSurface: AppTheme.textPrimary,
          ),
          dialogBackgroundColor: AppTheme.elevated,
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  void _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    await ref.read(tasksNotifierProvider.notifier).createTask(
        listId: widget.listId,
        title: title,
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        priority: _priority,
        price: _coins.toDouble(),
        estimatedPomodoros: _pomodoros,
        deadline: _deadline);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 32),
      child: SingleChildScrollView(
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: AppTheme.surfaceBorder,
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text('New Task', style: AppTheme.heading),
              const SizedBox(height: 20),
              TextField(
                  controller: _titleCtrl,
                  autofocus: true,
                  style: AppTheme.body,
                  decoration: _inputDecoration('Task title')),
              const SizedBox(height: 12),
              TextField(
                  controller: _descCtrl,
                  style: AppTheme.body.copyWith(fontSize: 14),
                  maxLines: 2,
                  decoration: _inputDecoration('Description (optional)')),
              const SizedBox(height: 20),
              Text('Priority', style: AppTheme.label),
              const SizedBox(height: 10),
              Row(children: [
                _PriorityChip(
                    label: 'High',
                    value: 1,
                    selected: _priority == 1,
                    color: AppTheme.error,
                    onTap: () => setState(() => _priority = 1)),
                const SizedBox(width: 8),
                _PriorityChip(
                    label: 'Medium',
                    value: 2,
                    selected: _priority == 2,
                    color: AppTheme.warning,
                    onTap: () => setState(() => _priority = 2)),
                const SizedBox(width: 8),
                _PriorityChip(
                    label: 'Low',
                    value: 3,
                    selected: _priority == 3,
                    color: AppTheme.primary,
                    onTap: () => setState(() => _priority = 3)),
              ]),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                    child: _Stepper(
                        label: 'Coins',
                        value: _coins,
                        step: 5,
                        min: 0,
                        max: 100,
                        onChanged: (v) => setState(() => _coins = v))),
                const SizedBox(width: 16),
                Expanded(
                    child: _Stepper(
                        label: 'Pomodoros',
                        value: _pomodoros,
                        step: 1,
                        min: 1,
                        max: 20,
                        onChanged: (v) => setState(() => _pomodoros = v))),
              ]),
              const SizedBox(height: 16),
              // Deadline picker
              GestureDetector(
                onTap: _pickDeadline,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _deadline != null
                              ? AppTheme.primary.withAlpha(76)
                              : AppTheme.surfaceBorder)),
                  child: Row(children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 16,
                        color: _deadline != null
                            ? AppTheme.primary
                            : AppTheme.textSecondary),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(
                          _deadline != null
                              ? '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}'
                              : 'Set deadline (optional)',
                          style: AppTheme.body.copyWith(
                              fontSize: 14,
                              color: _deadline != null
                                  ? AppTheme.textPrimary
                                  : AppTheme.textSecondary),
                        )),
                    if (_deadline != null)
                      GestureDetector(
                        onTap: () => setState(() => _deadline = null),
                        child:  Icon(Icons.close,
                            size: 16, color: AppTheme.textSecondary),
                      ),
                  ]),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                      onTap: _save,
                      child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(14)),
                          child: Text('Save Task',
                              style: AppTheme.label.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15),
                              textAlign: TextAlign.center)))),
            ]),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: AppTheme.caption,
      filled: true,
      fillColor: AppTheme.surface,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none));
}

class _PriorityChip extends StatelessWidget {
  final String label;
  final int value;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _PriorityChip(
      {required this.label,
        required this.value,
        required this.selected,
        required this.color,
        required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                color: selected ? color.withAlpha(38) : AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: selected ? color : AppTheme.surfaceBorder)),
            child: Text(label,
                style: AppTheme.label.copyWith(
                    color: selected ? color : AppTheme.textSecondary,
                    fontSize: 12))));
  }
}

class _Stepper extends StatelessWidget {
  final String label;
  final int value;
  final int step;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  const _Stepper(
      {required this.label,
        required this.value,
        required this.step,
        required this.min,
        required this.max,
        required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTheme.label),
      const SizedBox(height: 8),
      Container(
          decoration: BoxDecoration(
              color: AppTheme.surface, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            _StepBtn(
                icon: Icons.remove,
                onTap: value > min
                    ? () => onChanged((value - step).clamp(min, max))
                    : null),
            Expanded(
                child: Text('$value',
                    style: AppTheme.body.copyWith(fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center)),
            _StepBtn(
                icon: Icons.add,
                onTap: value < max
                    ? () => onChanged((value + step).clamp(min, max))
                    : null),
          ])),
    ]);
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _StepBtn({required this.icon, this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onTap,
        child: Container(
            width: 40,
            height: 44,
            decoration: BoxDecoration(
                color: onTap != null
                    ? AppTheme.primary.withAlpha(31)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon,
                size: 16,
                color: onTap != null ? AppTheme.primary : AppTheme.textDisabled)));
  }
}