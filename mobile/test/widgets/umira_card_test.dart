import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:umira/shared/widgets/umira_card.dart';

void main() {
  group('UmiraCard', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UmiraCard(child: Text('Card content')),
          ),
        ),
      );
      expect(find.text('Card content'), findsOneWidget);
    });

    testWidgets('fires onTap when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UmiraCard(
              onTap: () => tapped = true,
              child: const Text('Tap me'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Tap me'));
      expect(tapped, isTrue);
    });

    testWidgets('renders with custom padding', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UmiraCard(
              padding: EdgeInsets.all(24),
              child: Text('Padded'),
            ),
          ),
        ),
      );
      expect(find.text('Padded'), findsOneWidget);
    });
  });
}
