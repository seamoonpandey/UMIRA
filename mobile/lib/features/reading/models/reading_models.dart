class TextChunk {
  final String original;
  final String simplified;
  TextChunk({required this.original, required this.simplified});
  factory TextChunk.fromJson(Map<String, dynamic> j) => TextChunk(
        original: (j['original'] ?? j['originalChunk']) as String,
        simplified: (j['simplified'] ?? j['simplifiedChunk']) as String,
      );
}

class KeyTerm {
  final String term;
  final String definition;
  KeyTerm({required this.term, required this.definition});
  factory KeyTerm.fromJson(Map<String, dynamic> j) =>
      KeyTerm(term: j['term'] as String, definition: j['definition'] as String);
}

class SimplifyResult {
  final String summary;
  final List<TextChunk> chunks;
  final List<KeyTerm> keyTerms;
  SimplifyResult({required this.summary, required this.chunks, required this.keyTerms});
  factory SimplifyResult.fromJson(Map<String, dynamic> j) => SimplifyResult(
        summary: j['summary'] as String,
        chunks: ((j['chunks'] as List?) ?? []).map((e) => TextChunk.fromJson(e as Map<String, dynamic>)).toList(),
        keyTerms: ((j['key_terms'] as List?) ?? []).map((e) => KeyTerm.fromJson(e as Map<String, dynamic>)).toList(),
      );
}
