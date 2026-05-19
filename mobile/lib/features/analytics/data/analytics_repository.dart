import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

final analyticsRepoProvider = Provider((ref) => AnalyticsRepository(ref.watch(apiClientProvider)));

class AnalyticsRepository {
  final ApiClient _api;
  AnalyticsRepository(this._api);
  Future<Map<String, dynamic>> summary() => _api.getJson('/analytics/summary');
  Future<void> track(String name, [Map<String, dynamic>? props]) async {
    try { await _api.postJson('/analytics/events', body: {'eventName': name, 'props': props ?? {}}); } catch (_) {}
  }
}
