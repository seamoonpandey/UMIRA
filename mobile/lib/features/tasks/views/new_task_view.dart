import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/umira_button.dart';
import '../../../shared/widgets/umira_text_field.dart';
import '../data/tasks_repository.dart';
import '../providers/tasks_provider.dart';

class NewTaskView extends ConsumerStatefulWidget {
  const NewTaskView({super.key});
  @override
  ConsumerState<NewTaskView> createState() => _NewTaskViewState();
}

class _NewTaskViewState extends ConsumerState<NewTaskView> {
  final _title = TextEditingController();
  final _goal = TextEditingController();
  bool _extraSimplify = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _goal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New task')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              UmiraTextField(controller: _title, label: 'Task title (short)'),
              const SizedBox(height: 12),
              UmiraTextField(
                controller: _goal,
                label: 'Describe the goal (optional)',
                hint: 'e.g. Prepare weekly product update email and slides',
                maxLines: 4,
              ),
              SwitchListTile(
                title: const Text('Extra simplified steps'),
                value: _extraSimplify,
                onChanged: (v) => setState(() => _extraSimplify = v),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 16),
              UmiraButton(
                label: _busy ? 'Creating...' : 'Create + break into steps',
                primary: true,
                onPressed: _busy ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty) {
      setState(() => _error = 'Please add a short title.');
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      final repo = ref.read(tasksRepoProvider);
      final t = await repo.create(title: _title.text.trim());
      final goal = _goal.text.trim().isEmpty ? _title.text.trim() : _goal.text.trim();
      await repo.generateMicrotasks(t.id, goal: goal, extraSimplify: _extraSimplify);
      ref.invalidate(tasksListProvider);
      if (mounted) context.go('/tasks/${t.id}');
    } catch (e) {
      setState(() => _error = 'Could not create task: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
