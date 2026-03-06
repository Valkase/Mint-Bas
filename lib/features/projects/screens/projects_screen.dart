import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/database/app_database.dart';
import '../../../features/settings/widgets/settings_sheet.dart';
import '../../projects/providers/projects_notifier.dart';
import '../../tasks/providers/tasks_notifier.dart';

// ── Real project progress (completed tasks / total tasks) ─────────────────────
// FIX: Provider (not FutureProvider) that ref.watches existing reactive stream
// providers. Recomputes automatically whenever any list or task changes in the
// DB — no manual invalidation, updates while the screen is open.

final _projectProgressProvider =
Provider.autoDispose.family<double, String>((ref, projectId) {
  final listsAsync = ref.watch(listsStreamProvider(projectId));
  final lists      = listsAsync.value ?? [];

  if (lists.isEmpty) return 0.0;

  int total = 0, done = 0;
  for (final list in lists) {
    final tasksAsync = ref.watch(tasksStreamProvider(list.id));
    final tasks      = tasksAsync.value ?? [];
    total += tasks.length;
    done  += tasks.where((t) => t.isCompleted).length;
  }
  return total == 0 ? 0.0 : done / total;
});

// ── Screen ────────────────────────────────────────────────────────────────────

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeProvider); // rebuild instantly on theme change
    final projectsAsync = ref.watch(projectsStreamProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                // ── Header ────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 40, 20, 8),
                    child: Row(
                      children: [
                        // FIX: Expanded prevents header overflow on any screen size
                        Expanded(
                          child: GestureDetector(
                            onLongPress: () {
                              HapticFeedback.heavyImpact();
                              context.push('/debug');
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Your Projects', style: AppTheme.heading),
                                const SizedBox(height: 4),
                                Text(
                                  'Focus on grounded growth, one step at a time.',
                                  style: AppTheme.caption,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // FIX: Dead search icon → working settings button
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            showSettingsSheet(context);
                          },
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              shape: BoxShape.circle,
                              border:
                              Border.all(color: AppTheme.surfaceBorder),
                            ),
                            child: Icon(
                              Icons.tune_rounded,
                              color: AppTheme.textSecondary,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Project List ──────────────────────────────
                projectsAsync.when(
                  loading: () => SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 80),
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
                        'Something went wrong.',
                        style: AppTheme.body.copyWith(color: AppTheme.error),
                      ),
                    ),
                  ),
                  data: (projects) => SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 160),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          if (index == projects.length) {
                            return _EncouragementTile();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ProjectCard(project: projects[index]),
                          );
                        },
                        childCount: projects.length + 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ── FAB ──────────────────────────────────────────
            Positioned(
              right: 20,
              bottom: 24,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _showCreateSheet(context, ref);
                },
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withAlpha(100),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child:
                  const Icon(Icons.add, color: Colors.white, size: 28),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.elevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _CreateProjectSheet(ref: ref),
    );
  }
}

// ── Project Card ──────────────────────────────────────────────────────────────

class _ProjectCard extends ConsumerWidget {
  final Project project;
  const _ProjectCard({required this.project});

