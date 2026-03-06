import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/tasks.dart';
import '../tables/task_steps.dart';
import '../tables/tags.dart';
import '../tables/task_tags.dart';

part 'task_dao.g.dart';

@DriftAccessor(tables: [Tasks, TaskSteps, Tags, TaskTags])
class TaskDao extends DatabaseAccessor<AppDatabase> with _$TaskDaoMixin {
  TaskDao(super.db);

  // Watch ALL tasks across every list, ordered by deadline then priority
  Stream<List<Task>> watchAllTasks() =>
      (select(tasks)..orderBy([
            (t) => OrderingTerm(expression: t.deadline, mode: OrderingMode.asc, nulls: NullsOrder.last),
            (t) => OrderingTerm.asc(t.priority),
            (t) => OrderingTerm.desc(t.createdAt),
      ])).watch();

  Future<Task?> getTaskById(String id) =>
      (select(tasks)..where((t) => t.id.equals(id))).getSingleOrNull();

  Stream<Task?> watchTaskById(String id) =>
      (select(tasks)..where((t) => t.id.equals(id))).watchSingleOrNull();

  // Watch Tasks for list
  Stream<List<Task>> watchTasksForList(String listId) =>
      (select(tasks)..where((t) => t.listId.equals(listId))..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();

  // Fetch Tasks for list (used by dashboard)
  Future<List<Task>> getTasksForList(String listId) =>
      (select(tasks)..where((t) => t.listId.equals(listId))).get();

  // Insert a new task
  Future<void> insertTask(TasksCompanion task) =>
      into(tasks).insert(task);

  // Update a task
  Future<bool> updateTask(TasksCompanion task) =>
      update(tasks).replace(task);

  // Delete a task by id
  Future<int> deleteTask(String id) =>
      (delete(tasks)..where((t) => t.id.equals(id))).go();

  // Watch steps for each task
  Stream<List<TaskStep>> watchStepsForTask(String taskId) =>
      (select(taskSteps)..where((t) => t.taskId.equals(taskId))..orderBy([(t) => OrderingTerm.asc(t.id)])).watch();

  // Insert a step to the task
  Future<void> insertStep(TaskStepsCompanion step) =>
      into(taskSteps).insert(step);

  // Update a step for a task
  Future<bool> updateStep(TaskStepsCompanion step) =>
      update(taskSteps).replace(step);

  // Delete a step for a task
  Future<int> deleteStep(String id) =>
      (delete(taskSteps)..where((t) => t.id.equals(id))).go();

  Stream<List<Tag>> watchAllTags() => select(tags).watch();

  Stream<List<Tag>> watchTagsForTask(String taskId) {
    final query = select(tags).join([
      innerJoin(taskTags, taskTags.tagId.equalsExp(tags.id)),
    ])
      ..where(taskTags.taskId.equals(taskId));
    return query.watch().map(
          (rows) => rows.map((row) => row.readTable(tags)).toList(),
    );
  }

  Future<void> insertTag(TagsCompanion tag) =>
      into(tags).insertOnConflictUpdate(tag);

  Future<void> insertTaskTag(TaskTagsCompanion taskTag) =>
      into(taskTags).insertOnConflictUpdate(taskTag);

  Future<void> deleteTaskTag(String taskId,String id) =>
      (delete(taskTags)..where((t) => t.taskId.equals(taskId) & t.tagId.equals(id))).go();

  Future<void> deleteTag(String id) =>
      (delete(tags)..where((t) => t.id.equals(id))).go();
}