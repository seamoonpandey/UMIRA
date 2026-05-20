import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:umira/features/preferences/providers/preferences_provider.dart';

void main() {
  group('LocalPrefsNotifier', () {
    test('starts with default LocalPrefs when no stored prefs', () {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final prefs = container.read(localPrefsProvider);
      expect(prefs.fontScale, 1.0);
      expect(prefs.useDyslexiaFont, false);
      expect(prefs.reducedMotion, false);
      expect(prefs.spacingMode, 'normal');
      expect(prefs.sessionLengthDefault, 15);
    });

    test('update modifies state and persists', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(localPrefsProvider.notifier);
      await notifier.update((p) => p.copyWith(fontScale: 1.5));
      expect(container.read(localPrefsProvider).fontScale, 1.5);
      expect(container.read(localPrefsProvider).useDyslexiaFont, false);

      // Second update preserves first
      await notifier.update((p) => p.copyWith(useDyslexiaFont: true));
      expect(container.read(localPrefsProvider).fontScale, 1.5);
      expect(container.read(localPrefsProvider).useDyslexiaFont, true);
    });

    test('update persists to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final sp = await SharedPreferences.getInstance();
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(localPrefsProvider.notifier);
      await notifier.update((p) => p.copyWith(spacingMode: 'wide', sessionLengthDefault: 30));

      final stored = sp.getString('umira_local_prefs');
      expect(stored, isNotNull);
      expect(stored, contains('"spacingMode":"wide"'));
      expect(stored, contains('"sessionLengthDefault":30'));
    });

    test('loads persisted prefs on initialization', () async {
      SharedPreferences.setMockInitialValues({
        'umira_local_prefs': '{"fontScale":1.5,"useDyslexiaFont":true,"reducedMotion":false,"spacingMode":"wide","sessionLengthDefault":25,"ttsRate":1.0,"ttsPitch":1.0}',
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Read first to trigger lazy creation of LocalPrefsNotifier + async _load()
      container.read(localPrefsProvider);
      // Pump several microtasks to let _load() complete
      await Future.microtask(() {});
      await Future.microtask(() {});

      final prefs = container.read(localPrefsProvider);
      expect(prefs.fontScale, 1.5);
      expect(prefs.useDyslexiaFont, true);
      expect(prefs.spacingMode, 'wide');
      expect(prefs.sessionLengthDefault, 25);
    });
  });
}
