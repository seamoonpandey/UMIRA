import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/intervention_models.dart';
import '../data/intervention_repository.dart';

// Local storage for offline intervention progress
class InterventionProgress {
  final int totalSessions;
  final int spellingScore;
  final int spellingTotal;
  final int typingWpm;
  final int practiceWpm;

  const InterventionProgress({
    this.totalSessions = 0,
    this.spellingScore = 0,
    this.spellingTotal = 0,
    this.typingWpm = 0,
    this.practiceWpm = 0,
  });

  InterventionProgress copyWith({
    int? totalSessions,
    int? spellingScore,
    int? spellingTotal,
    int? typingWpm,
    int? practiceWpm,
  }) =>
      InterventionProgress(
        totalSessions: totalSessions ?? this.totalSessions,
        spellingScore: spellingScore ?? this.spellingScore,
        spellingTotal: spellingTotal ?? this.spellingTotal,
        typingWpm: typingWpm ?? this.typingWpm,
        practiceWpm: practiceWpm ?? this.practiceWpm,
      );

  double get spellingAverage =>
      spellingTotal > 0 ? (spellingScore / spellingTotal) * 100 : 0;

  Map<String, dynamic> toJson() => {
        'totalSessions': totalSessions,
        'spellingScore': spellingScore,
        'spellingTotal': spellingTotal,
        'typingWpm': typingWpm,
        'practiceWpm': practiceWpm,
      };

  factory InterventionProgress.fromJson(Map<String, dynamic> j) =>
      InterventionProgress(
        totalSessions: (j['totalSessions'] as num?)?.toInt() ?? 0,
        spellingScore: (j['spellingScore'] as num?)?.toInt() ?? 0,
        spellingTotal: (j['spellingTotal'] as num?)?.toInt() ?? 0,
        typingWpm: (j['typingWpm'] as num?)?.toInt() ?? 0,
        practiceWpm: (j['practiceWpm'] as num?)?.toInt() ?? 0,
      );
}

class InterventionNotifier extends StateNotifier<InterventionProgress> {
  InterventionNotifier() : super(const InterventionProgress()) {
    _load();
  }

  static const _key = 'umira_intervention_progress';

  Future<void> _load() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_key);
    if (raw != null) {
      try {
        state = InterventionProgress.fromJson(
            jsonDecode(raw) as Map<String, dynamic>,);
      } catch (_) {}
    }
  }

  Future<void> _save() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key, jsonEncode(state.toJson()));
  }

  Future<void> recordSpellingResult(int score, int total) async {
    state = state.copyWith(
      totalSessions: state.totalSessions + 1,
      spellingScore: state.spellingScore + score,
      spellingTotal: state.spellingTotal + total,
    );
    await _save();
  }

  Future<void> recordTypingResult(int wpm) async {
    state = state.copyWith(
      totalSessions: state.totalSessions + 1,
      typingWpm: wpm,
    );
    await _save();
  }

  Future<void> recordPracticeResult(int wpm) async {
    state = state.copyWith(
      totalSessions: state.totalSessions + 1,
      practiceWpm: wpm,
    );
    await _save();
  }

  Future<void> recordLesson() async {
    state = state.copyWith(totalSessions: state.totalSessions + 1);
    await _save();
  }
}

final interventionProgressProvider =
    StateNotifierProvider<InterventionNotifier, InterventionProgress>(
        (_) => InterventionNotifier(),);

final interventionSessionsProvider =
    FutureProvider.autoDispose<List<InterventionSession>>((ref) async {
  return ref.watch(interventionRepoProvider).listSessions();
});
