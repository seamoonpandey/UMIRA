// UMIRA — Environment Configuration
// Reads compile-time `--dart-define` values passed during build.
// Defaults to development values when nothing is passed.
//
// Usage:
//   flutter build web --dart-define=ENVIRONMENT=production
//                      --dart-define=UMIRA_API_URL=https://api.umira.app/v1
//                      --dart-define=SENTRY_DSN=https://xxx@o123.ingest.sentry.io/123

import 'package:flutter/foundation.dart';

const _kDefaultApiUrl = String.fromEnvironment(
  'UMIRA_API_URL',
  defaultValue: 'http://10.0.2.2:4000/v1',
);

const _kDefaultSentryDsn = String.fromEnvironment(
  'SENTRY_DSN',
  defaultValue: '',
);

/// Active environment name: development | staging | production
const String environment = String.fromEnvironment(
  'ENVIRONMENT',
  defaultValue: 'development',
);

/// Whether this is a production build
bool get isProduction => environment == 'production';

/// Whether this is a staging build
bool get isStaging => environment == 'staging';

/// Whether this is a development build
bool get isDevelopment => environment == 'development' || kDebugMode;

/// Base URL for the UMIRA API
String get apiUrl => _kDefaultApiUrl;

/// Sentry DSN — empty string disables Sentry
String get sentryDsn => _kDefaultSentryDsn;

/// Sentry environment tag
String get sentryEnvironment {
  if (isProduction) return 'production';
  if (isStaging) return 'staging';
  return 'development';
}

/// Human-readable display name for the current environment
String get environmentLabel {
  if (isProduction) return 'Production';
  if (isStaging) return 'Staging';
  return 'Development';
}
