import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../shared/widgets/umira_card.dart';
import '../../../shared/widgets/umira_button.dart';
import '../../preferences/providers/preferences_provider.dart';
import '../data/intervention_repository.dart';
import '../providers/intervention_provider.dart';

class PhonicsLesson {
  final String grapheme;
  final String phoneme;
  final String example;

  PhonicsLesson({
    required this.grapheme,
    required this.phoneme,
    required this.example,
  });
}

final defaultLessons = [
  PhonicsLesson(grapheme: 'th', phoneme: 'ð', example: 'the, that'),
  PhonicsLesson(grapheme: 'oy', phoneme: 'ɔɪ', example: 'toy, boy'),
  PhonicsLesson(grapheme: 'e', phoneme: 'ɛ', example: 'tent, went'),
  PhonicsLesson(grapheme: 'o', phoneme: 'uː', example: 'do, to'),
  PhonicsLesson(grapheme: 'or', phoneme: 'ɔːr', example: 'more, store'),
  PhonicsLesson(grapheme: 'uy', phoneme: 'aɪ', example: 'guy, buy'),
  PhonicsLesson(grapheme: 'y', phoneme: 'i', example: 'sunny, candy'),
  PhonicsLesson(grapheme: 'sh', phoneme: 'ʃ', example: 'ship, shop'),
  PhonicsLesson(grapheme: 'ch', phoneme: 'tʃ', example: 'chip, chat'),
  PhonicsLesson(grapheme: 'ph', phoneme: 'f', example: 'phone, photo'),
];

class PhonicsLessonView extends ConsumerStatefulWidget {
  const PhonicsLessonView({super.key});

  @override
  ConsumerState<PhonicsLessonView> createState() => _PhonicsLessonViewState();
}

class _PhonicsLessonViewState extends ConsumerState<PhonicsLessonView> {
  int _currentIndex = 0;
  bool _showBack = false;
  final _tts = FlutterTts();

  PhonicsLesson get _currentLesson => defaultLessons[_currentIndex];

  Future<void> _playSound() async {
    await _tts.setLanguage('en-US');
    await _tts.speak(
      'The sound for ${_currentLesson.grapheme} is ${_currentLesson.phoneme}. Like in ${_currentLesson.example}',
    );
  }

  Future<void> _markLearned() async {
    ref.read(interventionRepoProvider).saveSession(
          type: 'lesson',
          grapheme: _currentLesson.grapheme,
          phoneme: _currentLesson.phoneme,
        );
    ref.read(interventionProgressProvider.notifier).recordLesson();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Marked '${_currentLesson.grapheme}' as learned!"),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(localPrefsProvider);
    final useDyslexic = prefs.useDyslexiaFont;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Phonics Lessons'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Card ${_currentIndex + 1} / ${defaultLessons.length}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontFamily: useDyslexic ? 'Lexend' : null,
                  ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _showBack = !_showBack),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _showBack ? _buildFront() : _buildBack(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton.filled(
                  icon: const Icon(Icons.volume_up),
                  onPressed: _playSound,
                  tooltip: 'Hear pronunciation',
                ),
                IconButton.filled(
                  icon: const Icon(Icons.check),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  onPressed: _markLearned,
                  tooltip: 'Mark learned',
                ),
              ],
            ),
            const SizedBox(height: 12),
            UmiraButton(
              label: 'Next Card',
              primary: true,
              onPressed: () {
                setState(() {
                  _showBack = false;
                  _currentIndex =
                      (_currentIndex + 1) % defaultLessons.length;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFront() {
    return UmiraCard(
      child: Container(
        height: 300,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _currentLesson.grapheme,
              style: TextStyle(
                fontSize: 80,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Tap to flip',
              style: TextStyle(
                color: Theme.of(context).disabledColor,
                fontFamily:
                    ref.watch(localPrefsProvider).useDyslexiaFont ? 'Lexend' : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBack() {
    final prefs = ref.watch(localPrefsProvider);
    final useDyslexic = prefs.useDyslexiaFont;

    return UmiraCard(
      child: Container(
        height: 300,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Sound:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '/${_currentLesson.phoneme}/',
              style: TextStyle(
                fontSize: 40,
                fontFamily: useDyslexic ? 'Lexend' : null,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _currentLesson.example,
              style: TextStyle(
                fontSize: 24,
                fontFamily: useDyslexic ? 'Lexend' : null,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Tap to flip back',
              style: TextStyle(
                color: Theme.of(context).disabledColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
