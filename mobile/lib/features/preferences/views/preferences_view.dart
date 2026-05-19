import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/preferences_repository.dart';
import '../providers/preferences_provider.dart';

class PreferencesView extends ConsumerWidget {
  const PreferencesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(localPrefsProvider);
    final notifier = ref.read(localPrefsProvider.notifier);
    final remote = ref.read(preferencesRepoProvider);

    Future<void> sync(Map<String, dynamic> data) async {
      try { await remote.patch(data); } catch (_) {/* offline-safe */}
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Your preferences')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('Reading & display'),
          SwitchListTile(
            title: const Text('Dyslexia-friendly font'),
            subtitle: const Text('Uses a high-readability typeface'),
            value: prefs.useDyslexiaFont,
            onChanged: (v) {
              notifier.update((s) => s.copyWith(useDyslexiaFont: v));
              sync({'useDyslexiaFont': v});
            },
          ),
          ListTile(
            title: const Text('Text size'),
            subtitle: Slider(
              min: 0.8, max: 1.6, divisions: 8,
              value: prefs.fontScale,
              label: prefs.fontScale.toStringAsFixed(2),
              onChanged: (v) {
                notifier.update((s) => s.copyWith(fontScale: v));
                sync({'fontScale': v});
              },
            ),
          ),
          ListTile(
            title: const Text('Line spacing'),
            subtitle: Wrap(
              spacing: 8,
              children: ['normal', 'wide', 'extra-wide'].map((m) => ChoiceChip(
                label: Text(m),
                selected: prefs.spacingMode == m,
                onSelected: (_) {
                  notifier.update((s) => s.copyWith(spacingMode: m));
                  sync({'spacingMode': m});
                },
              )).toList(),
            ),
          ),
          SwitchListTile(
            title: const Text('Reduce motion'),
            value: prefs.reducedMotion,
            onChanged: (v) {
              notifier.update((s) => s.copyWith(reducedMotion: v));
              sync({'reducedMotion': v});
            },
          ),
          _section('Focus'),
          ListTile(
            title: const Text('Default session length'),
            subtitle: Wrap(
              spacing: 8,
              children: [10, 15, 20, 25].map((m) => ChoiceChip(
                label: Text('$m min'),
                selected: prefs.sessionLengthDefault == m,
                onSelected: (_) {
                  notifier.update((s) => s.copyWith(sessionLengthDefault: m));
                  sync({'sessionLengthDefault': m});
                },
              )).toList(),
            ),
          ),
          _section('Read-aloud voice'),
          ListTile(
            title: const Text('Speech rate'),
            subtitle: Slider(
              min: 0.5, max: 2.0, divisions: 15,
              value: prefs.ttsRate,
              onChanged: (v) {
                notifier.update((s) => s.copyWith(ttsRate: v));
                sync({'ttsRate': v});
              },
            ),
          ),
          ListTile(
            title: const Text('Pitch'),
            subtitle: Slider(
              min: 0.5, max: 2.0, divisions: 15,
              value: prefs.ttsPitch,
              onChanged: (v) {
                notifier.update((s) => s.copyWith(ttsPitch: v));
                sync({'ttsPitch': v});
              },
            ),
          ),
          _section('Account & privacy'),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Export my data'),
            subtitle: const Text('Download a JSON copy of everything'),
            onTap: () => _exportInfo(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Delete account'),
            subtitle: const Text('Hard delete - cannot be undone'),
            onTap: () => _confirmDelete(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            onTap: () async {
              await ref.read(authStateProvider.notifier).signOut();
              if (context.mounted) context.go('/onboarding');
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'UMIRA is an assistive productivity and reading-support tool. '
            'It is not a diagnostic tool and does not provide medical advice.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
      );

  void _exportInfo(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Export your data'),
        content: const Text('Download a complete JSON copy of your data.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(preferencesRepoProvider).exportData();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Data export started — check your downloads.')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Export failed: $e')),
                  );
                }
              }
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text('This permanently deletes your account, tasks, and reading sessions.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(preferencesRepoProvider).deleteAccount();
              await ref.read(authStateProvider.notifier).signOut();
              if (context.mounted) context.go('/onboarding');
            },
            child: const Text('Delete forever'),
          ),
        ],
      ),
    );
  }
}
