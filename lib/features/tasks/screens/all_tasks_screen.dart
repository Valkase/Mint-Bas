import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/flavor/app_strings.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/database/app_database.dart';
import '../../../features/settings/widgets/settings_sheet.dart';
import '../../projects/providers/projects_notifier.dart';
import '../providers/tasks_notifier.dart' hide allListsStreamProvider;

// Helpers
bool _isToday(DateTime? d) { if (d == null) return false; final n = DateTime.now(); return d.year==n.year&&d.month==n.month&&d.day==n.day; }
bool _isTomorrow(DateTime? d) { if (d == null) return false; final t = DateTime.now().add(const Duration(days:1)); return d.year==t.year&&d.month==t.month&&d.day==t.day; }
bool _isThisWeek(DateTime? d) { if (d == null) return false; final n=DateTime.now(); final s=DateTime(n.year,n.month,n.day+2); final e=DateTime(n.year,n.month,n.day+7,23,59,59); return d.isAfter(s.subtract(const Duration(seconds:1)))&&d.isBefore(e); }
bool _isPlanned(DateTime? d) { if (d == null) return false; return d.isAfter(DateTime.now().add(const Duration(days:7))); }
String _fmtDate(DateTime d) { const m=['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']; return '${d.day} ${m[d.month-1]}'; }
Color _deadlineColor(DateTime d) { final diff=d.difference(DateTime.now()).inDays; if(diff<0) return AppTheme.error; if(diff==0) return AppTheme.warning; if(diff<=2) return AppTheme.coral; return AppTheme.textSecondary; }
Color _priorityColor(int? p) => switch(p){1=>AppTheme.error,2=>AppTheme.warning,3=>AppTheme.primary,_=>AppTheme.surfaceBorder};
InputDecoration _inputDec(String h) => InputDecoration(hintText:h,hintStyle:AppTheme.body.copyWith(color:AppTheme.textDisabled,fontSize:14),filled:true,fillColor:AppTheme.surface,contentPadding:const EdgeInsets.symmetric(horizontal:16,vertical:14),border:OutlineInputBorder(borderRadius:BorderRadius.circular(12),borderSide: BorderSide(color:AppTheme.surfaceBorder)),enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(12),borderSide: BorderSide(color:AppTheme.surfaceBorder)),focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(12),borderSide: BorderSide(color:AppTheme.primary)));

// ── Screen ────────────────────────────────────────────────────────────────────

class AllTasksScreen extends ConsumerStatefulWidget {
  const AllTasksScreen({super.key});
  @override
  ConsumerState<AllTasksScreen> createState() => _AllTasksScreenState();
}

