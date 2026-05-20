import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../../../shared/widgets/umira_card.dart';
import '../../../shared/widgets/umira_button.dart';
import '../../preferences/providers/preferences_provider.dart';
import '../data/intervention_repository.dart';
import '../models/intervention_models.dart';
import '../providers/intervention_provider.dart';

class PracticeView extends ConsumerStatefulWidget {
  const PracticeView({super.key});

  @override
  ConsumerState<PracticeView> createState() => _PracticeViewState();
}

class _PracticeViewState extends ConsumerState<PracticeView> {
  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _isProcessing = false;
  bool _hasPermission = false;
  PracticeResult? _result;

  static const String _targetText =
      'The boy went to the store to buy some candy.';

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.microphone.status;
    if (mounted) {
      setState(() => _hasPermission = status.isGranted);
    }
  }

  Future<void> _requestPermission() async {
    final status = await Permission.microphone.request();
    if (mounted) {
      setState(() => _hasPermission = status.isGranted);
      if (status.isGranted) {
        _startRecording();
      } else {
        _showPermissionDenied();
      }
    }
  }

  void _showPermissionDenied() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Microphone Access Needed'),
        content: const Text(
          'UMIRA needs microphone access to analyze your reading. '
          'Please enable it in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _startRecording() async {
    if (!_hasPermission) {
      await _requestPermission();
      return;
    }

    try {
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/practice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: path,
      );

      if (mounted) {
        setState(() {
          _isRecording = true;
          _result = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start recording: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();

      if (path == null || !File(path).existsSync()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recording failed — no audio file')),
          );
        }
        return;
      }

      if (mounted) {
        setState(() {
          _isRecording = false;
          _isProcessing = true;
        });
      }

      await _analyzeRecording(path);
    } catch (e) {
      if (mounted) {
        setState(() => _isRecording = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to stop recording: $e')),
        );
      }
    }
  }

  Future<void> _analyzeRecording(String path) async {
    try {
      final repo = ref.read(interventionRepoProvider);
      final result = await repo.analyzePractice(
        path,
        expectedText: _targetText,
      );

      if (mounted) {
        setState(() {
          _result = result;
          _isProcessing = false;
        });

        // Save session
        repo.saveSession(
          type: 'practice',
          stats: {
            'wpm': result.stats.wpm,
            'skippedWords': result.stats.skippedWords,
            'repetitions': result.stats.repetitions,
            'wordData': result.wordData.map((w) => w.word).toList(),
          },
        );
        ref
            .read(interventionProgressProvider.notifier)
            .recordPracticeResult(result.stats.wpm);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analysis failed: $e'),
            action: SnackBarAction(
              label: 'Use Mock',
              onPressed: _mockAnalysis,
            ),
          ),
        );
      }
    }
  }

  Future<void> _mockAnalysis() async {
    setState(() => _isProcessing = true);

    await Future.delayed(const Duration(seconds: 2));

    final mockResult = PracticeResult(
      wordData: _targetText.split(' ').map((word) {
        final rand = word.length % 4;
        return WordResult(
          word: word.toLowerCase(),
          status: rand == 0
              ? 'skipped'
              : rand == 1
                  ? 'repetition'
                  : 'correct',
          skipped: rand == 0,
          repetition: rand == 1,
        );
      }).toList(),
      stats: PracticeStats(wpm: 85, skippedWords: 1, repetitions: 1),
    );

    if (mounted) {
      setState(() {
        _result = mockResult;
        _isProcessing = false;
      });

      ref.read(interventionRepoProvider).saveSession(
            type: 'practice',
            stats: {
              'wpm': mockResult.stats.wpm,
              'skippedWords': mockResult.stats.skippedWords,
              'repetitions': mockResult.stats.repetitions,
              'wordData': mockResult.wordData.map((w) => w.word).toList(),
            },
          );
      ref
          .read(interventionProgressProvider.notifier)
          .recordPracticeResult(mockResult.stats.wpm);
    }
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  Color _wordColor(String status) {
    switch (status) {
      case 'correct':
        return Colors.green;
      case 'skipped':
        return Colors.red;
      case 'repetition':
        return Colors.orange;
      case 'substitution':
        return Colors.purple;
      case 'insertion':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(localPrefsProvider);
    final useDyslexic = prefs.useDyslexiaFont;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading Practice'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Reading Practice',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontFamily: useDyslexic ? 'Lexend' : null,
                  fontWeight: useDyslexic ? FontWeight.normal : FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          UmiraCard(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                _targetText,
                style: TextStyle(
                  fontSize: 28,
                  height: 1.5,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontFamily: useDyslexic ? 'Lexend' : null,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Permission status indicator
          if (!_hasPermission && !_isRecording && _result == null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: UmiraCard(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.mic_off,
                          color: Theme.of(context).colorScheme.error, size: 20,),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Microphone access needed for recording',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Center(
            child: UmiraButton(
              label: _isRecording
                  ? 'Stop Recording'
                  : _isProcessing
                      ? 'Analyzing...'
                      : 'Start Recording',
              primary: true,
              icon: _isRecording ? Icons.stop : Icons.mic,
              onPressed: _isProcessing
                  ? null
                  : (_isRecording ? _stopRecording : _startRecording),
            ),
          ),
          if (!_hasPermission && !_isRecording && _result == null)
            const SizedBox(height: 8),
          if (!_hasPermission && !_isRecording && _result == null)
            TextButton.icon(
              onPressed: _mockAnalysis,
              icon: const Icon(Icons.developer_mode, size: 18),
              label: const Text('Use mock data instead'),
            ),
          if (_isRecording) ...[
            const SizedBox(height: 24),
            const Center(
              child: Column(
                children: [
                  Icon(Icons.record_voice_over, size: 48, color: Colors.red),
                  SizedBox(height: 12),
                  Text(
                    'Recording... Tap Stop when done',
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          ],
          if (_isProcessing) ...[
            const SizedBox(height: 24),
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Analyzing your speech...'),
                ],
              ),
            ),
          ],
          if (_result != null) ...[
            const SizedBox(height: 24),
            Text(
              'Feedback',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontFamily: useDyslexic ? 'Lexend' : null,
                  ),
            ),
            const SizedBox(height: 12),
            UmiraCard(
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _result!.wordData.map((w) {
                  return Text(
                    '${w.word} ',
                    style: TextStyle(
                      fontSize: 20,
                      color: _wordColor(w.status),
                      decoration: w.skipped
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      fontFamily: useDyslexic ? 'Lexend' : null,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'WPM',
                    value: '${_result!.stats.wpm}',
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    label: 'Skipped',
                    value: '${_result!.stats.skippedWords}',
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    label: 'Repetitions',
                    value: '${_result!.stats.repetitions}',
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: UmiraButton(
                label: 'Try Again',
                icon: Icons.refresh,
                onPressed: () {
                  setState(() {
                    _result = null;
                  });
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return UmiraCard(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
