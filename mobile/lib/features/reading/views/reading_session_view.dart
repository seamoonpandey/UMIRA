import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../preferences/providers/preferences_provider.dart';
import '../providers/reading_provider.dart';

class ReadingSessionView extends ConsumerStatefulWidget {
  final Map? payload;
  const ReadingSessionView({super.key, this.payload});
  @override
  ConsumerState<ReadingSessionView> createState() => _ReadingSessionViewState();
}

class _ReadingSessionViewState extends ConsumerState<ReadingSessionView> {
  final _tts = FlutterTts();
  bool _speaking = false;
  int _currentChunk = 0;
  String _mode = 'side-by-side';
  bool _lineFocus = false;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(localPrefsProvider);
    _tts.setSpeechRate(prefs.ttsRate * 0.5);
    _tts.setPitch(prefs.ttsPitch);
    _tts.setLanguage('en-US');
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _speaking = false);
    });
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.payload?['text'] as String? ?? '';
    final level = widget.payload?['level'] as String? ?? 'medium';
    final result = ref.watch(
        simplifyProvider(SimplifyRequest.make(text: text, level: level)),);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading'),
        actions: [
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
              Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 8,
                  children: ['original', 'simplified', 'side-by-side']
                      .map((m) => ChoiceChip(
                            label: Text(m),
                            selected: _mode == m,
                            onSelected: (_) => setState(() => _mode = m),
                          ),)
                      .toList(),
                ),
              ),
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
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: data.chunks.length,
                  itemBuilder: (_, i) {
                    final c = data.chunks[i];
                    final isCurrent = i == _currentChunk && _speaking;
                    final isFocused = _lineFocus && i == _currentChunk;
                    final faded = _lineFocus && i != _currentChunk;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? Theme.of(context)
                                .colorScheme
                                .secondary
                                .withValues(alpha: 0.15)
                            : null,
                        borderRadius: BorderRadius.circular(12),
                        border: isFocused
                            ? Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,)
                            : null,
                      ),
                      child: Opacity(
                        opacity: faded ? 0.25 : 1.0,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: _renderChunk(c.original, c.simplified),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      IconButton.filled(
                        onPressed: () => _prev(),
                        icon: const Icon(Icons.skip_previous),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          icon:
                              Icon(_speaking ? Icons.pause : Icons.play_arrow),
                          label: Text(_speaking ? 'Pause' : 'Read aloud'),
                          onPressed: () => _toggleSpeak(data.chunks.isEmpty
                              ? ''
                              : _readableText(
                                  data.chunks[_currentChunk].original,
                                  data.chunks[_currentChunk].simplified,),),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: () {
                          if (_currentChunk < data.chunks.length - 1) {
                            setState(() => _currentChunk++);
                          }
                        },
                        icon: const Icon(Icons.skip_next),
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

  Widget _renderChunk(String original, String simplified) {
    switch (_mode) {
      case 'original':
        return Text(original, style: Theme.of(context).textTheme.bodyLarge);
      case 'simplified':
        return Text(simplified, style: Theme.of(context).textTheme.bodyLarge);
      default:
        return LayoutBuilder(builder: (_, c) {
          final wide = c.maxWidth > 600;
          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(original)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(simplified,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,),),
                ),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(simplified,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),),
              const SizedBox(height: 6),
              Text(original, style: Theme.of(context).textTheme.bodySmall),
            ],
          );
        },);
    }
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

  void _prev() {
    if (_currentChunk > 0) setState(() => _currentChunk--);
  }
}
