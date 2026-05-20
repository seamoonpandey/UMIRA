class LocalPrefs {
  final double fontScale;
  final bool useDyslexiaFont;
  final bool reducedMotion;
  final String spacingMode;
  final double paragraphSpacing;
  final bool shortLineWidth;
  final bool chunkingEnabled;
  final String themeMode; // 'light' | 'warm' | 'dark'
  final int sessionLengthDefault;
  final double ttsRate;
  final double ttsPitch;

  const LocalPrefs({
    this.fontScale = 1.0,
    this.useDyslexiaFont = false,
    this.reducedMotion = false,
    this.spacingMode = 'normal',
    this.paragraphSpacing = 20.0,
    this.shortLineWidth = false,
    this.chunkingEnabled = true,
    this.themeMode = 'system',
    this.sessionLengthDefault = 15,
    this.ttsRate = 1.0,
    this.ttsPitch = 1.0,
  });

  LocalPrefs copyWith({
    double? fontScale,
    bool? useDyslexiaFont,
    bool? reducedMotion,
    String? spacingMode,
    double? paragraphSpacing,
    bool? shortLineWidth,
    bool? chunkingEnabled,
    String? themeMode,
    int? sessionLengthDefault,
    double? ttsRate,
    double? ttsPitch,
  }) =>
      LocalPrefs(
        fontScale: fontScale ?? this.fontScale,
        useDyslexiaFont: useDyslexiaFont ?? this.useDyslexiaFont,
        reducedMotion: reducedMotion ?? this.reducedMotion,
        spacingMode: spacingMode ?? this.spacingMode,
        paragraphSpacing: paragraphSpacing ?? this.paragraphSpacing,
        shortLineWidth: shortLineWidth ?? this.shortLineWidth,
        chunkingEnabled: chunkingEnabled ?? this.chunkingEnabled,
        themeMode: themeMode ?? this.themeMode,
        sessionLengthDefault: sessionLengthDefault ?? this.sessionLengthDefault,
        ttsRate: ttsRate ?? this.ttsRate,
        ttsPitch: ttsPitch ?? this.ttsPitch,
      );

  Map<String, dynamic> toJson() => {
        'fontScale': fontScale,
        'useDyslexiaFont': useDyslexiaFont,
        'reducedMotion': reducedMotion,
        'spacingMode': spacingMode,
        'paragraphSpacing': paragraphSpacing,
        'shortLineWidth': shortLineWidth,
        'chunkingEnabled': chunkingEnabled,
        'themeMode': themeMode,
        'sessionLengthDefault': sessionLengthDefault,
        'ttsRate': ttsRate,
        'ttsPitch': ttsPitch,
      };

  factory LocalPrefs.fromJson(Map<String, dynamic> j) => LocalPrefs(
        fontScale: (j['fontScale'] as num?)?.toDouble() ?? 1.0,
        useDyslexiaFont: j['useDyslexiaFont'] as bool? ?? false,
        reducedMotion: j['reducedMotion'] as bool? ?? false,
        spacingMode: j['spacingMode'] as String? ?? 'normal',
        paragraphSpacing: (j['paragraphSpacing'] as num?)?.toDouble() ?? 20.0,
        shortLineWidth: j['shortLineWidth'] as bool? ?? false,
        chunkingEnabled: j['chunkingEnabled'] as bool? ?? true,
        themeMode: j['themeMode'] as String? ?? 'system',
        sessionLengthDefault:
            (j['sessionLengthDefault'] as num?)?.toInt() ?? 15,
        ttsRate: (j['ttsRate'] as num?)?.toDouble() ?? 1.0,
        ttsPitch: (j['ttsPitch'] as num?)?.toDouble() ?? 1.0,
      );
}
