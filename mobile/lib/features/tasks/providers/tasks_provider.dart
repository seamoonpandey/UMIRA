import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/tasks_repository.dart';
import '../models/task_models.dart';

final tasksListProvider = FutureProvider.autoDispose<List<Task>>((ref) async {
  return ref.watch(tasksRepoProvider).list();
});

final taskDetailProvider =
    FutureProvider.autoDispose.family<Task?, String>((ref, id) async {
  final list = await ref.watch(tasksRepoProvider).list();
  try {
    return list.firstWhere((t) => t.id == id);
  } catch (_) {
    return null;
  }
});
