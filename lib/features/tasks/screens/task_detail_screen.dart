import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/database/app_database.dart';
import '../providers/tasks_notifier.dart';
import '../providers/tag_providers.dart';
import '../../../shared/providers/repository_providers.dart';

// Top-level provider — avoids re-creating a StreamProvider on every build()
final _taskByIdProvider = StreamProvider.family<Task?, String>(
      (ref, taskId) => ref.watch(taskDaoProvider).watchTaskById(taskId),
);

class TaskDetailScreen extends ConsumerStatefulWidget {
  final String taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen>
    with SingleTickerProviderStateMixin {
  bool _showSuccess = false;
  late AnimationController _successCtrl;
  late Animation<double> _successScale;
  late Animation<double> _successOpacity;

  @override
  void initState() {
    super.initState();
    _successCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _successScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _successCtrl, curve: Curves.elasticOut),
    );
    _successOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _successCtrl, curve: const Interval(0, 0.3)),
    );
  }

  @override
  void dispose() {
    _successCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskAsync = ref.watch(_taskByIdProvider(widget.taskId));
    final stepsAsync = ref.watch(stepsStreamProvider(widget.taskId));
    final tagsAsync = ref.watch(tagsForTaskProvider(widget.taskId));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          taskAsync.when(
            loading: () =>
            const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
            data: (task) {
              if (task == null) {
                return const Center(child: Text('Task not found'));
              }
              return _buildBody(context, task, stepsAsync, tagsAsync);
            },
          ),

          // ── Success overlay ──────────────────────────────────────────
          if (_showSuccess)
            _SuccessOverlay(
              task: taskAsync.value,
              scaleAnim: _successScale,
              opacityAnim: _successOpacity,
            ),
        ],
      ),
    );
  }

  Widget _buildBody(
      BuildContext context,
      Task task,
      AsyncValue<List<TaskStep>> stepsAsync,
      AsyncValue<List<Tag>> tagsAsync,
      ) {
    return Column(
      children: [
        // ── Safe area top + header ─────────────────────────────────────
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                _IconBtn(
                  icon: Icons.arrow_back,
                  onTap: () => context.pop(),
                ),
                const Spacer(),
                _IconBtn(
                  icon: Icons.edit_outlined,
                  onTap: () => _showEditSheet(context, task),
                ),
              ],
            ),
          ),
        ),

        // ── Scrollable content ─────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(task.title, style: AppTheme.heading.copyWith(fontSize: 24)),
                const SizedBox(height: 12),

                // Meta chips row
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetaChip(
                      icon: Icons.flag_outlined,
                      label: _priorityLabel(task.priority),
                      color: _priorityColor(task.priority),
                    ),
                    if (task.deadline != null)
                      _MetaChip(
                        icon: Icons.calendar_today_outlined,
                        label: _fmtDate(task.deadline!),
                        color: _deadlineColor(task.deadline!),
                      ),
                    if (task.price > 0)
                      _MetaChip(
                        icon: Icons.monetization_on_outlined,
                        label: '${task.price.toInt()} coins',
                        color: AppTheme.coral,
                      ),
                    if (task.isCompleted)
                      _MetaChip(
                        icon: Icons.check_circle_outline,
                        label: 'Done',
                        color: AppTheme.success,
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── FOCUS BUTTON ─────────────────────────────────────────
                if (!task.isCompleted)
                  _FocusButton(
                    onTap: () => _startFocus(context, task),
                  ),

                const SizedBox(height: 20),

                // Tags
                _TagsSection(
                  taskId: task.id,
                  tagsAsync: tagsAsync,
                ),
                const SizedBox(height: 20),

                // Description
                if (task.description != null &&
                    task.description!.isNotEmpty) ...[
                  _SectionLabel('Notes'),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      task.description!,
                      style: AppTheme.body.copyWith(
                        fontSize: 14,
                        height: 1.6,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Sub-tasks / steps
                _SectionLabel('Sub-tasks'),
                const SizedBox(height: 10),
                stepsAsync.when(
                  loading: () => const SizedBox(height: 40),
                  error: (e, st) => Text('Error: $e'),
                  data: (steps) => _StepsSection(
                    taskId: task.id,
                    steps: steps,
                  ),
                ),
                const SizedBox(height: 100), // space for bottom button
              ],
            ),
          ),
        ),

        // ── Complete button (fixed bottom) ────────────────────────────
        if (!task.isCompleted)
          SafeArea(
            top: false,
            child: _CompleteButton(onTap: () => _completeTask(task)),
          ),
      ],
    );
  }

  // ── Actions ─────────────────────────────────────────────────────────

  void _startFocus(BuildContext context, Task task) {
    HapticFeedback.mediumImpact();
    context.push('/pomodoro?taskId=${task.id}');
  }

  void _completeTask(Task task) async {
    HapticFeedback.mediumImpact();
    await ref.read(tasksNotifierProvider.notifier).completeTask(task.id);
    setState(() => _showSuccess = true);
    _successCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 2000));
    _successCtrl.reverse().then((_) {
      if (mounted) {
        setState(() => _showSuccess = false);
        context.pop();
      }
    });
  }

  void _showEditSheet(BuildContext context, Task task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.elevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EditSheet(task: task),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────

  String _priorityLabel(int? p) => switch (p) {
    1 => 'High Priority',
    2 => 'Medium',
    3 => 'Low',
    _ => 'No Priority',
  };

  Color _priorityColor(int? p) => switch (p) {
    1 => AppTheme.error,
    2 => AppTheme.warning,
    3 => AppTheme.primary,
    _ => AppTheme.textDisabled,
  };

  String _fmtDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';

  Color _deadlineColor(DateTime d) {
    final diff = d.difference(DateTime.now()).inDays;
    if (diff < 0) return AppTheme.error;
    if (diff == 0) return AppTheme.warning;
    return AppTheme.textSecondary;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Focus Button  — big, prominent, placed right after meta chips
// ─────────────────────────────────────────────────────────────────────────────

class _FocusButton extends StatelessWidget {
  final VoidCallback onTap;
  const _FocusButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.primary.withAlpha(31),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppTheme.primary.withAlpha(102),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Icon(
              Icons.timer_outlined,
              color: AppTheme.primary,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              'Start Focus Session',
              style: AppTheme.label.copyWith(
                color: AppTheme.primary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tags Section
// ─────────────────────────────────────────────────────────────────────────────

class _TagsSection extends ConsumerWidget {
  final String taskId;
  final AsyncValue<List<Tag>> tagsAsync;

  const _TagsSection({required this.taskId, required this.tagsAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _SectionLabel('Tags'),
            const Spacer(),
            GestureDetector(
              onTap: () => _showTagPicker(context, ref),
              child: Text(
                'Manage',
                style: AppTheme.caption.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        tagsAsync.when(
          loading: () => const SizedBox(height: 32),
          error: (_, __) => const SizedBox.shrink(),
          data: (tags) => tags.isEmpty
              ? Text(
            'No tags yet',
            style: AppTheme.caption,
          )
              : Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags
                .map((tag) => _TagChip(
              tag: tag,
              onRemove: () => ref
                  .read(tagNotifierProvider.notifier)
                  .removeTagFromTask(
                taskId: taskId,
                tagId: tag.id,
              ),
            ))
                .toList(),
          ),
        ),
      ],
    );
  }

  void _showTagPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.elevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: _TagPickerSheet(taskId: taskId),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final Tag tag;
  final VoidCallback onRemove;

  const _TagChip({required this.tag, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse(tag.color.replaceFirst('#', 'FF'), radix: 16));
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 6, 5),
      decoration: BoxDecoration(
        color: color.withAlpha(31),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tag.name,
            style: AppTheme.label.copyWith(color: color, fontSize: 12),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, color: color, size: 14),
          ),
        ],
      ),
    );
  }
}

