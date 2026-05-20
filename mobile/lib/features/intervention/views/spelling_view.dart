import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../shared/widgets/umira_card.dart';
import '../../../shared/widgets/umira_button.dart';
import '../../../shared/widgets/umira_text_field.dart';
import '../../preferences/providers/preferences_provider.dart';
import '../data/intervention_repository.dart';
import '../providers/intervention_provider.dart';

const _words = [
  'believe', 'receive', 'necessary', 'separate',
  'definitely', 'calendar', 'embarrass',
];

class SpellingView extends ConsumerStatefulWidget {
  const SpellingView({super.key});

  @override
  ConsumerState<SpellingView> createState() => _SpellingViewState();
}

class _SpellingViewState extends ConsumerState<SpellingView> {
  int _currentIndex = 0;
  final _controller = TextEditingController();
  String _feedback = '';
  int _score = 0;
  bool _completed = false;
  final _tts = FlutterTts();

  String get _currentWord => _words[_currentIndex];

  @override
  void initState() {
    super.initState();
    _playWord();
  }

  Future<void> _playWord() async {
    await _tts.setLanguage('en-US');
    await _tts.speak(_currentWord);
  }

  Future<void> _checkSpelling() async {
    if (_controller.text.trim().toLowerCase() == _currentWord.toLowerCase()) {
      setState(() {
        _feedback = 'Correct!';
        _score++;
      });
      await Future.delayed(const Duration(seconds: 1));
      _nextWord();
    } else {
      setState(() => _feedback = 'Try again');
      await _tts.speak('Try again');
    }
  }

  Future<void> _nextWord() async {
    if (_currentIndex < _words.length - 1) {
      setState(() {
        _currentIndex++;
        _controller.clear();
        _feedback = '';
      });
      _playWord();
    } else {
      setState(() => _completed = true);
      await ref.read(interventionRepoProvider).saveSession(
            type: 'spelling',
            score: _score,
            total: _words.length,
          );
      await ref
          .read(interventionProgressProvider.notifier)
          .recordSpellingResult(_score, _words.length);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
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
          title: const Text('Spelling Quiz'),
          leading:
              IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        ),
        body: Center(
          child: UmiraCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, size: 64, color: Colors.green),
                const SizedBox(height: 16),
                Text(
                  'Quiz Complete!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontFamily: useDyslexic ? 'Lexend' : null,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Score: $_score / ${_words.length}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontFamily: useDyslexic ? 'Lexend' : null,
                      ),
                ),
                const SizedBox(height: 20),
                UmiraButton(
                  label: 'Restart',
                  primary: true,
                  onPressed: () {
                    setState(() {
                      _completed = false;
                      _currentIndex = 0;
                      _score = 0;
                      _controller.clear();
                      _feedback = '';
                    });
                    _playWord();
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spelling Quiz'),
        leading:
            IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Word ${_currentIndex + 1} / ${_words.length}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontFamily: useDyslexic ? 'Lexend' : null,
                  ),
            ),
            const SizedBox(height: 20),
            UmiraButton(
              label: 'Hear Word Again',
              icon: Icons.volume_up,
              onPressed: _playWord,
            ),
            const SizedBox(height: 20),
            UmiraCard(
              child: Column(
                children: [
                  UmiraTextField(
                    controller: _controller,
                    label: 'Type the word...',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _feedback,
                    style: TextStyle(
                      fontSize: 18,
                      color: _feedback == 'Correct!' ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: UmiraButton(
                    label: 'Check',
                    primary: true,
                    onPressed: _checkSpelling,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: UmiraButton(
                    label: 'Skip',
                    onPressed: _nextWord,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
