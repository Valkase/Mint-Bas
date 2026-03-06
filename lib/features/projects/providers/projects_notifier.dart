import 'package:bd_project/data/database/app_database.dart';
import 'package:bd_project/shared/providers/repository_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


// All lists across every project — used by the task creation sheet
final allListsStreamProvider = StreamProvider<List<TaskList>>((ref) {
  return ref.watch(projectRepositoryProvider).watchAllLists();
});

// Returns (and lazily creates) the fixed Inbox list ID — non-nullable String
final inboxListIdProvider = FutureProvider<String>((ref) {
  return ref.read(projectRepositoryProvider).getOrCreateInboxList();
});

// 1. StreamProvider — watches live data
// UI uses this to display the list
final projectsStreamProvider = StreamProvider<List<Project>>((ref) {
  return ref.watch(projectRepositoryProvider).watchAllProjects();
});

// 2. AsyncNotifier — handles actions
// UI uses this to create/delete projects
class ProjectsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}  // no initial data needed — StreamProvider handles that

  Future<void> createProject({
    required String name,
    String? description,
    required String color,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() =>
        ref.read(projectRepositoryProvider).createProject(
          name: name,
          description: description,
          color: color,
        )
    );
  }

  Future<void> deleteProject(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() =>
        ref.read(projectRepositoryProvider).deleteProject(id)
    );
  }

  Future<void> createList({
    required String name,
    required String projectId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() =>
        ref.read(projectRepositoryProvider).createList(
          name: name,
          projectId: projectId,
        )
    );
  }
}

// The provider that exposes the notifier
final projectsNotifierProvider = AsyncNotifierProvider<ProjectsNotifier, void>(
    ProjectsNotifier.new
);