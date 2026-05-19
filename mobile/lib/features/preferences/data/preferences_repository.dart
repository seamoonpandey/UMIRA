import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

final preferencesRepoProvider = Provider((ref) => PreferencesRepository(ref.watch(apiClientProvider)));

class PreferencesRepository {
  final ApiClient _api;
  PreferencesRepository(this._api);

  Future<Map<String, dynamic>> get() async {
    final j = await _api.getJson('/preferences');
    return j['preferences'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> patch(Map<String, dynamic> data) async {
    final j = await _api.patchJson('/preferences', body: data);
    return j['preferences'] as Map<String, dynamic>;
  }

  Future<void> deleteAccount() => _api.delete('/privacy/account');
  Future<Map<String, dynamic>> exportData() => _api.getJson('/privacy/export');
}
