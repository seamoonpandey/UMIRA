import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/umira_card.dart';
import '../providers/analytics_provider.dart';

class AnalyticsView extends ConsumerWidget {
  const AnalyticsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(analyticsSummaryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Your insights (last 30 days)')),
      body: s.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load insights: $e')),
        data: (data) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _stat(context, 'Tasks created', '${data['tasks_created'] ?? 0}'),
            _stat(context, 'Steps completed', '${data['microtasks_done'] ?? 0}'),
            _stat(context, 'Focus sessions', '${data['focus_completed'] ?? 0}'),
            _stat(context, 'Focused minutes', '${data['focus_total_minutes'] ?? 0}'),
            _stat(context, 'Reading sessions', '${data['reading_sessions'] ?? 0}'),
            const SizedBox(height: 16),
            UmiraCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Time estimation', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('Avg planned: ${(data['estimation_accuracy']?['avg_planned_minutes'] ?? 0)} min'),
                  Text('Avg actual:  ${(data['estimation_accuracy']?['avg_actual_minutes'] ?? 0)} min'),
                  const SizedBox(height: 8),
                  const Text('This is a personal trend, not a judgement.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(BuildContext context, String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: UmiraCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: Theme.of(context).textTheme.titleMedium),
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
      );
}