class _AllTasksScreenState extends ConsumerState<AllTasksScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  List<String> _buildTabs(AppStrings s) =>
      [s.tasksToday, 'Tomorrow', 'This Week', 'Planned', 'All'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this, initialIndex: 4);
    _tabCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeProvider);
    final s = AppStrings.of(ref);
    final tabs = _buildTabs(s);
    final tasksAsync    = ref.watch(allTasksStreamProvider);
    final listsAsync    = ref.watch(allListsStreamProvider);
    final projectsAsync = ref.watch(allProjectsStreamProvider);
    final listsMap    = Map<String, TaskList>.fromEntries((listsAsync.value ?? []).map((l) => MapEntry(l.id, l)));
    final projectsMap = Map<String, Project>.fromEntries((projectsAsync.value ?? []).map((p) => MapEntry(p.id, p)));

    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () { HapticFeedback.mediumImpact(); _showCreateSheet(context); },
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white, size: 24),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(s.tasksScreenTitle, style: AppTheme.heading),
                      const SizedBox(height: 2),
                      tasksAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (tasks) { final open = tasks.where((t) => !t.isCompleted).length; return Text('$open task${open==1?'':'s'} remaining', style: AppTheme.caption); },
                      ),
                    ]),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/projects'),
                    child: Container(width:36,height:36,margin:const EdgeInsets.only(right:8),
                        decoration:BoxDecoration(color:AppTheme.surface,shape:BoxShape.circle,border:Border.all(color:AppTheme.surfaceBorder)),
                        child: Icon(Icons.folder_outlined,color:AppTheme.textSecondary,size:16)),
                  ),
                  GestureDetector(
                    onTap: () { HapticFeedback.lightImpact(); showSettingsSheet(context); },
                    child: Container(width:36,height:36,
                        decoration:BoxDecoration(color:AppTheme.surface,shape:BoxShape.circle,border:Border.all(color:AppTheme.surfaceBorder)),
                        child: Icon(Icons.tune_rounded,color:AppTheme.textSecondary,size:16)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: tabs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => _TabChip(
                  label: tabs[i], selected: _tabCtrl.index == i,
                  onTap: () { HapticFeedback.selectionClick(); _tabCtrl.animateTo(i); },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: tasksAsync.when(
                loading: () =>  Center(child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2)),
                error: (e, _) => Center(child: Text('Error: $e', style: AppTheme.caption.copyWith(color: AppTheme.error))),
                data: (allTasks) => TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _TasksTabView(tasks: allTasks.where((t) => _isToday(t.deadline)).toList(), listsMap: listsMap, projectsMap: projectsMap, emptyMessage: 'Nothing due today.', emptySubMessage: 'Enjoy the breathing room.', strings: s),
                    _TasksTabView(tasks: allTasks.where((t) => _isTomorrow(t.deadline)).toList(), listsMap: listsMap, projectsMap: projectsMap, emptyMessage: 'Nothing due tomorrow.', emptySubMessage: 'Get ahead on something today.', strings: s),
                    _TasksTabView(tasks: allTasks.where((t) => _isThisWeek(t.deadline)).toList(), listsMap: listsMap, projectsMap: projectsMap, emptyMessage: 'Clear week ahead.', emptySubMessage: 'Add tasks with deadlines to plan.', strings: s),
                    _TasksTabView(tasks: allTasks.where((t) => _isPlanned(t.deadline)).toList(), listsMap: listsMap, projectsMap: projectsMap, emptyMessage: 'Nothing planned yet.', emptySubMessage: 'Long-horizon tasks will show here.', strings: s),
                    _TasksTabView(tasks: allTasks, listsMap: listsMap, projectsMap: projectsMap, emptyMessage: 'No tasks yet.', emptySubMessage: 'Tap + to add your first task.', strings: s),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: AppTheme.elevated,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _CreateTaskSheet(parentRef: ref),
    );
  }
}

// ── Tab Chip ──────────────────────────────────────────────────────────────────

class _TabChip extends StatelessWidget {
  final String label; final bool selected; final VoidCallback onTap;
  const _TabChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? AppTheme.primary : AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? AppTheme.primary : AppTheme.surfaceBorder),
      ),
      child: Text(label, style: AppTheme.label.copyWith(fontSize: 12,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: selected ? Colors.white : AppTheme.textSecondary)),
    ),
  );
}

// ── Tasks Tab View ────────────────────────────────────────────────────────────

class _TasksTabView extends StatefulWidget {
  final List<Task> tasks;
  final Map<String, TaskList> listsMap;
  final Map<String, Project> projectsMap;
  final String emptyMessage, emptySubMessage;
  final AppStrings strings;
  const _TasksTabView({required this.tasks, required this.listsMap, required this.projectsMap, required this.emptyMessage, required this.emptySubMessage, required this.strings});
  @override State<_TasksTabView> createState() => _TasksTabViewState();
}

class _TasksTabViewState extends State<_TasksTabView> {
  bool _completedExpanded = false;

