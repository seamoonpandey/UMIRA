import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/umira_button.dart';
import '../../preferences/providers/preferences_provider.dart';

class FocusSetupView extends ConsumerStatefulWidget {
  const FocusSetupView({super.key});
  @override
  ConsumerState<FocusSetupView> createState() => _FocusSetupViewState();
}

class _FocusSetupViewState extends ConsumerState<FocusSetupView> {
  int _minutes = 15;

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(localPrefsProvider);
    _minutes = _minutes == 15 ? prefs.sessionLengthDefault : _minutes;
    return Scaffold(
      appBar: AppBar(title: const Text('Focus session')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Pick a session length',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [10, 15, 20, 25].map((m) => ChoiceChip(
                  label: Text('$m min'),
                  selected: _minutes == m,
                  onSelected: (_) => setState(() => _minutes = m),
                )).toList(),
              ),
              const SizedBox(height: 24),
              const Text('Optional pre-session ritual:\n- Close other apps\n- One glass of water\n- Set one tiny goal'),
              const Spacer(),
              UmiraButton(
                label: 'Start $_minutes-minute session',
                primary: true,
                icon: Icons.play_arrow,
                onPressed: () => context.push('/focus/run', extra: {
                  'minutes': _minutes,
                  'taskTitle': null,
                  'taskId': null,
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
