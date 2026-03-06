import 'package:bd_project/data/database/app_database.dart';
import 'package:bd_project/shared/providers/repository_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

// All tasks across every list — used by the Tasks home screen
final allTasksStreamProvider = StreamProvider<List<Task>>((ref) {
  return ref.watch(taskRepositoryProvider).watchAllTasks();
});

// StreamProvider with a parameter
final tasksStreamProvider = StreamProvider.family<List<Task>, String>((ref, listId) {
  return ref.watch(taskRepositoryProvider).watchTasksForList(listId);
});

// Steps stream also needs a parameter
final stepsStreamProvider = StreamProvider.family<List<TaskStep>, String>((ref, taskId) {
  return ref.watch(taskRepositoryProvider).watchStepsForTask(taskId);
});

final tasksNotifierProvider = AsyncNotifierProvider<TasksNotifier, void>(TasksNotifier.new);

final listsStreamProvider = StreamProvider.family<List<TaskList>, String>((ref, projectId) {
  return ref.watch(projectRepositoryProvider).watchListsForProject(projectId);
});

final allListsStreamProvider = StreamProvider<List<TaskList>>((ref) {
  return ref.watch(projectRepositoryProvider).watchAllLists();
});

final allProjectsStreamProvider = StreamProvider<List<Project>>((ref) {
  return ref.watch(projectRepositoryProvider).watchAllProjects();
});

class TasksNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> createTask({
    required String title,
    String? description,
    required String listId,
    required int priority,
    required double price,
    int estimatedPomodoros = 1,
    DateTime? deadline,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() =>
        ref.read(taskRepositoryProvider).createTask(
          title: title,
          description: description,
          listId: listId,
          priority: priority,
          price: price,
          estimatedPomodoros: estimatedPomodoros,
          deadline: deadline,
        ));
  }

  Future<void> updateTask(TasksCompanion task) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() =>
        ref.read(taskRepositoryProvider).updateTask(task));
  }

  Future<void> completeTask(String taskId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() =>
        ref.read(taskRepositoryProvider).completeTask(taskId));
  }

  Future<void> deleteTask(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() =>
        ref.read(taskRepositoryProvider).deleteTask(id));
  }

  Future<void> toggleStep(TaskStep step) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() =>
        ref.read(taskRepositoryProvider).toggleStep(step));
  }

  Future<void> insertStep({
    required String taskId,
    required String title,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() =>
        ref.read(taskRepositoryProvider).insertStep(
          TaskStepsCompanion(
            id: Value(const Uuid().v4()),
            taskId: Value(taskId),
            title: Value(title),
          ),
        ));
  }

  Future<void> deleteStep(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() =>
        ref.read(taskRepositoryProvider).deleteStep(id));
  }
}