  @override
  Widget build(BuildContext context) {
    final incomplete = widget.tasks.where((t) => !t.isCompleted).toList();
    final completed  = widget.tasks.where((t) => t.isCompleted).toList();
    if (widget.tasks.isEmpty) return _EmptyTab(message: widget.emptyMessage, subMessage: widget.emptySubMessage);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        if (incomplete.isEmpty)
          Padding(padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('All done here ✓', style: AppTheme.caption.copyWith(color: AppTheme.primary))))
        else
          ...incomplete.map((t) => _TaskRow(task: t, listsMap: widget.listsMap, projectsMap: widget.projectsMap)),
        if (completed.isNotEmpty) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _completedExpanded = !_completedExpanded); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.surfaceBorder)),
              child: Row(children: [
                AnimatedRotation(turns: _completedExpanded ? 0.25 : 0, duration: const Duration(milliseconds: 200),
                    child:  Icon(Icons.chevron_right, color: AppTheme.textSecondary, size: 18)),
                const SizedBox(width: 8),
                Text(widget.strings.tasksDone, style: AppTheme.label.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                const SizedBox(width: 6),
                Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(color: AppTheme.primary.withAlpha(30), borderRadius: BorderRadius.circular(10)),
                    child: Text('${completed.length}', style: AppTheme.caption.copyWith(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w600))),
              ]),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(height: 0),
            secondChild: Column(children: [
              const SizedBox(height: 4),
              ...completed.map((t) => Opacity(opacity: 0.5,
                  child: _TaskRow(task: t, listsMap: widget.listsMap, projectsMap: widget.projectsMap))),
            ]),
            crossFadeState: _completedExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ],
    );
  }
}

// ── Task Row ──────────────────────────────────────────────────────────────────

