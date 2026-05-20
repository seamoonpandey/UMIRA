import 'package:flutter_test/flutter_test.dart';
import 'package:umira/features/preferences/models/preferences_models.dart';

void main() {
  group('LocalPrefs', () {
    test('default constructor uses sensible defaults', () {
      const prefs = LocalPrefs();
      expect(prefs.fontScale, 1.0);
      expect(prefs.useDyslexiaFont, false);
      expect(prefs.reducedMotion, false);
      expect(prefs.spacingMode, 'normal');
      expect(prefs.sessionLengthDefault, 15);
      expect(prefs.ttsRate, 1.0);
      expect(prefs.ttsPitch, 1.0);
    });

    test('copyWith overrides only specified fields', () {
      const prefs = LocalPrefs(fontScale: 1.2, useDyslexiaFont: true);
      final modified = prefs.copyWith(spacingMode: 'wide');
      expect(modified.fontScale, 1.2);
      expect(modified.useDyslexiaFont, true);
      expect(modified.spacingMode, 'wide');
      expect(modified.reducedMotion, false);
      expect(modified.sessionLengthDefault, 15);
    });

    test('toJson and fromJson round-trip', () {
      const prefs = LocalPrefs(
        fontScale: 1.5,
        useDyslexiaFont: true,
        reducedMotion: true,
        spacingMode: 'wide',
        sessionLengthDefault: 25,
        ttsRate: 0.8,
        ttsPitch: 1.2,
      );
      final json = prefs.toJson();
      final restored = LocalPrefs.fromJson(json);
      expect(restored.fontScale, 1.5);
      expect(restored.useDyslexiaFont, true);
      expect(restored.reducedMotion, true);
      expect(restored.spacingMode, 'wide');
      expect(restored.sessionLengthDefault, 25);
      expect(restored.ttsRate, 0.8);
      expect(restored.ttsPitch, 1.2);
    });

    test('fromJson handles missing fields gracefully', () {
      final prefs = LocalPrefs.fromJson({});
      expect(prefs.fontScale, 1.0);
      expect(prefs.useDyslexiaFont, false);
      expect(prefs.sessionLengthDefault, 15);
    });
  });
}
