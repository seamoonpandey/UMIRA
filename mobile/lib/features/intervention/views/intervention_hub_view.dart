import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/umira_card.dart';
import '../../preferences/providers/preferences_provider.dart';

class InterventionHubView extends ConsumerWidget {
  const InterventionHubView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(localPrefsProvider);
    final useDyslexic = prefs.useDyslexiaFont;

    final menuItems = [
      _InterventionItem(
        title: 'Practice Mode',
        description: 'Read aloud and get feedback on accuracy',
        icon: Icons.mic,
        color: const Color(0xFFE91E63),
        route: '/intervention/practice',
      ),
      _InterventionItem(
        title: 'Phonics Lessons',
        description: 'Learn grapheme-phoneme correspondences',
        icon: Icons.auto_stories,
        color: const Color(0xFF4CAF50),
        route: '/intervention/lesson',
      ),
      _InterventionItem(
        title: 'Word Masking',
        description: 'Focus on one word at a time',
        icon: Icons.visibility,
        color: const Color(0xFFFF9800),
        route: '/intervention/masking',
      ),
      _InterventionItem(
        title: 'Spelling Quiz',
        description: 'Listen and spell words correctly',
        icon: Icons.edit,
        color: const Color(0xFF2196F3),
        route: '/intervention/spelling',
      ),
      _InterventionItem(
        title: 'Typing Practice',
        description: 'Improve typing speed and accuracy',
        icon: Icons.keyboard,
        color: const Color(0xFFFF9800),
        route: '/intervention/typing',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Intervention'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Intervention Mode',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontFamily: useDyslexic ? 'Lexend' : null,
                  fontWeight: useDyslexic ? FontWeight.normal : FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Structured practice to improve skills',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontFamily: useDyslexic ? 'Lexend' : null,
                ),
          ),
          const SizedBox(height: 24),
          ...menuItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _InterventionCard(item: item, useDyslexic: useDyslexic),
            ),
          ),
        ],
      ),
    );
  }
}

class _InterventionItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String route;

  _InterventionItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.route,
  });
}

class _InterventionCard extends StatefulWidget {
  final _InterventionItem item;
  final bool useDyslexic;

  const _InterventionCard({required this.item, required this.useDyslexic});

  @override
  State<_InterventionCard> createState() => _InterventionCardState();
}

class _InterventionCardState extends State<_InterventionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.of(context);
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        router.push(widget.item.route);
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: UmiraCard(
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: widget.item.color,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(widget.item.icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontFamily: widget.useDyslexic ? 'Lexend' : null,
                            fontWeight: widget.useDyslexic
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.item.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontFamily: widget.useDyslexic ? 'Lexend' : null,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Theme.of(context).disabledColor),
            ],
          ),
        ),
      ),
    );
  }
}


