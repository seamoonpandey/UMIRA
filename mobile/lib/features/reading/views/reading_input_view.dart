import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/umira_button.dart';
import '../../../shared/widgets/umira_text_field.dart';
import '../../preferences/providers/preferences_provider.dart';

class ReadingInputView extends ConsumerStatefulWidget {
  const ReadingInputView({super.key});
  @override
  ConsumerState<ReadingInputView> createState() => _ReadingInputViewState();
}

class _ReadingInputViewState extends ConsumerState<ReadingInputView> {
  final _text = TextEditingController();
  String _level = 'medium';

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(localPrefsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Reading support')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Paste text to simplify and read aloud.',
                  style: Theme.of(context).textTheme.bodyLarge,),
              const SizedBox(height: 12),
              Expanded(
                child: UmiraTextField(
                  controller: _text,
                  label: 'Source text',
                  maxLines: 20,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: ['light', 'medium', 'high']
                    .map((l) => ChoiceChip(
                          label: Text(l),
                          selected: _level == l,
                          onSelected: (_) => setState(() => _level = l),
                        ),)
                    .toList(),
              ),
              const SizedBox(height: 12),
              UmiraButton(
                label: 'Simplify + open reader',
                primary: true,
                icon: Icons.menu_book_outlined,
                onPressed: () {
                  if (_text.text.trim().length < 20) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Please paste at least 20 characters.'),),
                    );
                    return;
                  }
                  context.push('/reading/session', extra: {
                    'text': _text.text,
                    'level': _level,
                    'useDyslexiaFont': prefs.useDyslexiaFont,
                  },);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
