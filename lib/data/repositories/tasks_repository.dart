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

  // Passthroughs — ids are parameters, not stored state
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

  // Builder — constructs companion from simple primitives
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
      id: Value(const Uuid().v4()),
      title: Value(title),
      description: Value(description),
      listId: Value(listId),
      priority: Value(priority),
      price: Value(price),
      deadline: Value(deadline),
      estimatedPomodoro: Value(estimatedPomodoros),
    );
    await _taskDao.insertTask(task);
  }

  // Coordinator — multiple steps wrapped in a database transaction
  Future<void> completeTask(String taskId) async {
    await _taskDao.db.transaction(() async {
      final task = await _taskDao.getTaskById(taskId);
      if (task == null) return;

      // Data classes are immutable — use copyWith to create updated version
      final updatedTask = task.copyWith(isCompleted: true);
      await _taskDao.updateTask(updatedTask.toCompanion(true));

      // Earn coins — BankingRepository handles all transaction details
      await _bankingRepository.earn(
        task.price,
        relatedTask: task.id,
        note: 'Completed: ${task.title}',
      );
    });
  }

  // Flips a step's completion state to its opposite
  Future<void> toggleStep(TaskStep step) async {
    final updated = step.copyWith(isCompleted: !step.isCompleted);
    await _taskDao.updateStep(updated.toCompanion(true));
  }

  // Tags ──────────────────────────────────────────────────────

  Stream<List<Tag>> watchAllTags() => _taskDao.watchAllTags();

  Stream<List<Tag>> watchTagsForTask(String taskId) =>
      _taskDao.watchTagsForTask(taskId);

  Future<void> createTag({required String name, required String color}) =>
      _taskDao.insertTag(TagsCompanion(
        id: Value(const Uuid().v4()),
        name: Value(name),
        color: Value(color),
      ));

  Future<void> addTagToTask({required String taskId, required String tagId}) =>
      _taskDao.insertTaskTag(
        TaskTagsCompanion(taskId: Value(taskId), tagId: Value(tagId)),
      );

  Future<void> removeTagFromTask({
    required String taskId,
    required String tagId,
  }) => _taskDao.deleteTaskTag(taskId, tagId);
}