  Color get _accentColor {
    try {
      return Color(int.parse(project.color.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // FIX: plain Provider — no .value needed, always synchronous
    final progress = ref.watch(_projectProgressProvider(project.id));

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/project/${project.id}');
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.surfaceBorder),
        ),
        clipBehavior: Clip.hardEdge,
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 4, color: _accentColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 16, 16, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              project.name,
                              style: AppTheme.body.copyWith(
                                fontWeight: FontWeight.w600,
                                // FIX: AppTheme.textPrimary — visible in both modes
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (project.description != null &&
                                project.description!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                project.description!,
                                style: AppTheme.caption,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.task_alt,
                                    size: 14,
                                    color: AppTheme.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  progress > 0
                                      ? '${(progress * 100).toInt()}% complete'
                                      : 'Tap to view tasks',
                                  style:
                                  AppTheme.caption.copyWith(fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _MiniRing(progress: progress, color: _accentColor),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Mini Progress Ring ────────────────────────────────────────────────────────

class _MiniRing extends StatelessWidget {
  final double progress;
  final Color color;
  const _MiniRing({required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(44, 44),
            painter: _MiniRingPainter(progress: progress, color: color),
          ),
          Text(
            '${(progress * 100).toInt()}%',
            style: AppTheme.caption.copyWith(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              // FIX: AppTheme.textPrimary — visible in light mode
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  _MiniRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // FIX: AppTheme.surfaceBorder for the track — not hardcoded Colors.white
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppTheme.surfaceBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -1.5708,
        2 * 3.14159 * progress,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_MiniRingPainter old) =>
      old.progress != progress || old.color != color;
}

// ── Encouragement Tile ────────────────────────────────────────────────────────

class _EncouragementTile extends StatelessWidget {
  _EncouragementTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        // FIX: AppTheme tokens — not hardcoded Colors.white.withOpacity
        color: AppTheme.elevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(38),
              shape: BoxShape.circle,
            ),
            child:
            Icon(Icons.spa_outlined, color: AppTheme.primary, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            "You're doing great.",
            style: AppTheme.body.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Text(
            'Progress is not linear.\nTake a deep breath.',
            style: AppTheme.caption.copyWith(height: 1.6),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Create Project Sheet ──────────────────────────────────────────────────────

class _CreateProjectSheet extends StatefulWidget {
  final WidgetRef ref;
  const _CreateProjectSheet({required this.ref});

  @override
  State<_CreateProjectSheet> createState() => _CreateProjectSheetState();
}

class _CreateProjectSheetState extends State<_CreateProjectSheet> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedColor = '#4A7C59';

  final List<Map<String, String>> _colors = [
    {'hex': '#4A7C59', 'label': 'Forest'},
    {'hex': '#D4785A', 'label': 'Coral'},
    {'hex': '#5A7A9E', 'label': 'Blue'},
    {'hex': '#9E7A5A', 'label': 'Tan'},
    {'hex': '#8a9a5b', 'label': 'Sage'},
    {'hex': '#bc6c25', 'label': 'Earth'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
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
          Text('New Project',
              style: AppTheme.heading.copyWith(fontSize: 20)),
          const SizedBox(height: 20),
          _buildField(_nameController, 'Project name', maxLines: 1),
          const SizedBox(height: 12),
          _buildField(_descController, 'Description (optional)',
              maxLines: 2),
          const SizedBox(height: 20),
          Text('Pick a color', style: AppTheme.label),
          const SizedBox(height: 12),
          Row(
            children: _colors.map((c) {
              final isSelected = c['hex'] == _selectedColor;
              final color =
              Color(int.parse(c['hex']!.replaceFirst('#', '0xFF')));
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = c['hex']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 10),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                    // FIX: AppTheme.textPrimary — visible in both modes
                        ? Border.all(
                        color: AppTheme.textPrimary, width: 2.5)
                        : Border.all(
                        color: Colors.transparent, width: 2.5),
                    boxShadow: isSelected
                        ? [
                      BoxShadow(
                          color: color.withAlpha(120),
                          blurRadius: 8)
                    ]
                        : null,
                  ),
                  child: isSelected
                      ? Icon(Icons.check_rounded,
                      color: Colors.white.withAlpha(220), size: 16)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
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
                'Create Project',
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

  Widget _buildField(
      TextEditingController controller,
      String hint, {
        int maxLines = 1,
      }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: AppTheme.body,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTheme.body.copyWith(color: AppTheme.textDisabled),
        filled: true,
        fillColor: AppTheme.surface,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.surfaceBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.surfaceBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primary),
        ),
      ),
    );
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    HapticFeedback.mediumImpact();
    await widget.ref.read(projectsNotifierProvider.notifier).createProject(
      name: name,
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
      color: _selectedColor,
    );
    if (mounted) Navigator.pop(context);
  }
}