import '../config/env_config.dart';
import '../storage/secure_storage.dart';
import 'api_client.dart';

/// Creates an [ApiClient] with the base URL from environment configuration.
///
/// Uses [kApiUrl] which is configured via `--dart-define=UMIRA_API_URL=...`
/// during build, defaulting to the local dev URL.
ApiClient createEnvApiClient() {
  final storage = SecureStorage();
  final client = ApiClient(storage, baseUrl: apiUrl);
  return client;
}
