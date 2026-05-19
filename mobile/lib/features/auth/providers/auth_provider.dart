import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/secure_storage.dart';
import '../data/auth_repository.dart';

class AuthState {
  final String? token;
  final String? email;
  const AuthState({this.token, this.email});
}

class AuthNotifier extends StateNotifier<AuthState> {
  final SecureStorage _storage;
  final AuthRepository _repo;
  AuthNotifier(this._storage, this._repo) : super(const AuthState()) {
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final t = await _storage.readToken();
    if (t != null) state = AuthState(token: t);
  }

  Future<void> signIn(String email, String password) async {
    final res = await _repo.signIn(email, password);
    final token = res['token'] as String;
    await _storage.writeToken(token);
    state = AuthState(token: token, email: email);
  }

  Future<void> signUp(String email, String password) async {
    final res = await _repo.signUp(email, password);
    final token = res['token'] as String;
    await _storage.writeToken(token);
    state = AuthState(token: token, email: email);
  }

  Future<void> signOut() async {
    await _storage.deleteToken();
    state = const AuthState();
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(secureStorageProvider), ref.watch(authRepoProvider));
});
