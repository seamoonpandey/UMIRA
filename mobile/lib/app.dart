import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/preferences/providers/preferences_provider.dart';

class UmiraApp extends ConsumerWidget {
  const UmiraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final prefs = ref.watch(localPrefsProvider);

    return MaterialApp.router(
      title: 'UMIRA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(prefs),
      darkTheme: AppTheme.dark(prefs),
      themeMode: ThemeMode.system,
      routerConfig: router,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(prefs.fontScale),
            boldText: false,
            disableAnimations: prefs.reducedMotion,
          ),
          child: child!,
        );
      },
    );
  }
}