class _TagPickerSheet extends ConsumerStatefulWidget {
  final String taskId;
  const _TagPickerSheet({required this.taskId});

  @override
  ConsumerState<_TagPickerSheet> createState() => _TagPickerSheetState();
}

class _TagPickerSheetState extends ConsumerState<_TagPickerSheet> {
  final _nameCtrl = TextEditingController();
  String _selectedColor = '#4A7C59';
  final _colors = [
    '#4A7C59', '#D4785A', '#5A9E6A', '#C4965A',
    '#7C5A9E', '#5A7C9E', '#9E5A5A', '#9E9E5A',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allTagsAsync = ref.watch(allTagsProvider);
    final taskTagsAsync = ref.watch(tagsForTaskProvider(widget.taskId));

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
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
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Manage Tags', style: AppTheme.heading),
          const SizedBox(height: 16),

          // All available tags
          allTagsAsync.when(
            loading: () => const SizedBox(height: 40),
            error: (_, __) => const SizedBox.shrink(),
            data: (allTags) {
              final taskTags = taskTagsAsync.value ?? [];
              final taskTagIds = taskTags.map((t) => t.id).toSet();

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: allTags
                    .map((tag) {
                  final attached = taskTagIds.contains(tag.id);
                  final color = Color(int.parse(
                      tag.color.replaceFirst('#', 'FF'),
                      radix: 16));
                  return GestureDetector(
                    onTap: () {
                      if (attached) {
                        ref
                            .read(tagNotifierProvider.notifier)
                            .removeTagFromTask(
                          taskId: widget.taskId,
                          tagId: tag.id,
                        );
                      } else {
                        ref
                            .read(tagNotifierProvider.notifier)
                            .addTagToTask(
                          taskId: widget.taskId,
                          tagId: tag.id,
                        );
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: attached
                            ? color.withAlpha(51)
                            : AppTheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: attached
                              ? color
                              : AppTheme.surfaceBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (attached)
                            Padding(
                              padding: const EdgeInsets.only(right: 5),
                              child: Icon(Icons.check,
                                  size: 12, color: color),
                            ),
                          Text(
                            tag.name,
                            style: AppTheme.label.copyWith(
                              color:
                              attached ? color : AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                })
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 20),
          Divider(color: AppTheme.surfaceBorder),
          const SizedBox(height: 12),

          // Create new tag
          Text('Create new tag', style: AppTheme.label),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameCtrl,
                  style: AppTheme.body.copyWith(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Tag name',
                    hintStyle: AppTheme.caption,
                    filled: true,
                    fillColor: AppTheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _createTag,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _colors
                .map((c) {
              final color = Color(
                  int.parse(c.replaceFirst('#', 'FF'), radix: 16));
              final selected = _selectedColor == c;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: selected
                        ? Border.all(
                        color: Colors.white, width: 2.5)
                        : null,
                  ),
                  child: selected
                      ? const Icon(Icons.check,
                      color: Colors.white, size: 14)
                      : null,
                ),
              );
            })
                .toList(),
          ),
        ],
      ),
    );
  }

