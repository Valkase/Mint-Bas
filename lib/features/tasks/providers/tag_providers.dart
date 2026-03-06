import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/database/app_database.dart';
import '../../../shared/providers/repository_providers.dart';

// ── Stream providers ──────────────────────────────────────────────────────────

/// All tags in the database (for the tag picker).
final allTagsProvider = StreamProvider<List<Tag>>((ref) {
  return ref.watch(taskRepositoryProvider).watchAllTags();
});

/// Tags currently attached to a specific task.
final tagsForTaskProvider =
StreamProvider.family<List<Tag>, String>((ref, taskId) {
  return ref.watch(taskRepositoryProvider).watchTagsForTask(taskId);
});

/// A single task list by ID — used by the list header to get the list name.
final listByIdProvider =
StreamProvider.family<TaskList?, String>((ref, listId) {
  return ref.watch(projectRepositoryProvider).watchListById(listId);
});

// ── Tag notifier ──────────────────────────────────────────────────────────────

final tagNotifierProvider =
AsyncNotifierProvider<TagNotifier, void>(TagNotifier.new);

class TagNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> createTag({
    required String name,
    required String color,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
          () => ref.read(taskRepositoryProvider).createTag(
        name: name,
        color: color,
      ),
    );
  }

  Future<void> addTagToTask({
    required String taskId,
    required String tagId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
          () => ref.read(taskRepositoryProvider).addTagToTask(
        taskId: taskId,
        tagId: tagId,
      ),
    );
  }

  Future<void> removeTagFromTask({
    required String taskId,
    required String tagId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
          () => ref.read(taskRepositoryProvider).removeTagFromTask(
        taskId: taskId,
        tagId: tagId,
      ),
    );
  }
}