class _TaskRow extends ConsumerWidget {
  final Task task;
  final Map<String, TaskList> listsMap;
  final Map<String, Project> projectsMap;
  const _TaskRow({required this.task, required this.listsMap, required this.projectsMap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pColor  = _priorityColor(task.priority);
    final list    = listsMap[task.listId];
    final project = (list?.projectId != null) ? projectsMap[list!.projectId] : null;

    String? breadcrumb;
    if (project != null && list != null)     { breadcrumb = '${project.name}  ›  ${list.name}'; }
    else if (list != null && list.name != 'Inbox') { breadcrumb = list.name; }

    return GestureDetector(
      onTap: () => context.push('/task/${task.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppTheme.surface, borderRadius: BorderRadius.circular(14),
          border: Border(left: BorderSide(color: pColor, width: 3)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: GestureDetector(
                onTap: () { if (task.isCompleted) return; HapticFeedback.mediumImpact(); ref.read(tasksNotifierProvider.notifier).completeTask(task.id); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 20, height: 20,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      color: task.isCompleted ? AppTheme.primary : Colors.transparent,
                      border: Border.all(color: task.isCompleted ? AppTheme.primary : AppTheme.textDisabled, width: 1.5)),
                  child: task.isCompleted ? const Icon(Icons.check, color: Colors.white, size: 12) : null,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Breadcrumb
                if (breadcrumb != null) ...[
                  Row(children: [
                    Icon(Icons.folder_outlined, size: 10, color: AppTheme.textDisabled),
                    const SizedBox(width: 4),
                    Expanded(child: Text(breadcrumb, style: AppTheme.caption.copyWith(fontSize: 10, color: AppTheme.textDisabled), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ]),
                  const SizedBox(height: 3),
                ],
                // Title
                Text(task.title, style: AppTheme.body.copyWith(
                    fontSize: 14, fontWeight: FontWeight.w500,
                    decoration: task.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                    color: task.isCompleted ? AppTheme.textSecondary : AppTheme.textPrimary)),
                // Meta
                if (task.deadline != null || task.price > 0) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    if (task.deadline != null) ...[
                      Icon(Icons.calendar_today_outlined, size: 10, color: _deadlineColor(task.deadline!)),
                      const SizedBox(width: 3),
                      Text(_fmtDate(task.deadline!), style: AppTheme.caption.copyWith(fontSize: 10, color: _deadlineColor(task.deadline!))),
                      const SizedBox(width: 10),
                    ],
                    if (task.price > 0) ...[
                      const Icon(Icons.monetization_on_outlined, size: 10, color: Color(0xFFEAB308)),
                      const SizedBox(width: 3),
                      Text('${task.price.toInt()}', style: AppTheme.caption.copyWith(fontSize: 10, color: const Color(0xFFEAB308))),
                    ],
                  ]),
                ],
              ]),
            ),
            if (!task.isCompleted) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () { HapticFeedback.mediumImpact(); context.push('/pomodoro?taskId=${task.id}'); },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: AppTheme.primary.withAlpha(25), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.primary.withAlpha(60))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.timer_outlined, color: AppTheme.primary, size: 12),
                    const SizedBox(width: 4),
                    Text('Focus', style: AppTheme.caption.copyWith(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

// ── Create Task Sheet ─────────────────────────────────────────────────────────

class _CreateTaskSheet extends ConsumerStatefulWidget {
  final WidgetRef parentRef;
  const _CreateTaskSheet({required this.parentRef});
  @override ConsumerState<_CreateTaskSheet> createState() => _CreateTaskSheetState();
}

class _CreateTaskSheetState extends ConsumerState<_CreateTaskSheet> {
  final _titleCtrl = TextEditingController();
  int       _priority  = 3;
  int       _coins     = 10;
  int       _pomodoros = 1;
  DateTime? _deadline;
  Project?  _selectedProject;
  TaskList? _selectedList;

  @override void dispose() { _titleCtrl.dispose(); super.dispose(); }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(colorScheme: ColorScheme.dark(primary: AppTheme.primary, surface: AppTheme.elevated, onSurface: AppTheme.textPrimary), dialogBackgroundColor: AppTheme.elevated),
          child: child!),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    final String listId = _selectedList?.id ?? await ref.read(inboxListIdProvider.future);
    await ref.read(tasksNotifierProvider.notifier).createTask(
      listId: listId, title: title, priority: _priority,
      price: _coins.toDouble(), estimatedPomodoros: _pomodoros, deadline: _deadline,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(ref);
    final allProjects = ref.watch(allProjectsStreamProvider).value ?? [];
    final allLists    = ref.watch(allListsStreamProvider).value ?? [];
    final filteredLists = _selectedProject != null
        ? allLists.where((l) => l.projectId == _selectedProject!.id).toList()
        : allLists.where((l) => l.projectId != null).toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 32),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width:40,height:4,decoration:BoxDecoration(color:AppTheme.surfaceBorder,borderRadius:BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Text('New Task', style: AppTheme.heading),
          const SizedBox(height: 20),

          TextField(controller: _titleCtrl, autofocus: true, style: AppTheme.body, decoration: _inputDec('Task title')),
          const SizedBox(height: 20),

          Text('Assign to (optional)', style: AppTheme.label),
          const SizedBox(height: 10),
          _PickerRow(icon: Icons.folder_outlined, label: _selectedProject?.name ?? 'No project', hasValue: _selectedProject != null,
              onTap: allProjects.isEmpty ? null : () => _showProjectPicker(allProjects),
              onClear: _selectedProject == null ? null : () => setState(() { _selectedProject = null; _selectedList = null; })),
          const SizedBox(height: 8),
          _PickerRow(icon: Icons.list_outlined, label: _selectedList?.name ?? 'No list (Inbox)', hasValue: _selectedList != null,
              onTap: filteredLists.isEmpty ? null : () => _showListPicker(filteredLists),
              onClear: _selectedList == null ? null : () => setState(() => _selectedList = null)),
          const SizedBox(height: 20),

          Text('Priority', style: AppTheme.label),
          const SizedBox(height: 10),
          Row(children: [
            _PriorityChip(label: 'High',   selected: _priority==1, color: AppTheme.error,   onTap: () => setState(() => _priority=1)),
            const SizedBox(width: 8),
            _PriorityChip(label: 'Medium', selected: _priority==2, color: AppTheme.warning, onTap: () => setState(() => _priority=2)),
            const SizedBox(width: 8),
            _PriorityChip(label: 'Low',    selected: _priority==3, color: AppTheme.primary, onTap: () => setState(() => _priority=3)),
          ]),
          const SizedBox(height: 20),

          Row(children: [
            Expanded(child: _Stepper(label:'Coins',     value:_coins,     step:5, min:0,  max:100, onChanged:(v)=>setState(()=>_coins=v))),
            const SizedBox(width: 16),
            Expanded(child: _Stepper(label:'Pomodoros', value:_pomodoros, step:1, min:1,  max:20,  onChanged:(v)=>setState(()=>_pomodoros=v))),
          ]),
          const SizedBox(height: 16),

          GestureDetector(
            onTap: _pickDeadline,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _deadline != null ? AppTheme.primary.withAlpha(76) : AppTheme.surfaceBorder)),
              child: Row(children: [
                Icon(Icons.calendar_today_outlined, size: 16, color: _deadline != null ? AppTheme.primary : AppTheme.textSecondary),
                const SizedBox(width: 10),
                Expanded(child: Text(
                    _deadline != null ? '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}' : 'Set deadline (optional)',
                    style: AppTheme.body.copyWith(fontSize: 14, color: _deadline != null ? AppTheme.textPrimary : AppTheme.textSecondary))),
                if (_deadline != null)
                  GestureDetector(onTap: () => setState(() => _deadline = null),
                      child:  Icon(Icons.close, size: 16, color: AppTheme.textSecondary)),
              ]),
            ),
          ),
          const SizedBox(height: 28),

