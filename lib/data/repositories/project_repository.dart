import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../database/daos/project_dao.dart';
import 'package:drift/drift.dart';

class ProjectRepository {
  final ProjectDao _projectDao;
  ProjectRepository(this._projectDao);

  Stream<List<Project>> watchAllProjects() => _projectDao.watchAllProjects();

  Stream<List<TaskList>> watchListsForProject(String projectId) {
    return _projectDao.watchListsForProject(projectId);
  }

  Future<void> createProject({
    required String name,
    String? description,
    required String color,
  }) async {
    final project = ProjectsCompanion(
      id: Value(const Uuid().v4()),
      name: Value(name),
      description: Value(description),
      color: Value(color),
    );
    await _projectDao.insertProject(project);
  }

  Future<void> updateProject(ProjectsCompanion project) async {
    await _projectDao.updateProject(project);
  }

  Future<void> deleteProject(String id) async {
    await _projectDao.deleteProject(id);
  }

  Future<void> createList({
    required String name,
    String? description,
    String? projectId,
  }) async {
    final list = TaskListsCompanion(
      id: Value(const Uuid().v4()),
      name: Value(name),
      description: Value(description),
      projectId: Value(projectId),
    );
    await _projectDao.insertList(list);
  }

  Stream<List<TaskList>> watchAllLists() => _projectDao.watchAllLists();

  Future<List<TaskList>> getAllLists() => _projectDao.getAllLists();

  /// Returns the id of the "Inbox" list, creating it if it doesn't exist yet.
  /// Inbox has no projectId — it's a catch-all for unassigned tasks.
  Future<String> getOrCreateInboxList() async {
    final all = await _projectDao.getAllLists();
    final existing = all.where((l) => l.name == 'Inbox' && l.projectId == null);
    if (existing.isNotEmpty) return existing.first.id;
    final id = const Uuid().v4();
    await _projectDao.insertList(TaskListsCompanion(
      id: Value(id),
      name: const Value('Inbox'),
      projectId: const Value(null),
    ));
    return id;
  }

  Stream<TaskList?> watchListById(String id) =>
      _projectDao.watchListById(id);

}