import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:umira/shared/widgets/umira_text_field.dart';

void main() {
  group('UmiraTextField', () {
    testWidgets('renders label and hint text', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UmiraTextField(
              controller: controller,
              label: 'Email',
              hint: 'Enter your email',
            ),
          ),
        ),
      );
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Enter your email'), findsOneWidget);
    });

    testWidgets('obscures text when obscure is true', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UmiraTextField(
              controller: controller,
              label: 'Password',
              obscure: true,
            ),
          ),
        ),
      );
      final textField = tester.widget<TextField>(
        find.byType(TextField),
      );
      expect(textField.obscureText, isTrue);
    });

    testWidgets('does not obscure when obscure is false', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UmiraTextField(
              controller: controller,
              label: 'Name',
              obscure: false,
            ),
          ),
        ),
      );
      final textField = tester.widget<TextField>(
        find.byType(TextField),
      );
      expect(textField.obscureText, isFalse);
    });

    testWidgets('accepts typed text', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UmiraTextField(
              controller: controller,
              label: 'Search',
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'hello');
      expect(controller.text, 'hello');
    });
  });
}
