import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../preferences/models/preferences_models.dart';
import '../../preferences/providers/preferences_provider.dart';
import '../providers/reading_provider.dart';

class ReadingSessionView extends ConsumerStatefulWidget {
  final Map? payload;
  const ReadingSessionView({super.key, this.payload});
  @override
  ConsumerState<ReadingSessionView> createState() => _ReadingSessionViewState();
}

class _ReadingSessionViewState extends ConsumerState<ReadingSessionView>
    with SingleTickerProviderStateMixin {
  final _tts = FlutterTts();
  bool _speaking = false;
  int _currentChunk = 0;
  String _mode = 'side-by-side';
  bool _lineFocus = false;
  bool _showSettings = false;
  int _highlightedWordIndex = -1;
  final _pageController = PageController();
  late AnimationController _settingsAnimController;
  late Animation<double> _settingsAnimation;



  @override
  void initState() {
    super.initState();
    final prefs = ref.read(localPrefsProvider);
    _initTts(prefs);

    _settingsAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _settingsAnimation = CurvedAnimation(
      parent: _settingsAnimController,
      curve: Curves.easeInOut,
    );
  }

  void _initTts(LocalPrefs prefs) {
    _tts.setSpeechRate(prefs.ttsRate * 0.5);
    _tts.setPitch(prefs.ttsPitch);
    _tts.setLanguage('en-US');
    _tts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _speaking = false;
          _highlightedWordIndex = -1;
        });
      }
    });
    _tts.setProgressHandler((String text, int startOffset, int endOffset, String word) {
      if (mounted) {
        // Find which word index this character offset corresponds to
        final words = text.substring(0, startOffset).split(' ');
        final wordIndex = words.length - 1;
        setState(() {
          _highlightedWordIndex = wordIndex;
        });
      }
    });
  }

  @override
  void dispose() {
    _tts.stop();
    _pageController.dispose();
    _settingsAnimController.dispose();
    super.dispose();
  }

  void _toggleSettings() {
    setState(() => _showSettings = !_showSettings);
    if (_showSettings) {
      _settingsAnimController.forward();
    } else {
      _settingsAnimController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.payload?['text'] as String? ?? '';
    final level = widget.payload?['level'] as String? ?? 'medium';
    final result = ref.watch(
        simplifyProvider(SimplifyRequest.make(text: text, level: level)),);
    final prefs = ref.watch(localPrefsProvider);
    final notifier = ref.read(localPrefsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: Icon(_showSettings ? Icons.close : Icons.tune),
            onPressed: _toggleSettings,
          ),
          IconButton(
            tooltip: 'Line focus',
            icon: Icon(_lineFocus ? Icons.crop_din : Icons.crop_landscape),
            onPressed: () => setState(() => _lineFocus = !_lineFocus),
          ),
        ],
      ),
      body: result.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
              child: Text(
                  'Could not simplify: $e\n\nThe original text is preserved - switch to "Original" mode.',),),
        ),
        data: (data) {
          return Column(
            children: [
              // Animated Settings Panel
              SizeTransition(
                sizeFactor: _settingsAnimation,
                axisAlignment: -1.0,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _settingSlider(
                        context,
                        'Font size',
                        prefs.fontScale,
                        0.8, 1.6,
                        (v) => notifier.update((s) => s.copyWith(fontScale: v)),
                      ),
                      _settingSlider(
                        context,
                        'Line spacing',
                        prefs.spacingMode == 'normal'
                            ? 0
                            : prefs.spacingMode == 'wide'
                                ? 1
                                : 2,
                        0, 2,
                        (v) => notifier.update((s) => s.copyWith(
                            spacingMode:
                                v == 0 ? 'normal' : v == 1 ? 'wide' : 'extra-wide',),),
                      ),
                      Row(
                        children: [
                          const Text('Dyslexia font'),
                          const Spacer(),
                          Switch(
                            value: prefs.useDyslexiaFont,
                            onChanged: (v) => notifier
                                .update((s) => s.copyWith(useDyslexiaFont: v)),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Text('Short line width'),
                          const Spacer(),
                          Switch(
                            value: prefs.shortLineWidth,
                            onChanged: (v) => notifier
                                .update((s) => s.copyWith(shortLineWidth: v)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Mode selector
              Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 8,
                  children: ['original', 'simplified', 'side-by-side']
                      .map((m) => ChoiceChip(
                            label: Text(m),
                            selected: _mode == m,
                            onSelected: (_) =>
                                setState(() => _mode = m),
                          ),)
                      .toList(),
                ),
              ),
              // Quick summary if available
              if (data.summary.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quick summary',
                          style: Theme.of(context).textTheme.titleSmall,),
                      const SizedBox(height: 6),
                      Text(data.summary),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              // Progress counter
              Text(
                'Chunk ${_currentChunk + 1} / ${data.chunks.length}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              // Content
              Expanded(
                child: data.chunks.isEmpty
                    ? const Center(child: Text('No content'))
                    : PageView.builder(
                        controller: _pageController,
                        onPageChanged: (i) {
                          setState(() => _currentChunk = i);
                          if (_speaking) {
                            _tts.stop();
                            setState(() => _speaking = false);
                          }
                        },
                        itemCount: data.chunks.length,
                        itemBuilder: (_, i) {
                          final c = data.chunks[i];
                          final isFocused = _lineFocus && i == _currentChunk;
                          final faded = _lineFocus && i != _currentChunk;

                          return SingleChildScrollView(
                            padding: EdgeInsets.symmetric(
                              horizontal: prefs.shortLineWidth ? 48 : 16,
                              vertical: 12,
                            ),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(bottom: 12),
                              constraints: prefs.shortLineWidth
                                  ? const BoxConstraints(maxWidth: 600)
                                  : null,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: isFocused
                                    ? Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        width: 2,)
                                    : null,
                              ),
                              child: Opacity(
                                opacity: faded ? 0.25 : 1.0,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: _renderChunk(
                                      c.original, c.simplified, prefs,),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              // Bottom controls
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      // Word-level highlight bar for current chunk
                      if (_speaking && data.chunks.isNotEmpty)
                        _wordHighlightBar(
                            data.chunks[_currentChunk].original, prefs,),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton.filled(
                            onPressed: () => _prevChunk(data.chunks.length),
                            icon: const Icon(Icons.skip_previous),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.icon(
                              icon: Icon(_speaking
                                  ? Icons.pause
                                  : Icons.play_arrow,),
                              label: Text(
                                  _speaking ? 'Pause' : 'Read aloud',),
                              onPressed: () => _toggleSpeak(
                                data.chunks.isEmpty
                                    ? ''
                                    : _readableText(
                                        data.chunks[_currentChunk].original,
                                        data.chunks[_currentChunk].simplified,),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            onPressed: () => _nextChunk(data.chunks.length),
                            icon: const Icon(Icons.skip_next),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _settingSlider(
    BuildContext context,
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Row(
      children: [
        SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 13))),
        Expanded(
          child: Slider(
            min: min,
            max: max,
            divisions: ((max - min) * 4).round(),
            value: value.clamp(min, max),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _wordHighlightBar(String text, LocalPrefs prefs) {
    final words = text.split(' ');
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: words.asMap().entries.map((entry) {
          final i = entry.key;
          final word = entry.value;
          final isHighlighted = _highlightedWordIndex >= 0 && i == _highlightedWordIndex;

          return GestureDetector(
            onTap: () {
              _tts.stop();
              _tts.speak(word);
              setState(() => _highlightedWordIndex = i);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isHighlighted
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                    : null,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                word,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                  color: isHighlighted
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                  fontFamily: prefs.useDyslexiaFont ? 'Lexend' : null,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _renderChunk(String original, String simplified, LocalPrefs prefs) {
    switch (_mode) {
      case 'original':
        return _buildBody(original, prefs);
      case 'simplified':
        return _buildBody(simplified, prefs);
      default:
        return LayoutBuilder(builder: (_, c) {
          final wide = c.maxWidth > 600;
          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildBody(original, prefs)),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildBody(simplified, prefs,
                      color: Theme.of(context).colorScheme.primary,),
                ),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBody(simplified, prefs,
                  color: Theme.of(context).colorScheme.primary,),
              const SizedBox(height: 6),
              _buildBody(original, prefs, style: Theme.of(context).textTheme.bodySmall),
            ],
          );
        },);
    }
  }

  Widget _buildBody(String text, LocalPrefs prefs, {Color? color, TextStyle? style}) {
    return Text(
      text,
      style: (style ?? Theme.of(context).textTheme.bodyLarge)?.copyWith(
        color: color,
        height: switch (prefs.spacingMode) {
          'wide' => 1.4,
          'extra-wide' => 1.7,
          _ => 1.2,
        },
        fontFamily: prefs.useDyslexiaFont ? 'Lexend' : null,
      ),
    );
  }

  String _readableText(String original, String simplified) {
    return _mode == 'original' ? original : simplified;
  }

  Future<void> _toggleSpeak(String text) async {
    if (_speaking) {
      await _tts.pause();
      setState(() => _speaking = false);
    } else {
      setState(() => _speaking = true);
      await _tts.speak(text);
    }
  }

  void _prevChunk(int total) {
    if (_currentChunk > 0) {
      _pageController.animateToPage(
        _currentChunk - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextChunk(int total) {
    if (_currentChunk < total - 1) {
      _pageController.animateToPage(
        _currentChunk + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
}
