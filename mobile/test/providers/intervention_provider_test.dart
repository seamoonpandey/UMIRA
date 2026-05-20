import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:umira/features/intervention/providers/intervention_provider.dart';
import 'package:umira/features/intervention/data/intervention_repository.dart';
import 'package:umira/features/intervention/models/intervention_models.dart';
import 'package:umira/core/network/api_client.dart';
import 'package:umira/core/storage/secure_storage.dart';

// ── Mock infrastructure ────────────────────────────────────────

class _MockSecureStorage extends SecureStorage {
  @override
  Future<String?> readToken() async => null;
  @override
  Future<void> writeToken(String token) async {}
  @override
  Future<void> deleteToken() async {}
}

class _MockApiClient extends ApiClient {
  _MockApiClient() : super(_MockSecureStorage(), baseUrl: 'http://test');
}

class _MockInterventionRepository extends InterventionRepository {
  final List<InterventionSession> sessions;
  _MockInterventionRepository(this.sessions) : super(_MockApiClient());

  @override
  Future<List<InterventionSession>> listSessions() async => sessions;
}

// ── Tests ──────────────────────────────────────────────────────

void main() {
  group('InterventionProgress model', () {
    test('default values are all zero', () {
      const p = InterventionProgress();
      expect(p.totalSessions, 0);
      expect(p.spellingScore, 0);
      expect(p.spellingTotal, 0);
      expect(p.typingWpm, 0);
      expect(p.practiceWpm, 0);
      expect(p.spellingAverage, 0);
    });

    test('copyWith preserves unchanged fields', () {
      const p = InterventionProgress(
        totalSessions: 5,
        spellingScore: 10,
        spellingTotal: 20,
        typingWpm: 30,
        practiceWpm: 40,
      );
      final updated = p.copyWith(typingWpm: 50);
      expect(updated.totalSessions, 5);
      expect(updated.spellingScore, 10);
      expect(updated.spellingTotal, 20);
      expect(updated.typingWpm, 50);
      expect(updated.practiceWpm, 40);
    });

    test('spellingAverage calculates correctly', () {
      const p = InterventionProgress(spellingScore: 8, spellingTotal: 10);
      expect(p.spellingAverage, 80.0);
    });

    test('spellingAverage returns 0 when total is 0', () {
      const p = InterventionProgress();
      expect(p.spellingAverage, 0);
    });

    test('toJson / fromJson round-trip', () {
      const p = InterventionProgress(
        totalSessions: 3,
        spellingScore: 15,
        spellingTotal: 20,
        typingWpm: 25,
        practiceWpm: 35,
      );
      final json = p.toJson();
      final restored = InterventionProgress.fromJson(json);
      expect(restored.totalSessions, p.totalSessions);
      expect(restored.spellingScore, p.spellingScore);
      expect(restored.spellingTotal, p.spellingTotal);
      expect(restored.typingWpm, p.typingWpm);
      expect(restored.practiceWpm, p.practiceWpm);
    });

    test('fromJson handles missing keys gracefully', () {
      final restored = InterventionProgress.fromJson({});
      expect(restored.totalSessions, 0);
      expect(restored.spellingScore, 0);
      expect(restored.spellingTotal, 0);
      expect(restored.typingWpm, 0);
      expect(restored.practiceWpm, 0);
    });
  });

  group('InterventionNotifier — state transitions', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('initial state is empty', () {
      final notifier = InterventionNotifier();
      expect(notifier.state.totalSessions, 0);
      expect(notifier.state.spellingScore, 0);
      expect(notifier.state.spellingTotal, 0);
      expect(notifier.state.typingWpm, 0);
      expect(notifier.state.practiceWpm, 0);
    });

    test('recordSpellingResult increments totalSessions and adds score/total',
        () async {
      final notifier = InterventionNotifier();
      await notifier.recordSpellingResult(8, 10);
      expect(notifier.state.totalSessions, 1);
      expect(notifier.state.spellingScore, 8);
      expect(notifier.state.spellingTotal, 10);
    });

    test('recordSpellingResult accumulates across multiple calls', () async {
      final notifier = InterventionNotifier();
      await notifier.recordSpellingResult(8, 10);
      await notifier.recordSpellingResult(9, 10);
      expect(notifier.state.totalSessions, 2);
      expect(notifier.state.spellingScore, 17);
      expect(notifier.state.spellingTotal, 20);
    });

    test('recordTypingResult increments sessions and sets typingWpm',
        () async {
      final notifier = InterventionNotifier();
      await notifier.recordTypingResult(45);
      expect(notifier.state.totalSessions, 1);
      expect(notifier.state.typingWpm, 45);
    });

    test('recordTypingResult overwrites previous wpm', () async {
      final notifier = InterventionNotifier();
      await notifier.recordTypingResult(30);
      await notifier.recordTypingResult(50);
      expect(notifier.state.totalSessions, 2);
      expect(notifier.state.typingWpm, 50);
    });

    test('recordPracticeResult increments sessions and sets practiceWpm',
        () async {
      final notifier = InterventionNotifier();
      await notifier.recordPracticeResult(55);
      expect(notifier.state.totalSessions, 1);
      expect(notifier.state.practiceWpm, 55);
    });

    test('recordLesson increments totalSessions only', () async {
      final notifier = InterventionNotifier();
      await notifier.recordLesson();
      expect(notifier.state.totalSessions, 1);
      expect(notifier.state.spellingScore, 0);
      expect(notifier.state.spellingTotal, 0);
      expect(notifier.state.typingWpm, 0);
      expect(notifier.state.practiceWpm, 0);
    });

    test('multiple different recordings accumulate correctly', () async {
      final notifier = InterventionNotifier();
      await notifier.recordSpellingResult(8, 10);
      await notifier.recordTypingResult(45);
      await notifier.recordPracticeResult(55);
      await notifier.recordLesson();

      expect(notifier.state.totalSessions, 4);
      expect(notifier.state.spellingScore, 8);
      expect(notifier.state.spellingTotal, 10);
      expect(notifier.state.typingWpm, 45);
      expect(notifier.state.practiceWpm, 55);
    });
  });

  group('interventionSessionsProvider', () {
    test('returns sessions from the repository', () async {
      final sessions = [
        InterventionSession(
          id: '1',
          type: 'spelling',
          date: '2025-01-01',
          score: 80,
          total: 100,
        ),
        InterventionSession(
          id: '2',
          type: 'typing',
          date: '2025-01-02',
          wpm: 40,
        ),
      ];
      final container = ProviderContainer(
        overrides: [
          interventionRepoProvider.overrideWithValue(
            _MockInterventionRepository(sessions),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(interventionSessionsProvider.future);
      expect(result.length, 2);
      expect(result[0].id, '1');
      expect(result[0].type, 'spelling');
      expect(result[1].id, '2');
      expect(result[1].type, 'typing');
    });

    test('returns empty list when repository returns empty', () async {
      final container = ProviderContainer(
        overrides: [
          interventionRepoProvider.overrideWithValue(
            _MockInterventionRepository([]),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(interventionSessionsProvider.future);
      expect(result, isEmpty);
    });
  });
}
