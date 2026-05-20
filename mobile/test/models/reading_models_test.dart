import 'package:flutter_test/flutter_test.dart';
import 'package:umira/features/reading/models/reading_models.dart';

void main() {
  group('TextChunk', () {
    test('fromJson parses standard keys', () {
      final c = TextChunk.fromJson({
        'original': 'Long sentence here',
        'simplified': 'Short sentence.',
      });
      expect(c.original, 'Long sentence here');
      expect(c.simplified, 'Short sentence.');
    });

    test('fromJson falls back to alternative keys', () {
      final c = TextChunk.fromJson({
        'originalChunk': 'Fallback original',
        'simplifiedChunk': 'Fallback simplified',
      });
      expect(c.original, 'Fallback original');
      expect(c.simplified, 'Fallback simplified');
    });
  });

  group('KeyTerm', () {
    test('fromJson parses correctly', () {
      final kt = KeyTerm.fromJson({
        'term': 'API',
        'definition': 'Application Programming Interface',
      });
      expect(kt.term, 'API');
      expect(kt.definition, 'Application Programming Interface');
    });
  });

  group('SimplifyResult', () {
    test('fromJson parses full structure', () {
      final json = {
        'summary': 'A short summary.',
        'chunks': [
          {'original': 'Long text', 'simplified': 'Short text'},
        ],
        'key_terms': [
          {'term': 'AI', 'definition': 'Artificial Intelligence'},
        ],
      };
      final result = SimplifyResult.fromJson(json);
      expect(result.summary, 'A short summary.');
      expect(result.chunks.length, 1);
      expect(result.chunks.first.original, 'Long text');
      expect(result.keyTerms.length, 1);
      expect(result.keyTerms.first.term, 'AI');
    });

    test('fromJson handles empty lists', () {
      final json = {
        'summary': 'Empty result.',
        'chunks': [],
        'key_terms': [],
      };
      final result = SimplifyResult.fromJson(json);
      expect(result.chunks, isEmpty);
      expect(result.keyTerms, isEmpty);
    });
  });
}
