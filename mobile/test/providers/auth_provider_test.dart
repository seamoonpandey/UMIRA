import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:umira/core/network/api_client.dart';
import 'package:umira/core/storage/secure_storage.dart';
import 'package:umira/features/auth/data/auth_repository.dart';
import 'package:umira/features/auth/providers/auth_provider.dart';

/// In-memory SecureStorage that doesn't use platform channels.
class MockSecureStorage extends SecureStorage {
  String? _token;

  @override
  Future<String?> readToken() async => _token;

  @override
  Future<void> writeToken(String token) async => _token = token;

  @override
  Future<void> deleteToken() async => _token = null;
}

/// ApiClient that doesn't make real HTTP requests.
class MockApiClient extends ApiClient {
  MockApiClient() : super(MockSecureStorage());

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body,}) async {
    final b = body as Map<String, dynamic>?;
    if (path == '/auth/signup') {
      return {'token': 'mock-token-${b?['email']}'};
    }
    if (path == '/auth/signin') {
      return {'token': 'mock-token-${b?['email']}'};
    }
    return {};
  }

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    return {};
  }
}

/// AuthRepository backed by MockApiClient — no platform channels needed.
AuthRepository makeMockAuthRepo() => AuthRepository(MockApiClient());

void main() {
  late MockSecureStorage storage;
  late ProviderContainer container;

  setUp(() {
    storage = MockSecureStorage();
    final mockRepo = makeMockAuthRepo();
    container = ProviderContainer(
      overrides: [
        secureStorageProvider.overrideWithValue(storage),
        authRepoProvider.overrideWithValue(mockRepo),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('AuthNotifier', () {
    test('starts with no token and no email', () {
      final state = container.read(authStateProvider);
      expect(state.token, isNull);
      expect(state.email, isNull);
    });

    test('signUp sets token and email', () async {
      final notifier = container.read(authStateProvider.notifier);
      await notifier.signUp('alice@example.com', 'secret123');

      final state = container.read(authStateProvider);
      expect(state.token, 'mock-token-alice@example.com');
      expect(state.email, 'alice@example.com');

      final stored = await storage.readToken();
      expect(stored, 'mock-token-alice@example.com');
    });

    test('signOut clears token and storage', () async {
      final notifier = container.read(authStateProvider.notifier);
      await notifier.signUp('carol@example.com', 'secret');

      expect(container.read(authStateProvider).token, isNotNull);
      await notifier.signOut();

      final state = container.read(authStateProvider);
      expect(state.token, isNull);
      expect(state.email, isNull);

      final stored = await storage.readToken();
      expect(stored, isNull);
    });

    test('loads persisted token from storage on init', () async {
      // Pre-write a token to storage
      await storage.writeToken('stored-token');
      container.dispose();

      // Fresh container should load the token
      container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(storage),
          authRepoProvider.overrideWithValue(makeMockAuthRepo()),
        ],
      );

      // Read first to trigger lazy creation + async _bootstrap()
      container.read(authStateProvider);
      await Future.microtask(() {});
      await Future.microtask(() {});

      final state = container.read(authStateProvider);
      expect(state.token, 'stored-token');
    });
  });
}
