import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/umira_card.dart';
import '../providers/tasks_provider.dart';

class TasksListView extends ConsumerWidget {
  const TasksListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Your tasks')),
      body: tasks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) => list.isEmpty
            ? const Center(child: Text('No tasks yet. Add one to begin.'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final t = list[i];
                  final done = t.microtasks.where((m) => m.status == 'done').length;
                  final total = t.microtasks.length;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: UmiraCard(
                      onTap: () => context.push('/tasks/${t.id}'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.title, style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: total == 0 ? 0 : done / total,
                            minHeight: 6,
                          ),
                          const SizedBox(height: 6),
                          Text('$done / $total steps - ${t.status}'),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/tasks/new'),
        icon: const Icon(Icons.add),
        label: const Text('New task'),
      ),
    );
  }
}
