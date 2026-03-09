// lib/features/tasks/screens/task_detail_screen.dart

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
      vsync   : this,
      duration: const Duration(milliseconds: 600),
    );
    _successScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _successCtrl, curve: Curves.elasticOut),
    );
    _successOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _successCtrl, curve: const Interval(0.0, 0.4)),
    );
  }

  @override
  void dispose() {
    _successCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskAsync  = ref.watch(_taskByIdProvider(widget.taskId));
    final stepsAsync = ref.watch(stepsStreamProvider(widget.taskId));
    final tagsAsync  = ref.watch(tagsForTaskProvider(widget.taskId));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            taskAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error  : (e, _) => Center(child: Text('Error: $e')),
              data   : (task) {
                if (task == null) {
                  return Center(
                    child: Text('Task not found', style: AppTheme.body),
                  );
                }
                return _TaskBody(
                  task      : task,
                  stepsAsync: stepsAsync,
                  tagsAsync : tagsAsync,
                  onComplete: () => _complete(task),
                );
              },
            ),
            if (_showSuccess) _SuccessOverlay(
              scale  : _successScale,
              opacity: _successOpacity,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _complete(Task task) async {
    if (task.isCompleted) return;
    HapticFeedback.heavyImpact();
    await ref.read(tasksNotifierProvider.notifier).completeTask(task.id);
    setState(() => _showSuccess = true);
    _successCtrl.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 1800));
    if (mounted) {
      _successCtrl.reverse().then((_) {
        if (mounted) {
          setState(() => _showSuccess = false);
          context.pop();
        }
      });
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TaskBody
// ─────────────────────────────────────────────────────────────────────────────

class _TaskBody extends ConsumerWidget {
  final Task task;
  final AsyncValue<List<TaskStep>> stepsAsync;
  final AsyncValue<List<Tag>>      tagsAsync;
  final VoidCallback               onComplete;

  const _TaskBody({
    required this.task,
    required this.stepsAsync,
    required this.tagsAsync,
    required this.onComplete,
  });

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

  String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  Color _deadlineColor(DateTime d) {
    final diff = d.difference(DateTime.now()).inDays;
    if (diff < 0) return AppTheme.error;
    if (diff == 0) return AppTheme.warning;
    return AppTheme.textSecondary;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      slivers: [
        // ── Header ──────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
            child: Row(
              children: [
                _CircleIconBtn(
                  icon : Icons.arrow_back,
                  onTap: () => context.pop(),
                ),
                const Spacer(),
                _CircleIconBtn(
                  icon : Icons.edit_outlined,
                  onTap: () => _showEditSheet(context, ref),
                ),
              ],
            ),
          ),
        ),

        // ── Title + meta ─────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title, style: AppTheme.heading.copyWith(fontSize: 22)),
                const SizedBox(height: 8),
                if (task.description != null && task.description!.isNotEmpty) ...[
                  Text(
                    task.description!,
                    style: AppTheme.body.copyWith(
                      color : AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                // Meta chips
                Wrap(
                  spacing   : 8,
                  runSpacing: 8,
                  children  : [
                    _MetaChip(
                      label: _priorityLabel(task.priority),
                      color: _priorityColor(task.priority),
                    ),
                    _MetaChip(
                      label: '${task.price.toInt()} coins',
                      color: const Color(0xFFEAB308),
                    ),
                    _MetaChip(
                      label: '${task.estimatedPomodoro ?? 1} pomodoros',
                      color: AppTheme.primary,
                    ),
                    if (task.deadline != null)
                      _MetaChip(
                        label: _fmtDate(task.deadline!),
                        color: _deadlineColor(task.deadline!),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 20)),

        // ── Focus button ─────────────────────────────────────
        if (!task.isCompleted)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _FocusButton(
                // ── BUG FIX ───────────────────────────────────────────────
                // Was: context.push('/pomodoro', extra: task.id)
                // The router reads initialTaskId from queryParameters, not
                // from GoRouter's 'extra' field. Using 'extra' meant the
                // Pomodoro screen always opened with initialTaskId == null,
                // silently detaching the session from the task.
                // Fix: use query parameters, consistent with all_tasks_screen
                // and task_list_screen which both do this correctly.
                // ─────────────────────────────────────────────────────────
                onTap: () => context.push('/pomodoro?taskId=${task.id}'),
              ),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 20)),

        // ── Tags ─────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _TagsSection(
              taskId   : task.id,
              tagsAsync: tagsAsync,
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 20)),

        // ── Steps ────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: stepsAsync.when(
              loading: () => const SizedBox(height: 40),
              error  : (_, __) => const SizedBox.shrink(),
              data   : (steps) => _StepsSection(
                taskId: task.id,
                steps : steps,
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 20)),

        // ── Complete button ──────────────────────────────────
        if (!task.isCompleted)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: _CompleteButton(onTap: onComplete),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context          : context,
      isScrollControlled: true,
      backgroundColor  : AppTheme.elevated,
      shape            : const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EditSheet(task: task),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tags section
// ─────────────────────────────────────────────────────────────────────────────

class _TagsSection extends ConsumerWidget {
  final String                taskId;
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
                  color     : AppTheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        tagsAsync.when(
          loading: () => const SizedBox(height: 32),
          error  : (_, __) => const SizedBox.shrink(),
          data   : (tags) => tags.isEmpty
              ? Text('No tags yet', style: AppTheme.caption)
              : Wrap(
            spacing   : 8,
            runSpacing: 8,
            children  : tags
                .map((tag) => _TagChip(
              tag     : tag,
              onRemove: () => ref
                  .read(tagNotifierProvider.notifier)
                  .removeTagFromTask(
                taskId: taskId,
                tagId : tag.id,
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
      context           : context,
      isScrollControlled: true,
      backgroundColor   : AppTheme.elevated,
      shape             : const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ProviderScope(
        parent: ProviderScope.containerOf(context),
        child : _TagPickerSheet(taskId: taskId),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final Tag          tag;
  final VoidCallback onRemove;

  const _TagChip({required this.tag, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse(tag.color.replaceFirst('#', 'FF'), radix: 16));
    return Container(
      padding   : const EdgeInsets.fromLTRB(10, 5, 6, 5),
      decoration: BoxDecoration(
        color        : color.withAlpha(31),
        borderRadius : BorderRadius.circular(8),
        border       : Border.all(color: color.withAlpha(76)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(tag.name, style: AppTheme.label.copyWith(color: color, fontSize: 12)),
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

// ─────────────────────────────────────────────────────────────────────────────
// Tag picker sheet
// ─────────────────────────────────────────────────────────────────────────────

class _TagPickerSheet extends ConsumerStatefulWidget {
  final String taskId;
  const _TagPickerSheet({required this.taskId});

  @override
  ConsumerState<_TagPickerSheet> createState() => _TagPickerSheetState();
}

class _TagPickerSheetState extends ConsumerState<_TagPickerSheet> {
  final _nameCtrl      = TextEditingController();
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
    final allTagsAsync  = ref.watch(allTagsProvider);
    final taskTagsAsync = ref.watch(tagsForTaskProvider(widget.taskId));

    return Padding(
      padding: EdgeInsets.only(
        left  : 20,
        right : 20,
        top   : 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize       : MainAxisSize.min,
        crossAxisAlignment : CrossAxisAlignment.start,
        children           : [
          Center(
            child: Container(
              width : 40,
              height: 4,
              decoration: BoxDecoration(
                color        : AppTheme.surfaceBorder,
                borderRadius : BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Manage Tags', style: AppTheme.heading),
          const SizedBox(height: 16),

          // Existing tags
          allTagsAsync.when(
            loading: () => const SizedBox(height: 40),
            error  : (_, __) => const SizedBox.shrink(),
            data   : (allTags) {
              final taskTags   = taskTagsAsync.value ?? [];
              final taskTagIds = taskTags.map((t) => t.id).toSet();

              return Wrap(
                spacing   : 8,
                runSpacing: 8,
                children  : allTags.map((tag) {
                  final attached = taskTagIds.contains(tag.id);
                  final color    = Color(int.parse(
                      tag.color.replaceFirst('#', 'FF'), radix: 16));
                  return GestureDetector(
                    onTap: () {
                      if (attached) {
                        ref.read(tagNotifierProvider.notifier).removeTagFromTask(
                          taskId: widget.taskId,
                          tagId : tag.id,
                        );
                      } else {
                        ref.read(tagNotifierProvider.notifier).addTagToTask(
                          taskId: widget.taskId,
                          tagId : tag.id,
                        );
                      }
                    },
                    child: AnimatedContainer(
                      duration  : const Duration(milliseconds: 200),
                      padding   : const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color        : attached ? color.withAlpha(51) : AppTheme.surface,
                        borderRadius : BorderRadius.circular(8),
                        border       : Border.all(
                          color: attached ? color : AppTheme.surfaceBorder,
                        ),
                      ),
                      child: Text(
                        tag.name,
                        style: AppTheme.caption.copyWith(
                          color     : attached ? color : AppTheme.textSecondary,
                          fontSize  : 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
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
                  style     : AppTheme.body.copyWith(fontSize: 14),
                  decoration: InputDecoration(
                    hintText        : 'Tag name',
                    hintStyle       : AppTheme.caption,
                    filled          : true,
                    fillColor       : AppTheme.surface,
                    border          : OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide  : BorderSide.none,
                    ),
                    contentPadding  : const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _createTag,
                child: Container(
                  width     : 44,
                  height    : 44,
                  decoration: BoxDecoration(
                    color       : AppTheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Color swatches
          Wrap(
            spacing   : 8,
            runSpacing: 8,
            children  : _colors.map((c) {
              final color    = Color(int.parse(c.replaceFirst('#', 'FF'), radix: 16));
              final selected = _selectedColor == c;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = c),
                child: AnimatedContainer(
                  duration  : const Duration(milliseconds: 150),
                  width     : 28,
                  height    : 28,
                  decoration: BoxDecoration(
                    color : color,
                    shape : BoxShape.circle,
                    border: selected
                        ? Border.all(color: Colors.white, width: 2.5)
                        : null,
                  ),
                  child: selected
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _createTag() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    final tagId = await ref.read(tagNotifierProvider.notifier).createTag(
      name : name,
      color: _selectedColor,
    );

    await ref.read(tagNotifierProvider.notifier).addTagToTask(
      taskId: widget.taskId,
      tagId : tagId,
    );

    _nameCtrl.clear();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Steps section
// ─────────────────────────────────────────────────────────────────────────────

class _StepsSection extends ConsumerStatefulWidget {
  final String        taskId;
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('Sub-tasks'),
        const SizedBox(height: 10),
        ...widget.steps.map((step) => _StepRow(
          step    : step,
          onToggle: () => ref.read(tasksNotifierProvider.notifier).toggleStep(step),
          onDelete: () => ref.read(tasksNotifierProvider.notifier).deleteStep(step.id),
        )),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                style     : AppTheme.body.copyWith(fontSize: 14),
                decoration: InputDecoration(
                  hintText      : 'Add a sub-task…',
                  hintStyle     : AppTheme.caption,
                  filled        : true,
                  fillColor     : AppTheme.surface,
                  border        : OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide  : BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
                onSubmitted: (_) => _addStep(),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _addStep,
              child: Container(
                width     : 44,
                height    : 44,
                decoration: BoxDecoration(
                  color       : AppTheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _addStep() {
    final title = _ctrl.text.trim();
    if (title.isEmpty) return;
    ref.read(tasksNotifierProvider.notifier).insertStep(
      taskId: widget.taskId,
      title : title,
    );
    _ctrl.clear();
  }
}

class _StepRow extends StatelessWidget {
  final TaskStep     step;
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration  : const Duration(milliseconds: 200),
              width     : 22,
              height    : 22,
              decoration: BoxDecoration(
                color       : step.isCompleted
                    ? AppTheme.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border      : Border.all(
                  color: step.isCompleted
                      ? AppTheme.primary
                      : AppTheme.surfaceBorder,
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
                fontSize  : 14,
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
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.close, color: AppTheme.textDisabled, size: 16),
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
    _descCtrl  = TextEditingController(text: widget.task.description ?? '');
    _priority  = widget.task.priority ?? 3;
    _coins     = widget.task.price.toInt();
    _pomodoros = widget.task.estimatedPomodoro ?? 1;
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
      padding: EdgeInsets.fromLTRB(
        20, 20, 20,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize      : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width : 40,
              height: 4,
              decoration: BoxDecoration(
                color       : AppTheme.surfaceBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Edit Task', style: AppTheme.heading.copyWith(fontSize: 20)),
          const SizedBox(height: 16),
          TextField(
            controller: _titleCtrl,
            style     : AppTheme.body,
            decoration: InputDecoration(
              hintText      : 'Task title',
              hintStyle     : AppTheme.caption,
              filled        : true,
              fillColor     : AppTheme.surface,
              border        : OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide  : BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            style     : AppTheme.body.copyWith(fontSize: 14),
            maxLines  : 3,
            decoration: InputDecoration(
              hintText      : 'Description (optional)',
              hintStyle     : AppTheme.caption,
              filled        : true,
              fillColor     : AppTheme.surface,
              border        : OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide  : BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              style    : ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding        : const EdgeInsets.symmetric(vertical: 16),
                elevation      : 0,
                shape          : RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Save changes',
                style: AppTheme.label.copyWith(
                  color     : Colors.white,
                  fontSize  : 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;

    final companion = widget.task.copyWith(
      title             : title,
      description       : Value(_descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim()),
      priority          : Value(_priority),
      price             : _coins.toDouble(),
      estimatedPomodoro : _pomodoros,
    ).toCompanion(true);

    await ref.read(tasksNotifierProvider.notifier).updateTask(companion);
    if (mounted) Navigator.pop(context);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small shared widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTheme.label.copyWith(
        color    : AppTheme.textSecondary,
        fontSize : 12,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final Color  color;

  const _MetaChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding   : const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color       : color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border      : Border.all(color: color.withAlpha(76)),
      ),
      child: Text(
        label,
        style: AppTheme.caption.copyWith(color: color, fontSize: 12),
      ),
    );
  }
}

class _CircleIconBtn extends StatelessWidget {
  final IconData     icon;
  final VoidCallback onTap;

  const _CircleIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width     : 40,
        height    : 40,
        decoration: BoxDecoration(
          color : AppTheme.surface,
          shape : BoxShape.circle,
          border: Border.all(color: AppTheme.surfaceBorder),
        ),
        child: Icon(icon, color: AppTheme.textSecondary, size: 20),
      ),
    );
  }
}

class _FocusButton extends StatelessWidget {
  final VoidCallback onTap;
  const _FocusButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width     : double.infinity,
        padding   : const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color       : AppTheme.primary.withAlpha(31),
          borderRadius: BorderRadius.circular(14),
          border      : Border.all(color: AppTheme.primary.withAlpha(102)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timer_outlined, color: AppTheme.primary, size: 20),
            const SizedBox(width: 10),
            Text(
              'Start Focus Session',
              style: AppTheme.label.copyWith(
                color     : AppTheme.primary,
                fontSize  : 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompleteButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CompleteButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width     : double.infinity,
        padding   : const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color       : AppTheme.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(
              'Mark Complete',
              style: AppTheme.label.copyWith(
                color     : Colors.white,
                fontSize  : 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessOverlay extends StatelessWidget {
  final Animation<double> scale;
  final Animation<double> opacity;

  const _SuccessOverlay({required this.scale, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: opacity,
      child: Container(
        color: AppTheme.background.withAlpha(200),
        child: Center(
          child: ScaleTransition(
            scale: scale,
            child: Container(
              padding   : const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color       : AppTheme.surface,
                borderRadius: BorderRadius.circular(24),
                border      : Border.all(color: AppTheme.surfaceBorder),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children    : [
                  Icon(Icons.check_circle_rounded,
                      color: AppTheme.primary, size: 56),
                  const SizedBox(height: 16),
                  Text('Task Complete!', style: AppTheme.heading),
                  const SizedBox(height: 8),
                  Text(
                    'Coins have been added to your balance.',
                    style: AppTheme.caption,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}