  void _createTag() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    await ref.read(tagNotifierProvider.notifier).createTag(
      name: name,
      color: _selectedColor,
    );
    await ref.read(tagNotifierProvider.notifier).addTagToTask(
      taskId: widget.taskId,
      tagId: '', // notifier creates and returns id — adapt if needed
    );
    _nameCtrl.clear();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pomodoro progress bar
// ─────────────────────────────────────────────────────────────────────────────

class _StepsSection extends ConsumerStatefulWidget {
  final String taskId;
  final List<TaskStep> steps;

  const _StepsSection({required this.taskId, required this.steps});

  @override
  ConsumerState<_StepsSection> createState() => _StepsSectionState();
}

class _StepsSectionState extends ConsumerState<_StepsSection> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...widget.steps.map((step) => _StepRow(
          step: step,
          onToggle: () => ref
              .read(tasksNotifierProvider.notifier)
              .toggleStep(step),
          onDelete: () => ref
              .read(tasksNotifierProvider.notifier)
              .deleteStep(step.id), // FIX: was `step as String` — always threw TypeError
        )),
        const SizedBox(height: 8),
        // Add step
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                style: AppTheme.body.copyWith(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Add a sub-task…',
                  hintStyle: AppTheme.caption,
                  filled: true,
                  fillColor: AppTheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onSubmitted: (_) => _addStep(),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _addStep,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(31),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppTheme.primary.withAlpha(76)),
                ),
                child: Icon(Icons.add,
                    color: AppTheme.primary, size: 20),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _addStep() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    await ref
        .read(tasksNotifierProvider.notifier)
        .insertStep(taskId: widget.taskId, title: text);
    _ctrl.clear();
  }
}

class _StepRow extends StatelessWidget {
  final TaskStep step;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _StepRow({
    required this.step,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: step.isCompleted
                    ? AppTheme.primary
                    : Colors.transparent,
                border: Border.all(
                  color: step.isCompleted
                      ? AppTheme.primary
                      : AppTheme.textDisabled,
                  width: 1.5,
                ),
              ),
              child: step.isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 13)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              step.title,
              style: AppTheme.body.copyWith(
                fontSize: 14,
                decoration: step.isCompleted
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
                color: step.isCompleted
                    ? AppTheme.textSecondary
                    : AppTheme.textPrimary,
              ),
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child:  Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close,
                  color: AppTheme.textDisabled, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Edit sheet
// ─────────────────────────────────────────────────────────────────────────────

class _EditSheet extends ConsumerStatefulWidget {
  final Task task;
  const _EditSheet({required this.task});

