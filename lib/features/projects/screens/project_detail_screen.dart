import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/database/app_database.dart';
import '../../projects/providers/projects_notifier.dart';
import '../../tasks/providers/tasks_notifier.dart';
import '../../tasks/providers/tag_providers.dart';

class ProjectDetailScreen extends ConsumerWidget {
  final String projectId;
  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsStreamProvider);
    final listsAsync = ref.watch(listsStreamProvider(projectId));

    final project = projectsAsync.value?.firstWhere(
          (p) => p.id == projectId,
      orElse: () => throw Exception('Project not found'),
    );

    final accentColor = _parseColor(project?.color ?? '#4A7C59');

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                // ── Header ──────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: _ProjectHeader(
                    project: project,
                    accentColor: accentColor,
                    onBack: () => context.pop(),
                    onDelete: () => _confirmDelete(context, ref),
                  ),
                ),

                // ── Lists ────────────────────────────────────────────────────
                listsAsync.when(
                  loading: () => SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),
                  error: (e, _) => SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Could not load lists.',
                        style: AppTheme.body.copyWith(color: AppTheme.error),
                      ),
                    ),
                  ),
                  data: (lists) {
                    if (lists.isEmpty) {
                      return SliverToBoxAdapter(
                        child: _EmptyListsState(
                          onCreateList: () => _showCreateListSheet(context, ref),
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 160),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                              (context, index) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ListCard(
                              taskList: lists[index],
                              accentColor: accentColor,
                            ),
                          ),
                          childCount: lists.length,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),

            // ── FAB ────────────────────────────────────────────────────────
            Positioned(
              right: 20,
              bottom: 24,
              child: GestureDetector(
                onTap: () => _showCreateListSheet(context, ref),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withAlpha(100),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 28),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppTheme.primary;
    }
  }

  void _showCreateListSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.elevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _CreateListSheet(projectId: projectId, ref: ref),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.elevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Project?',
          style: AppTheme.body.copyWith(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'This will permanently delete the project and all its lists.',
          style: AppTheme.caption.copyWith(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: AppTheme.label),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: AppTheme.label.copyWith(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await ref.read(projectsNotifierProvider.notifier).deleteProject(projectId);
      if (context.mounted) context.pop();
    }
  }
}

// ── Project Header ─────────────────────────────────────────────────────────

class _ProjectHeader extends StatelessWidget {
  final Project? project;
  final Color accentColor;
  final VoidCallback onBack;
  final VoidCallback onDelete;

  const _ProjectHeader({
    required this.project,
    required this.accentColor,
    required this.onBack,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          bottom: BorderSide(color: AppTheme.surfaceBorder),
          left: BorderSide(color: accentColor, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: onBack,
                child: Row(
                  children: [
                    Icon(
                      Icons.arrow_back_ios,
                      color: AppTheme.textSecondary,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text('Projects', style: AppTheme.caption),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon:  Icon(
                  Icons.delete_outline,
                  color: AppTheme.textSecondary,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(project?.name ?? '', style: AppTheme.heading),
          if (project?.description != null &&
              project!.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              project!.description!,
              style: AppTheme.caption.copyWith(height: 1.5),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 3,
                height: 12,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'TASK LISTS',
                style: AppTheme.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── List Card ─────────────────────────────────────────────────────────────

class _ListCard extends ConsumerWidget {
  final TaskList taskList;
  final Color accentColor;

  const _ListCard({
    required this.taskList,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksStreamProvider(taskList.id));

    return GestureDetector(
      onTap: () => context.push('/list/${taskList.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.surfaceBorder),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // List name + chevron
            Row(
              children: [
                Expanded(
                  child: Text(
                    taskList.name,
                    style:
                    AppTheme.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                 Icon(
                  Icons.chevron_right,
                  color: AppTheme.textSecondary,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Mini dashboard with real data
            tasksAsync.when(
              loading: () => ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child:  LinearProgressIndicator(
                  backgroundColor: AppTheme.surfaceBorder,
                  color: AppTheme.primary,
                  minHeight: 5,
                ),
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (tasks) {
                final total = tasks.length;
                final completed =
                    tasks.where((t) => t.isCompleted).length;
                final progress =
                total == 0 ? 0.0 : completed / total;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats row
                    Row(
                      children: [
                        _MiniStat(
                          icon: Icons.check_circle_outline,
                          label: '$completed/$total tasks',
                          color: AppTheme.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // ── FIX: Progress bar now driven by real progress ──
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: progress),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOut,
                      builder: (context, value, _) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: value,
                                backgroundColor:
                                accentColor.withAlpha(38),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    accentColor),
                                minHeight: 5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              total == 0
                                  ? 'No tasks yet'
                                  : '${(value * 100).toInt()}% complete',
                              style:
                              AppTheme.caption.copyWith(fontSize: 11),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(label, style: AppTheme.caption.copyWith(fontSize: 11)),
      ],
    );
  }
}

// ── Empty Lists State ─────────────────────────────────────────────────────

class _EmptyListsState extends StatelessWidget {
  final VoidCallback onCreateList;
  const _EmptyListsState({required this.onCreateList});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child:  Icon(
              Icons.list_alt_outlined,
              color: AppTheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Nothing here yet —',
            style: AppTheme.body.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            'what needs doing today?',
            style: AppTheme.caption.copyWith(height: 1.6),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onCreateList,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(38),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primary.withAlpha(76)),
              ),
              child: Text(
                'Create a list',
                style: AppTheme.label.copyWith(color: AppTheme.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Create List Sheet ─────────────────────────────────────────────────────

class _CreateListSheet extends StatefulWidget {
  final String projectId;
  final WidgetRef ref;
  const _CreateListSheet({required this.projectId, required this.ref});

  @override
  State<_CreateListSheet> createState() => _CreateListSheetState();
}

class _CreateListSheetState extends State<_CreateListSheet> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
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
          Text('New List', style: AppTheme.heading.copyWith(fontSize: 20)),
          const SizedBox(height: 8),
          Text(
            'Add a focused list to this project.',
            style: AppTheme.caption,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            autofocus: true,
            style: AppTheme.body,
            decoration: InputDecoration(
              hintText: 'List name',
              hintStyle:
              AppTheme.body.copyWith(color: AppTheme.textDisabled),
              filled: true,
              fillColor: AppTheme.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:  BorderSide(color: AppTheme.surfaceBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:  BorderSide(color: AppTheme.surfaceBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:  BorderSide(color: AppTheme.primary),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _create,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Create List',
                style: AppTheme.label.copyWith(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    await widget.ref.read(projectsNotifierProvider.notifier).createList(
      name: name,
      projectId: widget.projectId,
    );
    if (mounted) Navigator.pop(context);
  }
}