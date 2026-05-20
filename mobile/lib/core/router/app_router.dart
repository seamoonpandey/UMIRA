import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/views/onboarding_view.dart';
import '../../features/auth/views/sign_in_view.dart';
import '../../features/auth/views/sign_up_view.dart';
import '../../features/home/views/home_view.dart';
import '../../features/tasks/views/tasks_list_view.dart';
import '../../features/tasks/views/task_detail_view.dart';
import '../../features/tasks/views/new_task_view.dart';
import '../../features/reading/views/reading_input_view.dart';
import '../../features/reading/views/reading_session_view.dart';
import '../../features/focus/views/focus_setup_view.dart';
import '../../features/focus/views/focus_session_view.dart';
import '../../features/preferences/views/preferences_view.dart';
import '../../features/analytics/views/analytics_view.dart';
import '../../features/intervention/views/intervention_hub_view.dart';
import '../../features/intervention/views/practice_view.dart';
import '../../features/intervention/views/phonics_lesson_view.dart';
import '../../features/intervention/views/spelling_view.dart';
import '../../features/intervention/views/typing_view.dart';
import '../../features/intervention/views/masking_view.dart';
import '../../features/intervention/views/ocr_scan_view.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authStateProvider);
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final loggedIn = auth.token != null;
      final goingToAuth = state.matchedLocation == '/sign-in' ||
          state.matchedLocation == '/sign-up' ||
          state.matchedLocation == '/onboarding';
      if (!loggedIn && !goingToAuth) return '/onboarding';
      if (loggedIn && goingToAuth) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingView()),
      GoRoute(path: '/sign-in', builder: (_, __) => const SignInView()),
      GoRoute(path: '/sign-up', builder: (_, __) => const SignUpView()),
      GoRoute(path: '/', builder: (_, __) => const HomeView()),
      GoRoute(path: '/tasks', builder: (_, __) => const TasksListView()),
      GoRoute(path: '/tasks/new', builder: (_, __) => const NewTaskView()),
      GoRoute(
        path: '/tasks/:id',
        builder: (_, state) =>
            TaskDetailView(taskId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/reading', builder: (_, __) => const ReadingInputView()),
      GoRoute(
        path: '/reading/session',
        builder: (_, state) => ReadingSessionView(payload: state.extra as Map?),
      ),
      GoRoute(path: '/focus', builder: (_, __) => const FocusSetupView()),
      GoRoute(
        path: '/focus/run',
        builder: (_, state) => FocusSessionView(args: state.extra as Map),
      ),
      GoRoute(
          path: '/preferences', builder: (_, __) => const PreferencesView(),),
      GoRoute(path: '/analytics', builder: (_, __) => const AnalyticsView()),
      GoRoute(
          path: '/intervention', builder: (_, __) => const InterventionHubView(),),
      GoRoute(
          path: '/intervention/practice',
          builder: (_, __) => const PracticeView(),),
      GoRoute(
          path: '/intervention/lesson',
          builder: (_, __) => const PhonicsLessonView(),),
      GoRoute(
          path: '/intervention/spelling',
          builder: (_, __) => const SpellingView(),),
      GoRoute(
          path: '/intervention/typing',
          builder: (_, __) => const TypingView(),),
      GoRoute(
          path: '/intervention/masking',
          builder: (_, __) => const MaskingView(),),
      GoRoute(
          path: '/intervention/scan',
          builder: (_, __) => const OcrScanView(),),
    ],
  );
});
