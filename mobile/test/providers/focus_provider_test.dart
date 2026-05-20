import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:umira/core/storage/secure_storage.dart';
import 'package:umira/features/focus/data/focus_repository.dart';
import 'package:umira/features/focus/providers/focus_provider.dart';

class _MockSecureStorage extends SecureStorage {
  @override
  Future<String?> readToken() async => null;
  @override
  Future<void> writeToken(String token) async {}
  @override
  Future<void> deleteToken() async {}
}

void main() {
  group('focusActionsProvider', () {
    test('provides a FocusRepository instance', () {
      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(_MockSecureStorage()),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(focusActionsProvider);
      expect(repo, isA<FocusRepository>());
    });
  });
}
