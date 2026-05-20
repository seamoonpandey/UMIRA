import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../shared/widgets/umira_card.dart';
import '../../../shared/widgets/umira_button.dart';
import '../../preferences/providers/preferences_provider.dart';
import '../data/intervention_repository.dart';
import '../providers/intervention_provider.dart';

const _sentences = [
  'The quick brown fox jumps over the lazy dog.',
  'Dyslexia is a learning difference not a disability.',
  'Practice makes progress perfect over time.',
];

class TypingView extends ConsumerStatefulWidget {
  const TypingView({super.key});

  @override
  ConsumerState<TypingView> createState() => _TypingViewState();
}

class _TypingViewState extends ConsumerState<TypingView> {
  int _currentIndex = 0;
  final _controller = TextEditingController();
  DateTime? _startTime;
  bool _completed = false;
  int _wpm = 0;
  int _accuracy = 0;
  final _tts = FlutterTts();
  final _focusNode = FocusNode();

  String get _targetText => _sentences[_currentIndex];

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  void _onTextChanged(String text) {
    if (_startTime == null && text.isNotEmpty) {
      _startTime = DateTime.now();
    }
  }

  void _calculateStats() {
    if (_startTime == null) return;
    final endTime = DateTime.now();
    final durationMinutes = endTime.difference(_startTime!).inMilliseconds / 60000;
    final words = _controller.text.length / 5;
    final calcWpm = durationMinutes > 0 ? (words / durationMinutes).round() : 0;

    // Character-level accuracy
    int matches = 0;
    for (int i = 0; i < _controller.text.length && i < _targetText.length; i++) {
      if (_controller.text[i] == _targetText[i]) matches++;
    }
    final calcAccuracy =
        _targetText.isNotEmpty ? ((matches / _targetText.length) * 100).round() : 0;

    setState(() {
      _wpm = calcWpm;
      _accuracy = calcAccuracy;
      _completed = true;
    });

    ref.read(interventionRepoProvider).saveSession(
          type: 'typing',
          wpm: calcWpm,
          accuracy: calcAccuracy,
        );
    ref.read(interventionProgressProvider.notifier).recordTypingResult(calcWpm);

    _tts.speak('You typed: ${_controller.text}');
  }

  void _nextSentence() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % _sentences.length;
      _controller.clear();
      _startTime = null;
      _completed = false;
      _wpm = 0;
      _accuracy = 0;
    });
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(localPrefsProvider);
    final useDyslexic = prefs.useDyslexiaFont;

    if (_completed) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Typing Practice'),
          leading:
              IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        ),
        body: Center(
          child: UmiraCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Results',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontFamily: useDyslexic ? 'Lexend' : null,
                      ),
                ),
                const SizedBox(height: 20),
                Text(
                  'WPM: $_wpm',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontFamily: useDyslexic ? 'Lexend' : null,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Accuracy: $_accuracy%',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontFamily: useDyslexic ? 'Lexend' : null,
                      ),
                ),
                const SizedBox(height: 24),
                UmiraButton(
                  label: 'Next Sentence',
                  primary: true,
                  onPressed: _nextSentence,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Typing Practice'),
        leading:
            IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Type the following:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontFamily: useDyslexic ? 'Lexend' : null,
                  ),
            ),
            const SizedBox(height: 12),
            UmiraCard(
              child: Text(
                _targetText,
                style: TextStyle(
                  fontSize: 24,
                  height: 1.4,
                  fontFamily: useDyslexic ? 'Lexend' : null,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                onChanged: _onTextChanged,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: TextStyle(
                  fontSize: 20,
                  fontFamily: useDyslexic ? 'Lexend' : null,
                ),
                decoration: InputDecoration(
                  hintText: 'Start typing...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 20),
            UmiraButton(
              label: 'Done',
              primary: true,
              onPressed: _calculateStats,
            ),
          ],
        ),
      ),
    );
  }
}
