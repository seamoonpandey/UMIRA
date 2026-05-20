import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:umira/shared/widgets/umira_button.dart';
import 'package:umira/shared/widgets/umira_card.dart';

void main() {
  testWidgets('Minimal reproduction: Expanded+UmiraButton in Row inside ListView', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('Heading'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: UmiraButton(
                      label: 'Scan Again',
                      icon: Icons.refresh,
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: UmiraButton(
                      label: 'Copy Text',
                      primary: true,
                      icon: Icons.copy,
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    print('=== MINIMAL REPRO ===');
    print('Scan Again: ${find.text("Scan Again").evaluate().length}');
    print('Copy Text: ${find.text("Copy Text").evaluate().length}');
    print('OutlinedButton: ${find.byType(OutlinedButton).evaluate().length}');
    print('FilledButton: ${find.byType(FilledButton).evaluate().length}');
    print('Expanded: ${find.byType(Expanded).evaluate().length}');
    for (final e in find.byType(Text).evaluate()) {
      final t = e.widget as Text;
      if (t.data != null) print('  Text: "${t.data}"');
    }
    print('=== END ===');

    expect(find.text('Scan Again'), findsOneWidget);
    expect(find.text('Copy Text'), findsOneWidget);
  });
}
