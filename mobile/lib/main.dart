import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/config/sentry_config.dart';
import 'core/network/api_client.dart';
import 'core/network/env_api_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise crash reporting (no-op if SENTRY_DSN is empty)
  await initSentry();

  // Create ApiClient with env-aware base URL and add Sentry interceptor
  final apiClient = createEnvApiClient();
  addSentryToDio(apiClient);

  runApp(
    ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(apiClient),
      ],
      child: const UmiraApp(),
    ),
  );
}
