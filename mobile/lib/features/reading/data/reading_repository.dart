import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/reading_models.dart';

final readingRepoProvider = Provider((ref) => ReadingRepository(ref.watch(apiClientProvider)));

class ReadingRepository {
  final ApiClient _api;
  ReadingRepository(this._api);

  Future<SimplifyResult> simplify({required String text, String level = 'medium', bool glossary = true, bool save = false}) async {
    final j = await _api.postJson('/reading/simplify', body: {
      'text': text,
      'level': level,
      'glossary': glossary,
      'save': save,
    });
    if (j['ok'] != true) {
      throw Exception(j['error'] ?? 'Simplification failed');
    }
    return SimplifyResult.fromJson(j['result'] as Map<String, dynamic>);
  }
}
