import 'package:flutter_test/flutter_test.dart';
import 'package:umira/features/focus/models/focus_models.dart';

void main() {
  group('FocusSession', () {
    test('fromJson parses with actualMinutes', () {
      final json = {
        'id': 'fs1',
        'plannedMinutes': 25,
        'actualMinutes': 23,
        'status': 'completed',
      };
      final fs = FocusSession.fromJson(json);
      expect(fs.id, 'fs1');
      expect(fs.plannedMinutes, 25);
      expect(fs.actualMinutes, 23);
      expect(fs.status, 'completed');
    });

    test('fromJson parses without actualMinutes', () {
      final json = {
        'id': 'fs2',
        'plannedMinutes': 15,
        'status': 'running',
      };
      final fs = FocusSession.fromJson(json);
      expect(fs.actualMinutes, isNull);
      expect(fs.status, 'running');
    });
  });
}
