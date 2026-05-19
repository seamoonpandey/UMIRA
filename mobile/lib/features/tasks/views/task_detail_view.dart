import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/tasks_repository.dart';
import '../models/task_models.dart';
import '../providers/tasks_provider.dart';

class TaskDetailView extends ConsumerWidget {
  final String taskId;
  const TaskDetailView({super.key, required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final task = ref.watch(taskDetailProvider(taskId));
    return Scaffold(
      appBar: AppBar(title: const Text('Task')),
      body: task.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (t) =>
            t == null ? const Center(child: Text('Not found')) : _Body(task: t),
      ),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  final Task task;
  const _Body({required this.task});
  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  bool _busy = false;

  Future<void> _toggle(Microtask m) async {
    setState(() => _busy = true);
    try {
      final repo = ref.read(tasksRepoProvider);
      final next = m.status == 'done' ? 'pending' : 'done';
      await repo.updateMicrotask(m.id, status: next);
      ref.invalidate(taskDetailProvider(widget.task.id));
      ref.invalidate(tasksListProvider);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.task;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(t.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
            '${t.microtasks.where((m) => m.status == 'done').length} of ${t.microtasks.length} done',),
        const Divider(height: 32),
        ...t.microtasks.map((m) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Checkbox(
                  value: m.status == 'done',
                  onChanged: _busy ? null : (_) => _toggle(m),
                ),
                title: Text(
                  m.label,
                  style: m.status == 'done'
                      ? const TextStyle(decoration: TextDecoration.lineThrough)
                      : null,
                ),
                subtitle: Text('${m.estimatedMinutes} min'),
                trailing: m.status == 'pending'
                    ? IconButton(
                        icon: const Icon(Icons.play_arrow),
                        tooltip: 'Focus on this step',
                        onPressed: () => context.push('/focus', extra: {
                          'taskTitle': m.label,
                          'taskId': widget.task.id,
                        },),
                      )
                    : null,
              ),
            ),),
        const SizedBox(height: 24),
        FilledButton.icon(
          icon: const Icon(Icons.refresh),
          label: const Text('Regenerate steps'),
          onPressed: _busy
              ? null
              : () async {
                  setState(() => _busy = true);
                  try {
                    await ref
                        .read(tasksRepoProvider)
                        .generateMicrotasks(t.id, goal: t.title);
                    ref.invalidate(taskDetailProvider(t.id));
                  } finally {
                    if (mounted) setState(() => _busy = false);
                  }
                },
        ),
      ],
    );
  }
}
