import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:umira/shared/widgets/umira_button.dart';

void main() {
  group('UmiraButton', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UmiraButton(label: 'Click me', onPressed: null),
          ),
        ),
      );
      expect(find.text('Click me'), findsOneWidget);
    });

    testWidgets('fires onPressed when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UmiraButton(label: 'Tap', onPressed: () => tapped = true),
          ),
        ),
      );
      await tester.tap(find.text('Tap'));
      expect(tapped, isTrue);
    });

    testWidgets('renders FilledButton when primary', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UmiraButton(label: 'Primary', onPressed: null, primary: true),
          ),
        ),
      );
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('renders OutlinedButton when not primary', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UmiraButton(label: 'Secondary', onPressed: null, primary: false),
          ),
        ),
      );
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('shows icon when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UmiraButton(
              label: 'Save',
              onPressed: null,
              icon: Icons.save,
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.save), findsOneWidget);
    });

    testWidgets('does not crash when onPressed is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UmiraButton(label: 'Disabled', onPressed: null),
          ),
        ),
      );
      expect(find.text('Disabled'), findsOneWidget);
    });
  });
}
