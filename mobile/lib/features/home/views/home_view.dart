import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/umira_card.dart';
import '../../tasks/providers/tasks_provider.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksListProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('UMIRA'),
        actions: [
          IconButton(
            tooltip: 'Preferences',
            icon: const Icon(Icons.tune),
            onPressed: () => context.push('/preferences'),
          ),
          IconButton(
            tooltip: 'Insights',
            icon: const Icon(Icons.insights_outlined),
            onPressed: () => context.push('/analytics'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(tasksListProvider.future),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Your next best step',
                style: Theme.of(context).textTheme.titleMedium,),
            const SizedBox(height: 8),
            tasks.when(
              loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),),
              error: (e, _) => Text('Could not load tasks: $e'),
              data: (list) {
                final next = list
                    .expand(
                        (t) => t.microtasks.where((m) => m.status == 'pending'),)
                    .cast<dynamic>()
                    .firstOrNull;
                if (next == null) {
                  return UmiraCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                            'Nothing queued. Add something small to start.',),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add a task'),
                          onPressed: () => context.push('/tasks/new'),
                        ),
                      ],
                    ),
                  );
                }
                return UmiraCard(
                  onTap: () =>
                      context.push('/focus', extra: {'taskTitle': next.label}),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(next.label,
                          style: Theme.of(context).textTheme.titleLarge,),
                      const SizedBox(height: 8),
                      Text('Estimated ${next.estimatedMinutes} min',
                          style: Theme.of(context).textTheme.bodyMedium,),
                      const SizedBox(height: 16),
                      Row(children: [
                        FilledButton.icon(
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Start focus'),
                          onPressed: () => context
                              .push('/focus', extra: {'taskTitle': next.label}),
                        ),
                      ],),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            _quickActionsGrid(context),
            const SizedBox(height: 24),
            Text('Today', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            tasks.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (list) {
                if (list.isEmpty) return const Text('No tasks yet.');
                return Column(
                  children: list.take(5).map((t) {
                    final done =
                        t.microtasks.where((m) => m.status == 'done').length;
                    final total = t.microtasks.length;
                    return UmiraCard(
                      onTap: () => context.push('/tasks/${t.id}'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.title,
                              style: Theme.of(context).textTheme.titleMedium,),
                          const SizedBox(height: 4),
                          Text('$done / $total steps done'),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/tasks/new'),
        icon: const Icon(Icons.add),
        label: const Text('Add task'),
      ),
    );
  }

  Widget _quickActionsGrid(BuildContext context) {
    final actions = [
      _Action('Tasks', Icons.checklist, '/tasks'),
      _Action('Read', Icons.menu_book_outlined, '/reading'),
      _Action('Focus', Icons.timer_outlined, '/focus'),
      _Action('Intervene', Icons.interpreter_mode, '/intervention'),
      _Action('Insights', Icons.insights_outlined, '/analytics'),
      _Action('Settings', Icons.tune, '/preferences'),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.4,
      children: actions
          .map((a) => UmiraCard(
                onTap: () => context.push(a.route),
                child: Row(
                  children: [
                    Icon(a.icon, size: 28),
                    const SizedBox(width: 12),
                    Text(a.label,
                        style: Theme.of(context).textTheme.titleMedium,),
                  ],
                ),
              ),)
          .toList(),
    );
  }
}

class _Action {
  final String label;
  final IconData icon;
  final String route;
  _Action(this.label, this.icon, this.route);
}
