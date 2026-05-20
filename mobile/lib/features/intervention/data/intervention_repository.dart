import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/intervention_models.dart';

final interventionRepoProvider = Provider<InterventionRepository>(
  (ref) => InterventionRepository(ref.watch(apiClientProvider)),
);

class InterventionRepository {
  final ApiClient _api;

  InterventionRepository(this._api);

  Future<PracticeResult> analyzePractice(
    String audioPath, {
    String expectedText = 'The boy went to the store to buy some candy.',
  }) async {
    try {
      final formData = FormData.fromMap({
        'file':
            await MultipartFile.fromFile(audioPath, filename: 'recording.m4a'),
        'expectedText': expectedText,
      });

      final response = await _api.dio.post(
        '/intervention/analyze-practice',
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
          receiveTimeout: const Duration(seconds: 120),
        ),
      );

      return PracticeResult.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to analyze practice: $e');
    }
  }

  Future<String> performOcr(String imagePath) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(imagePath, filename: 'scan.jpg'),
      });

      final response = await _api.dio.post(
        '/intervention/ocr',
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      return (response.data as Map<String, dynamic>)['text'] as String? ?? '';
    } catch (e) {
      throw Exception('OCR failed: $e');
    }
  }

  Future<String> simplifyWithBart(String text) async {
    try {
      final response = await _api.postJson(
        '/intervention/simplify',
        body: {
          'text': text,
        },
      );
      return response['simplified'] as String? ?? text;
    } catch (e) {
      // Fallback: return original text
      return text;
    }
  }

  Future<void> saveSession({
    required String type,
    int? score,
    int? total,
    int? wpm,
    int? accuracy,
    String? grapheme,
    String? phoneme,
    Map<String, dynamic>? stats,
  }) async {
    try {
      await _api.postJson(
        '/intervention/sessions',
        body: {
          'type': type,
          if (score != null) 'score': score,
          if (total != null) 'total': total,
          if (wpm != null) 'wpm': wpm,
          if (accuracy != null) 'accuracy': accuracy,
          if (grapheme != null) 'grapheme': grapheme,
          if (phoneme != null) 'phoneme': phoneme,
          if (stats != null) 'stats': stats,
        },
      );
    } catch (_) {
      // offline-safe
    }
  }

  Future<List<InterventionSession>> listSessions() async {
    try {
      final response = await _api.getJson('/intervention/sessions');
      final list = response['sessions'] as List? ?? [];
      return list
          .map((e) => InterventionSession.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