          SizedBox(width: double.infinity,
              child: GestureDetector(onTap: _save,
                  child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(14)),
                      child: Text(s.tasksAddButton, style: AppTheme.label.copyWith(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15), textAlign: TextAlign.center)))),
        ]),
      ),
    );
  }

  void _showProjectPicker(List<Project> projects) {
    showModalBottomSheet(context: context, backgroundColor: AppTheme.elevated,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => _PickerSheet(title: 'Select Project',
            items: projects.map((p) => _PickerItem(id: p.id, label: p.name)).toList(),
            selectedId: _selectedProject?.id,
            onSelect: (id) { setState(() { _selectedProject = projects.firstWhere((p) => p.id==id); _selectedList = null; }); Navigator.pop(context); }));
  }

  void _showListPicker(List<TaskList> lists) {
    showModalBottomSheet(context: context, backgroundColor: AppTheme.elevated,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => _PickerSheet(title: 'Select List',
            items: lists.map((l) => _PickerItem(id: l.id, label: l.name)).toList(),
            selectedId: _selectedList?.id,
            onSelect: (id) {
              final list = lists.firstWhere((l) => l.id==id);
              if (_selectedProject == null && list.projectId != null) {
                final all = ref.read(allProjectsStreamProvider).value ?? [];
                _selectedProject = all.cast<Project?>().firstWhere((p) => p?.id==list.projectId, orElse: () => null);
              }
              setState(() => _selectedList = list);
              Navigator.pop(context);
            }));
  }
}

// ── Picker Row ────────────────────────────────────────────────────────────────

class _PickerRow extends StatelessWidget {
  final IconData icon; final String label; final bool hasValue;
  final VoidCallback? onTap, onClear;
  const _PickerRow({required this.icon, required this.label, required this.hasValue, this.onTap, this.onClear});
  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null && !hasValue;
    return GestureDetector(onTap: disabled ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: hasValue ? AppTheme.primary.withAlpha(76) : AppTheme.surfaceBorder)),
          child: Row(children: [
            Icon(icon, size: 16, color: hasValue ? AppTheme.primary : (disabled ? AppTheme.textDisabled : AppTheme.textSecondary)),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: AppTheme.body.copyWith(fontSize: 14, color: hasValue ? AppTheme.textPrimary : (disabled ? AppTheme.textDisabled : AppTheme.textSecondary)))),
            if (onClear != null) GestureDetector(onTap: onClear, child:  Icon(Icons.close, size: 15, color: AppTheme.textSecondary))
            else if (!disabled)  Icon(Icons.chevron_right, size: 16, color: AppTheme.textDisabled),
          ]),
        ));
  }
}

