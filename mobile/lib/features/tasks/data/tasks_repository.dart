import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/task_models.dart';

final tasksRepoProvider =
    Provider((ref) => TasksRepository(ref.watch(apiClientProvider)));

class TasksRepository {
  final ApiClient _api;
  TasksRepository(this._api);

  Future<List<Task>> list() async {
    final j = await _api.getJson('/tasks');
    return ((j['tasks'] as List?) ?? [])
        .map((e) => Task.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Task> create(
      {required String title, String? sourceText, String? priority,}) async {
    final j = await _api.postJson('/tasks', body: {
      'title': title,
      if (sourceText != null) 'sourceText': sourceText,
      if (priority != null) 'priority': priority,
    },);
    return Task.fromJson(j['task'] as Map<String, dynamic>);
  }

  Future<List<Microtask>> generateMicrotasks(String taskId,
      {required String goal,
      int? sessionLength,
      bool extraSimplify = false,}) async {
    final j = await _api.postJson('/tasks/$taskId/microtasks/generate', body: {
      'goal': goal,
      if (sessionLength != null) 'sessionLength': sessionLength,
      'extraSimplify': extraSimplify,
    },);
    if (j['ok'] != true) {
      throw Exception(j['refusal'] ?? j['error'] ?? 'AI generation failed');
    }
    return ((j['microtasks'] as List?) ?? [])
        .map((e) => Microtask.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Microtask> updateMicrotask(String id,
      {String? status, String? label, int? position,}) async {
    final j = await _api.patchJson('/microtasks/$id', body: {
      if (status != null) 'status': status,
      if (label != null) 'label': label,
      if (position != null) 'position': position,
    },);
    return Microtask.fromJson(j['microtask'] as Map<String, dynamic>);
  }

  Future<void> deleteTask(String id) => _api.delete('/tasks/$id');
}
