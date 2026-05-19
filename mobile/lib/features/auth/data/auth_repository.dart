import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

final authRepoProvider = Provider((ref) => AuthRepository(ref.watch(apiClientProvider)));

class AuthRepository {
  final ApiClient _api;
  AuthRepository(this._api);

  Future<Map<String, dynamic>> signUp(String email, String password) =>
      _api.postJson('/auth/signup', body: {'email': email, 'password': password});

  Future<Map<String, dynamic>> signIn(String email, String password) =>
      _api.postJson('/auth/signin', body: {'email': email, 'password': password});

  Future<Map<String, dynamic>> me() => _api.getJson('/me');
}