// ── Picker Sheet ──────────────────────────────────────────────────────────────

class _PickerItem { final String id, label; const _PickerItem({required this.id, required this.label}); }

class _PickerSheet extends StatelessWidget {
  final String title; final List<_PickerItem> items; final String? selectedId; final ValueChanged<String> onSelect;
  const _PickerSheet({required this.title, required this.items, required this.onSelect, this.selectedId});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width:40,height:4,decoration:BoxDecoration(color:AppTheme.surfaceBorder,borderRadius:BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        Text(title, style: AppTheme.body.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ...items.map((item) {
          final sel = item.id == selectedId;
          return GestureDetector(onTap: () => onSelect(item.id),
              child: Container(width: double.infinity, margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(color: sel ? AppTheme.primary.withAlpha(20) : AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: sel ? AppTheme.primary.withAlpha(80) : AppTheme.surfaceBorder)),
                  child: Row(children: [
                    Expanded(child: Text(item.label, style: AppTheme.body.copyWith(fontSize: 14, color: sel ? AppTheme.primary : AppTheme.textPrimary, fontWeight: sel ? FontWeight.w600 : FontWeight.w400))),
                    if (sel)  Icon(Icons.check, size: 16, color: AppTheme.primary),
                  ])));
        }),
      ]),
    );
  }
}

// ── Priority Chip ─────────────────────────────────────────────────────────────

class _PriorityChip extends StatelessWidget {
  final String label; final bool selected; final Color color; final VoidCallback onTap;
  const _PriorityChip({required this.label, required this.selected, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(child: GestureDetector(onTap: onTap,
      child: AnimatedContainer(duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: selected ? color.withAlpha(30) : AppTheme.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: selected ? color : AppTheme.surfaceBorder)),
          child: Text(label, style: AppTheme.caption.copyWith(color: selected ? color : AppTheme.textSecondary, fontWeight: selected ? FontWeight.w600 : FontWeight.w400), textAlign: TextAlign.center))));
}

// ── Stepper ───────────────────────────────────────────────────────────────────

class _Stepper extends StatelessWidget {
  final String label; final int value, step, min, max; final ValueChanged<int> onChanged;
  const _Stepper({required this.label, required this.value, required this.step, required this.min, required this.max, required this.onChanged});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.surfaceBorder)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTheme.caption.copyWith(fontSize: 11)),
      const SizedBox(height: 6),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        GestureDetector(onTap: value>min ? ()=>onChanged(value-step) : null,
            child: Container(width:28,height:28,decoration:BoxDecoration(color:AppTheme.elevated,borderRadius:BorderRadius.circular(6)),
                child:Icon(Icons.remove,size:14,color:value>min?AppTheme.textPrimary:AppTheme.textDisabled))),
        Text('$value', style: AppTheme.body.copyWith(fontWeight: FontWeight.w600)),
        GestureDetector(onTap: value<max ? ()=>onChanged(value+step) : null,
            child: Container(width:28,height:28,decoration:BoxDecoration(color:AppTheme.elevated,borderRadius:BorderRadius.circular(6)),
                child:Icon(Icons.add,size:14,color:value<max?AppTheme.textPrimary:AppTheme.textDisabled))),
      ]),
    ]),
  );
}

// ── Empty Tab ─────────────────────────────────────────────────────────────────

class _EmptyTab extends StatelessWidget {
  final String message, subMessage;
  const _EmptyTab({required this.message, required this.subMessage});
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 40),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width:56,height:56,decoration:BoxDecoration(color:AppTheme.primary.withAlpha(20),shape:BoxShape.circle),
          child: Icon(Icons.check_circle_outline,color:AppTheme.primary,size:26)),
      const SizedBox(height: 16),
      Text(message, style: AppTheme.body.copyWith(fontWeight: FontWeight.w500), textAlign: TextAlign.center),
      const SizedBox(height: 6),
      Text(subMessage, style: AppTheme.caption.copyWith(height: 1.6), textAlign: TextAlign.center),
    ]),
  ));
}