  @override
  ConsumerState<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends ConsumerState<_EditSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late int _priority;
  late int _coins;
  late int _pomodoros;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.task.title);
    _descCtrl = TextEditingController(
        text: widget.task.description ?? '');
    _priority = widget.task.priority ?? 4;
    _coins = widget.task.price.toInt();
    _pomodoros = widget.task.estimatedPomodoro.clamp(1, 20);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
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
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Edit Task', style: AppTheme.heading),
            const SizedBox(height: 16),
            TextField(
              controller: _titleCtrl,
              style: AppTheme.body,
              decoration: _deco('Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              style: AppTheme.body.copyWith(fontSize: 14),
              maxLines: 3,
              decoration: _deco('Notes (optional)'),
            ),
            const SizedBox(height: 20),
            Text('Priority', style: AppTheme.label),
            const SizedBox(height: 10),
            Row(
              children: [1, 2, 3, 4].map((p) {
                final labels = {1: 'High', 2: 'Medium', 3: 'Low', 4: 'None'};
                final colors = {
                  1: AppTheme.error,
                  2: AppTheme.warning,
                  3: AppTheme.primary,
                  4: AppTheme.textDisabled,
                };
                final selected = _priority == p;
                final color = colors[p]!;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _priority = p),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? color.withAlpha(38)
                            : AppTheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected ? color : AppTheme.surfaceBorder,
                        ),
                      ),
                      child: Text(
                        labels[p]!,
                        style: AppTheme.label.copyWith(
                          color:
                          selected ? color : AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _Stepper(
                      label: 'Coins',
                      value: _coins,
                      step: 5,
                      min: 0,
                      max: 100,
                      onChanged: (v) => setState(() => _coins = v)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _Stepper(
                      label: 'Pomodoros',
                      value: _pomodoros,
                      step: 1,
                      min: 1,
                      max: 20,
                      onChanged: (v) => setState(() => _pomodoros = v)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _delete,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppTheme.error.withAlpha(76)),
                      ),
                      child: Text(
                        'Delete',
                        style: AppTheme.label.copyWith(
                            color: AppTheme.error,
                            fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: _save,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Save Changes',
                        style: AppTheme.label.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    final companion = widget.task.toCompanion(true).copyWith(
      title: Value(title),
      description: Value(_descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim()),
      priority: Value(_priority),
      price: Value(_coins.toDouble()),
      estimatedPomodoro: Value(_pomodoros),
    );
    await ref.read(tasksNotifierProvider.notifier).updateTask(companion);
    if (mounted) Navigator.pop(context);
  }

  void _delete() async {
    await ref.read(tasksNotifierProvider.notifier).deleteTask(widget.task.id);
    if (mounted) {
      Navigator.pop(context); // close sheet
      context.pop(); // go back from detail screen
    }
  }

  InputDecoration _deco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: AppTheme.caption,
    filled: true,
    fillColor: AppTheme.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Success overlay
// ─────────────────────────────────────────────────────────────────────────────

class _SuccessOverlay extends StatelessWidget {
  final Task? task;
  final Animation<double> scaleAnim;
  final Animation<double> opacityAnim;

  const _SuccessOverlay({
    required this.task,
    required this.scaleAnim,
    required this.opacityAnim,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.background.withAlpha(235),
      child: Center(
        child: FadeTransition(
          opacity: opacityAnim,
          child: ScaleTransition(
            scale: scaleAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.success.withAlpha(38),
                    shape: BoxShape.circle,
                  ),
                  child:  Icon(
                    Icons.check,
                    color: AppTheme.success,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Done. That one counted.',
                  style: AppTheme.heading.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 8),
                if ((task?.price ?? 0) > 0)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                       Icon(Icons.monetization_on,
                          color: AppTheme.coral, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '+${task!.price.toInt()} coins earned',
                        style: AppTheme.body.copyWith(
                          color: AppTheme.coral,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Complete button
// ─────────────────────────────────────────────────────────────────────────────

class _CompleteButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CompleteButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withAlpha(89),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            'Mark as Done',
            style: AppTheme.label.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Micro widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTheme.label.copyWith(
        fontSize: 11,
        letterSpacing: 0.8,
        color: AppTheme.textSecondary,
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTheme.label.copyWith(color: color, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppTheme.textSecondary, size: 18),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stepper widget (shared between create and edit sheets)
// ─────────────────────────────────────────────────────────────────────────────

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