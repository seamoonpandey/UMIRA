import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/umira_card.dart';
import '../../../shared/widgets/umira_button.dart';
import '../../preferences/providers/preferences_provider.dart';

const _targetText = 'The boy went to the store to buy some candy.';

class MaskingView extends ConsumerStatefulWidget {
  const MaskingView({super.key});

  @override
  ConsumerState<MaskingView> createState() => _MaskingViewState();
}

class _MaskingViewState extends ConsumerState<MaskingView> {
  int _currentIndex = 0;
  final _words = _targetText.split(' ');

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(localPrefsProvider);
    final useDyslexic = prefs.useDyslexiaFont;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Word Masking'),
        leading:
            IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Word Masking',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontFamily: useDyslexic ? 'Lexend' : null,
                    fontWeight: useDyslexic ? FontWeight.normal : FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Center(
                child: UmiraCard(
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 6,
                      children: _words.asMap().entries.map((entry) {
                        final index = entry.key;
                        final word = entry.value;
                        final isFocused = index == _currentIndex;

                        return Opacity(
                          opacity: isFocused ? 1.0 : 0.3,
                          child: Text(
                            word,
                            style: TextStyle(
                              fontSize: 32,
                              color: isFocused
                                  ? const Color(0xFFFF9800)
                                  : Colors.grey,
                              fontWeight:
                                  isFocused ? FontWeight.bold : FontWeight.normal,
                              fontFamily: useDyslexic ? 'Lexend' : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            UmiraButton(
              label: 'Next Word',
              primary: true,
              onPressed: () {
                setState(() {
                  _currentIndex = (_currentIndex + 1) % _words.length;
                });
              },
            ),
            const SizedBox(height: 12),
            Text(
              'Tap "Next Word" to move the focus.',
              style: TextStyle(
                color: Theme.of(context).disabledColor,
                fontFamily: useDyslexic ? 'Lexend' : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
