// lib/data/repositories/tasks_repository.dart

import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../database/daos/task_dao.dart';
import 'banking_repository.dart';
import 'package:drift/drift.dart';

class TaskRepository {
  final TaskDao _taskDao;
  final BankingRepository _bankingRepository;

  TaskRepository(this._taskDao, this._bankingRepository);

  Stream<List<Task>> watchAllTasks() => _taskDao.watchAllTasks();

  Stream<List<Task>> watchTasksForList(String listId) =>
      _taskDao.watchTasksForList(listId);

  Stream<List<TaskStep>> watchStepsForTask(String taskId) =>
      _taskDao.watchStepsForTask(taskId);

  Future<bool> updateTask(TasksCompanion task) =>
      _taskDao.updateTask(task);

  Future<int> deleteTask(String id) =>
      _taskDao.deleteTask(id);

  Future<void> insertStep(TaskStepsCompanion step) =>
      _taskDao.insertStep(step);

  Future<bool> updateStep(TaskStepsCompanion step) =>
      _taskDao.updateStep(step);

  Future<int> deleteStep(String id) =>
      _taskDao.deleteStep(id);

  Future<void> createTask({
    required String title,
    String? description,
    required String listId,
    required int priority,
    required double price,
    int estimatedPomodoros = 1,
    DateTime? deadline,
  }) async {
    final task = TasksCompanion(
      id                : Value(const Uuid().v4()),
      title             : Value(title),
      description       : Value(description),
      listId            : Value(listId),
      priority          : Value(priority),
      price             : Value(price),
      deadline          : Value(deadline),
      estimatedPomodoro : Value(estimatedPomodoros),
    );
    await _taskDao.insertTask(task);
  }

  // ── BUG N3 FIX ─────────────────────────────────────────────────────────────
  // completeTask() previously had no guard for already-completed tasks.
  // A rapid double-tap or any programmatic caller could call this twice,
  // setting isCompleted=true again AND calling earn() a second time —
  // silently doubling the coin award. The fix adds a repository-level guard
  // (not just a UI-level guard) so the invariant holds for every caller.
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> completeTask(String taskId) async {
    await _taskDao.db.transaction(() async {
      final task = await _taskDao.getTaskById(taskId);
      if (task == null) return;
      if (task.isCompleted) return; // ← N3: guard against double-completion

      final updatedTask = task.copyWith(isCompleted: true);
      await _taskDao.updateTask(updatedTask.toCompanion(true));

      await _bankingRepository.earn(
        task.price,
        relatedTask: task.id,
        note: 'Completed: ${task.title}',
      );
    });
  }

  Future<void> toggleStep(TaskStep step) async {
    final updated = step.copyWith(isCompleted: !step.isCompleted);
    await _taskDao.updateStep(updated.toCompanion(true));
  }

  // Tags ──────────────────────────────────────────────────────────────────────

  Stream<List<Tag>> watchAllTags() => _taskDao.watchAllTags();

  Stream<List<Tag>> watchTagsForTask(String taskId) =>
      _taskDao.watchTagsForTask(taskId);

  // ── BUG N1 FIX ─────────────────────────────────────────────────────────────
  // createTag() previously returned Future<void>. The caller (_createTag in
  // task_detail_screen.dart) had no way to retrieve the new tag's ID and
  // hardcoded '' as the tagId in the subsequent addTagToTask() call, so newly
  // created tags were never actually linked to the task.
  //
  // Fix: generate the ID here and return it so the caller can pass it straight
  // to addTagToTask() without any extra round-trip query.
  // ─────────────────────────────────────────────────────────────────────────
  Future<String> createTag({required String name, required String color}) async {
    final id = const Uuid().v4();
    await _taskDao.insertTag(TagsCompanion(
      id    : Value(id),
      name  : Value(name),
      color : Value(color),
    ));
    return id; // ← was void before
  }

  Future<void> addTagToTask({required String taskId, required String tagId}) =>
      _taskDao.insertTaskTag(
        TaskTagsCompanion(taskId: Value(taskId), tagId: Value(tagId)),
      );

  Future<void> removeTagFromTask({
    required String taskId,
    required String tagId,
  }) => _taskDao.deleteTaskTag(taskId, tagId);
}