import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:sentry_dio/sentry_dio.dart';
import '../network/api_client.dart';
import 'env_config.dart';

/// Whether Sentry has been initialized
bool _sentryInitialized = false;

/// Initialize Sentry crash reporting.
///
/// Must be called before `runApp()`. Returns `true` if Sentry was
/// initialized, `false` if skipped (no DSN or already initialized).
Future<bool> initSentry() async {
  if (_sentryInitialized) return false;
  if (sentryDsn.isEmpty) {
    debugPrint('[sentry] Skipping — SENTRY_DSN not configured');
    return false;
  }

  await SentryFlutter.init(
    (options) {
      options.dsn = sentryDsn;
      options.environment = sentryEnvironment;
      options.tracesSampleRate = isProduction ? 0.1 : 1.0;
      options.debug = !isProduction;
      options.reportPackages = false;
      options.attachScreenshot = !kIsWeb;
      // ignore: experimental_member_use
      options.attachViewHierarchy = !kIsWeb;
    },
    appRunner: () {}, // actual app runner is called separately
  );

  _sentryInitialized = true;
  debugPrint('[sentry] Initialized (env: $sentryEnvironment)');
  return true;
}

/// Add the Sentry Dio interceptor to an existing `ApiClient`.
/// Must be called after `initSentry()`.
void addSentryToDio(ApiClient client) {
  if (!_sentryInitialized) return;
  client.dio.addSentry();
  debugPrint('[sentry] Dio interceptor added');
}
