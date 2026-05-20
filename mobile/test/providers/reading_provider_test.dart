import 'package:flutter_test/flutter_test.dart';
import 'package:umira/features/reading/providers/reading_provider.dart';

void main() {
  group('Req', () {
    test('equality respects all fields', () {
      final a = Req('Hello world', 'medium', true, false);
      final b = Req('Hello world', 'medium', true, false);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality on different text', () {
      final a = Req('Hello', 'medium', true, false);
      final b = Req('World', 'medium', true, false);
      expect(a, isNot(equals(b)));
    });

    test('inequality on different level', () {
      final a = Req('Hello', 'light', true, false);
      final b = Req('Hello', 'medium', true, false);
      expect(a, isNot(equals(b)));
    });

    test('inequality on different glossary flag', () {
      final a = Req('Hello', 'medium', false, false);
      final b = Req('Hello', 'medium', true, false);
      expect(a, isNot(equals(b)));
    });

    test('inequality on different save flag', () {
      final a = Req('Hello', 'medium', true, false);
      final b = Req('Hello', 'medium', true, true);
      expect(a, isNot(equals(b)));
    });
  });

  group('SimplifyRequest', () {
    test('make creates Req with given params', () {
      final req = SimplifyRequest.make(
        text: 'Some long text',
        level: 'light',
        glossary: false,
        save: true,
      );
      expect(req.text, 'Some long text');
      expect(req.level, 'light');
      expect(req.glossary, false);
      expect(req.save, true);
    });

    test('make uses defaults for optional params', () {
      final req = SimplifyRequest.make(text: 'Hello');
      expect(req.level, 'medium');
      expect(req.glossary, true);
      expect(req.save, false);
    });

    test('make provides correct hashCode consistency', () {
      final req = SimplifyRequest.make(text: 'Same');
      final req2 = SimplifyRequest.make(text: 'Same');
      expect(req.hashCode, equals(req2.hashCode));
    });
  });
}
