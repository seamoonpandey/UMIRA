class LocalPrefs {
  final double fontScale;
  final bool useDyslexiaFont;
  final bool reducedMotion;
  final String spacingMode;
  final int sessionLengthDefault;
  final double ttsRate;
  final double ttsPitch;

  const LocalPrefs({
    this.fontScale = 1.0,
    this.useDyslexiaFont = false,
    this.reducedMotion = false,
    this.spacingMode = 'normal',
    this.sessionLengthDefault = 15,
    this.ttsRate = 1.0,
    this.ttsPitch = 1.0,
  });

  LocalPrefs copyWith({
    double? fontScale,
    bool? useDyslexiaFont,
    bool? reducedMotion,
    String? spacingMode,
    int? sessionLengthDefault,
    double? ttsRate,
    double? ttsPitch,
  }) =>
      LocalPrefs(
        fontScale: fontScale ?? this.fontScale,
        useDyslexiaFont: useDyslexiaFont ?? this.useDyslexiaFont,
        reducedMotion: reducedMotion ?? this.reducedMotion,
        spacingMode: spacingMode ?? this.spacingMode,
        sessionLengthDefault: sessionLengthDefault ?? this.sessionLengthDefault,
        ttsRate: ttsRate ?? this.ttsRate,
        ttsPitch: ttsPitch ?? this.ttsPitch,
      );

  Map<String, dynamic> toJson() => {
        'fontScale': fontScale,
        'useDyslexiaFont': useDyslexiaFont,
        'reducedMotion': reducedMotion,
        'spacingMode': spacingMode,
        'sessionLengthDefault': sessionLengthDefault,
        'ttsRate': ttsRate,
        'ttsPitch': ttsPitch,
      };

  factory LocalPrefs.fromJson(Map<String, dynamic> j) => LocalPrefs(
        fontScale: (j['fontScale'] as num?)?.toDouble() ?? 1.0,
        useDyslexiaFont: j['useDyslexiaFont'] as bool? ?? false,
        reducedMotion: j['reducedMotion'] as bool? ?? false,
        spacingMode: j['spacingMode'] as String? ?? 'normal',
        sessionLengthDefault: (j['sessionLengthDefault'] as num?)?.toInt() ?? 15,
        ttsRate: (j['ttsRate'] as num?)?.toDouble() ?? 1.0,
        ttsPitch: (j['ttsPitch'] as num?)?.toDouble() ?? 1.0,
      );
}
