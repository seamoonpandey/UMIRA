import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/umira_card.dart';
import '../../intervention/providers/intervention_provider.dart';
import '../providers/analytics_provider.dart';

class AnalyticsView extends ConsumerWidget {
  const AnalyticsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(analyticsSummaryProvider);
    final progress = ref.watch(interventionProgressProvider);
    final sessions = ref.watch(interventionSessionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Your insights (last 30 days)')),
      body: s.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load insights: $e')),
        data: (data) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Productivity stats
              Text('Productivity',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      context,
                      Icons.checklist,
                      'Tasks',
                      '${data['tasks_created'] ?? 0}',
                      Colors.indigo,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _statCard(
                      context,
                      Icons.check_circle_outline,
                      'Steps done',
                      '${data['microtasks_done'] ?? 0}',
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      context,
                      Icons.timer_outlined,
                      'Focus sessions',
                      '${data['focus_completed'] ?? 0}',
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _statCard(
                      context,
                      Icons.access_time,
                      'Focused min',
                      '${data['focus_total_minutes'] ?? 0}',
                      Colors.deepOrange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      context,
                      Icons.menu_book_outlined,
                      'Reading',
                      '${data['reading_sessions'] ?? 0}',
                      Colors.teal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _statCard(
                      context,
                      Icons.interpreter_mode,
                      'Interventions',
                      '${progress.totalSessions}',
                      Colors.purple,
                    ),
                  ),
                ],
              ),

              // Intervention performance
              if (progress.totalSessions > 0) ...[
                const SizedBox(height: 24),
                Text('Intervention performance',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        context,
                        Icons.edit,
                        'Spelling avg',
                        '${progress.spellingAverage.toStringAsFixed(0)}%',
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _statCard(
                        context,
                        Icons.keyboard,
                        'Typing WPM',
                        '${progress.typingWpm}',
                        Colors.amber,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _statCard(
                        context,
                        Icons.mic,
                        'Practice WPM',
                        '${progress.practiceWpm}',
                        Colors.pink,
                      ),
                    ),
                  ],
                ),
              ],

              // Time estimation
              if ((data['estimation_accuracy']?['avg_planned_minutes'] ?? 0) > 0 ||
                  (data['estimation_accuracy']?['avg_actual_minutes'] ?? 0) > 0) ...[
                const SizedBox(height: 16),
                UmiraCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.trending_up, size: 20),
                          const SizedBox(width: 8),
                          Text('Time estimation',
                              style:
                                  Theme.of(context).textTheme.titleMedium,),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                          'Avg planned: ${(data['estimation_accuracy']?['avg_planned_minutes'] ?? 0)} min',),
                      Text(
                          'Avg actual:  ${(data['estimation_accuracy']?['avg_actual_minutes'] ?? 0)} min',),
                      const SizedBox(height: 8),
                      const Text(
                          'A personal trend, not a judgement.',),
                    ],
                  ),
                ),
              ],

              // Recent intervention sessions
              const SizedBox(height: 24),
              Text('Recent intervention sessions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),),
              const SizedBox(height: 8),
              sessions.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Could not load sessions: $e'),
                data: (list) {
                  if (list.isEmpty) {
                    return UmiraCard(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Icon(Icons.interpreter_mode,
                                size: 48,
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.5),),
                            const SizedBox(height: 12),
                            const Text(
                                'No intervention sessions yet.',),
                            const SizedBox(height: 8),
                            const Text(
                              'Try the Practice or Spelling exercises to get started!',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: list.take(10).map((s) {
                      IconData icon;
                      Color color;
                      switch (s.type) {
                        case 'practice':
                          icon = Icons.mic;
                          color = Colors.pink;
                          break;
                        case 'spelling':
                          icon = Icons.edit;
                          color = Colors.blue;
                          break;
                        case 'typing':
                          icon = Icons.keyboard;
                          color = Colors.amber;
                          break;
                        case 'lesson':
                          icon = Icons.auto_stories;
                          color = Colors.green;
                          break;
                        default:
                          icon = Icons.circle;
                          color = Colors.grey;
                      }
                      return UmiraCard(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: color.withValues(alpha: 0.2),
                            child: Icon(icon, color: color, size: 20),
                          ),
                          title: Text(s.type),
                          subtitle:
                              Text(_sessionSubtitle(s)),
                          trailing: s.score != null && s.total != null
                              ? Text(
                                  '${s.score}/${s.total}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: s.score == s.total
                                        ? Colors.green
                                        : null,
                                  ),
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  String _sessionSubtitle(session) {
    final date = session.date.length >= 10
        ? session.date.substring(0, 10)
        : session.date;
    final parts = <String>[];
    if (session.wpm != null) parts.add('${session.wpm} wpm');
    if (session.grapheme != null) parts.add(session.grapheme!);
    parts.add(date);
    return parts.join(' · ');
  }

  Widget _statCard(
      BuildContext context, IconData icon, String label, String value, Color color,) {
    return UmiraCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
