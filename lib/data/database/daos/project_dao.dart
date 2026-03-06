import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/projects.dart';
import '../tables/task_lists.dart';

part 'project_dao.g.dart';

@DriftAccessor(tables: [Projects, TaskLists])
class ProjectDao extends DatabaseAccessor<AppDatabase> with _$ProjectDaoMixin {
  ProjectDao(super.db);

  // Fetch all projects, newest first
  Future<List<Project>> getAllProjects() =>
      (select(projects)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();

  // Watch projects (reactive stream — UI rebuilds when data changes)
  Stream<List<Project>> watchAllProjects() =>
      (select(projects)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();

  // Insert a new project
  Future<void> insertProject(ProjectsCompanion project) =>
      into(projects).insert(project);

  // Update a project
  Future<bool> updateProject(ProjectsCompanion project) =>
      update(projects).replace(project);

  // Insert a new list
  Future<void> insertList(TaskListsCompanion list) =>
      into(taskLists).insert(list);

  Future<void> upsertList(TaskListsCompanion list) =>
      into(taskLists).insertOnConflictUpdate(list);

  // Delete a project by id
  Future<int> deleteProject(String id) =>
      (delete(projects)..where((t) => t.id.equals(id))).go();

  // Get all lists for a project
  Future<List<TaskList>> getListsForProject(String projectId) =>
      (select(taskLists)..where((t) => t.projectId.equals(projectId))).get();

  Stream<List<TaskList>> watchListsForProject(String projectId) =>
      (select(taskLists)..where((t) => t.projectId.equals(projectId))).watch();

  Stream<TaskList?> watchListById(String id) =>
      (select(taskLists)..where((l) => l.id.equals(id))).watchSingleOrNull();

  Stream<List<TaskList>> watchAllLists() => select(taskLists).watch();

  Future<List<TaskList>> getAllLists() => select(taskLists).get();

}