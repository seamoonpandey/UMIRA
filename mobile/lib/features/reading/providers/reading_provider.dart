import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/reading_repository.dart';
import '../models/reading_models.dart';

final simplifyProvider = FutureProvider.autoDispose.family<SimplifyResult, _Req>((ref, req) async {
  return ref.read(readingRepoProvider).simplify(
        text: req.text, level: req.level, glossary: req.glossary, save: req.save,
      );
});

class _Req {
  final String text;
  final String level;
  final bool glossary;
  final bool save;
  _Req(this.text, this.level, this.glossary, this.save);
  @override
  bool operator ==(Object other) =>
      other is _Req && other.text == text && other.level == level && other.glossary == glossary && other.save == save;
  @override
  int get hashCode => Object.hash(text, level, glossary, save);
}

class SimplifyRequest {
  static _Req make({required String text, String level = 'medium', bool glossary = true, bool save = false}) =>
      _Req(text, level, glossary, save);
}
