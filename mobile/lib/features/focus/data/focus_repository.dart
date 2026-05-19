import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/focus_models.dart';

final focusRepoProvider =
    Provider((ref) => FocusRepository(ref.watch(apiClientProvider)));

class FocusRepository {
  final ApiClient _api;
  FocusRepository(this._api);

  Future<FocusSession> start({String? taskId, required int minutes}) async {
    final j = await _api.postJson('/focus/sessions', body: {
      if (taskId != null) 'taskId': taskId,
      'plannedMinutes': minutes,
    },);
    return FocusSession.fromJson(j['session'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> complete(String id,
      {required int actualMinutes,
      int distractions = 0,
      bool aiReflection = false,}) async {
    return _api.postJson('/focus/sessions/$id/complete', body: {
      'actualMinutes': actualMinutes,
      'distractionEvents': distractions,
      'generateAiReflection': aiReflection,
    },);
  }

  Future<void> cancel(String id) =>
      _api.postJson('/focus/sessions/$id/cancel', body: {});
}
