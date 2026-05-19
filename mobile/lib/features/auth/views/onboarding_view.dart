import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/umira_button.dart';

class OnboardingView extends StatelessWidget {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text('Welcome to UMIRA',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 12),
              Text(
                'A calm workspace built around how you think.\n\n'
                '- Break tasks into tiny steps\n'
                '- Read with simplified text and read-aloud\n'
                '- Run short focus sessions\n'
                '- Adjust everything to fit you',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const Spacer(),
              UmiraButton(
                label: 'Create account',
                onPressed: () => context.go('/sign-up'),
                primary: true,
              ),
              const SizedBox(height: 12),
              UmiraButton(
                label: 'I already have an account',
                onPressed: () => context.go('/sign-in'),
              ),
              const SizedBox(height: 16),
              Text(
                'UMIRA is not a medical or diagnostic tool. '
                'It is an assistive productivity and reading-support app.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
