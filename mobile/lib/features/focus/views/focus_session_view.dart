import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/umira_button.dart';
import '../data/focus_repository.dart';
import '../models/focus_models.dart';

class FocusSessionView extends ConsumerStatefulWidget {
  final Map args;
  const FocusSessionView({super.key, required this.args});
  @override
  ConsumerState<FocusSessionView> createState() => _FocusSessionViewState();
}

class _FocusSessionViewState extends ConsumerState<FocusSessionView> {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  bool _paused = false;
  bool _completed = false;
  FocusSession? _session;
  String? _reflection;
  int _distractions = 0;

  int get _plannedMinutes => (widget.args['minutes'] as int?) ?? 15;
  String? get _taskTitle => widget.args['taskTitle'] as String?;
  String? get _taskId => widget.args['taskId'] as String?;

  @override
  void initState() {
    super.initState();
    _remaining = Duration(minutes: _plannedMinutes);
    _start();
  }

  Future<void> _start() async {
    final repo = ref.read(focusRepoProvider);
    try {
      _session = await repo.start(taskId: _taskId, minutes: _plannedMinutes);
    } catch (_) {
      // continue offline; session can be saved when network returns
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_paused) return;
      setState(() {
        _remaining -= const Duration(seconds: 1);
        if (_remaining.inSeconds <= 0) {
          t.cancel();
          _complete();
        }
      });
    });
  }

  Future<void> _complete() async {
    if (_completed) return;
    setState(() => _completed = true);
    final used = _plannedMinutes - (_remaining.inSeconds / 60).floor();
    final repo = ref.read(focusRepoProvider);
    try {
      if (_session != null) {
        final res = await repo.complete(
          _session!.id,
          actualMinutes: used.clamp(0, _plannedMinutes),
          distractions: _distractions,
          aiReflection: true,
        );
        setState(() => _reflection = res['aiReflection'] as String?);
      }
    } catch (_) {/* swallow */}
  }

  Future<void> _cancelEarly() async {
    _timer?.cancel();
    if (_session != null) {
      try { await ref.read(focusRepoProvider).cancel(_session!.id); } catch (_) {}
    }
    if (mounted) context.pop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mm = _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    final progress = 1 - (_remaining.inSeconds / (_plannedMinutes * 60));
    return Scaffold(
      appBar: AppBar(title: Text(_taskTitle ?? 'Focus')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _completed
              ? _completionBody()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_taskTitle != null) ...[
                      Text(_taskTitle!, textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 24),
                    ],
                    SizedBox(
                      height: 220, width: 220,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox.expand(
                            child: CircularProgressIndicator(
                              value: progress.clamp(0, 1),
                              strokeWidth: 10,
                            ),
                          ),
                          Text('$mm:$ss', style: Theme.of(context).textTheme.displayMedium),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
                          label: Text(_paused ? 'Resume' : 'Pause'),
                          onPressed: () => setState(() => _paused = !_paused),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.notifications_off),
                          label: Text('Distraction (${_distractions})'),
                          onPressed: () => setState(() => _distractions++),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: _cancelEarly,
                      child: const Text('End session early'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _completionBody() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.check_circle_outline, size: 80),
        const SizedBox(height: 16),
        Text('Session complete', textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        if (_reflection != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_reflection!, style: Theme.of(context).textTheme.bodyLarge),
            ),
          ),
        const SizedBox(height: 24),
        UmiraButton(
          label: 'Back to home',
          primary: true,
          onPressed: () => context.go('/'),
        ),
      ],
    );
  }
}
