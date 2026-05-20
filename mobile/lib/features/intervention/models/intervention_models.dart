class WordResult {
  final String word;
  final String status; // 'correct', 'skipped', 'repetition', 'substitution', 'insertion'
  final double? pauseMs;
  final double? durationRatio;
  final bool skipped;
  final bool repetition;

  WordResult({
    required this.word,
    required this.status,
    this.pauseMs,
    this.durationRatio,
    this.skipped = false,
    this.repetition = false,
  });

  factory WordResult.fromJson(Map<String, dynamic> j) => WordResult(
        word: j['word'] as String? ?? '',
        status: j['status'] as String? ?? 'correct',
        pauseMs: (j['pauseMs'] as num?)?.toDouble(),
        durationRatio: (j['durationRatio'] as num?)?.toDouble(),
        skipped: j['skipped'] as bool? ?? false,
        repetition: j['repetition'] as bool? ?? false,
      );
}

class PracticeStats {
  final int wpm;
  final int skippedWords;
  final int repetitions;

  PracticeStats({
    required this.wpm,
    required this.skippedWords,
    required this.repetitions,
  });

  factory PracticeStats.fromJson(Map<String, dynamic> j) => PracticeStats(
        wpm: (j['wpm'] as num?)?.toInt() ?? 0,
        skippedWords: (j['skippedWords'] as num?)?.toInt() ?? 0,
        repetitions: (j['repetitions'] as num?)?.toInt() ?? 0,
      );
}

class InterventionSession {
  final String id;
  final String type; // spelling, typing, lesson, practice
  final String date;
  final int? score;
  final int? total;
  final int? wpm;
  final int? accuracy;
  final String? grapheme;

  InterventionSession({
    required this.id,
    required this.type,
    required this.date,
    this.score,
    this.total,
    this.wpm,
    this.accuracy,
    this.grapheme,
  });

  factory InterventionSession.fromJson(Map<String, dynamic> j) =>
      InterventionSession(
        id: j['id'] as String? ?? '',
        type: j['type'] as String? ?? '',
        date: j['date'] as String? ?? '',
        score: (j['score'] as num?)?.toInt(),
        total: (j['total'] as num?)?.toInt(),
        wpm: (j['wpm'] as num?)?.toInt(),
        accuracy: (j['accuracy'] as num?)?.toInt(),
        grapheme: j['grapheme'] as String?,
      );
}

class PracticeResult {
  final List<WordResult> wordData;
  final PracticeStats stats;

  PracticeResult({required this.wordData, required this.stats});

  factory PracticeResult.fromJson(Map<String, dynamic> j) => PracticeResult(
        wordData: ((j['wordData'] as List?) ?? [])
            .map((e) => WordResult.fromJson(e as Map<String, dynamic>))
            .toList(),
        stats: PracticeStats.fromJson(j['stats'] as Map<String, dynamic>? ?? {}),
      );
}
