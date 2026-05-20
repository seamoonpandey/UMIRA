import 'package:flutter_test/flutter_test.dart';
import 'package:umira/features/tasks/models/task_models.dart';

void main() {
  group('Microtask', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'mt1',
        'label': 'Open note-taking app',
        'position': 0,
        'estimatedMinutes': 5,
        'status': 'pending',
        'editedByUser': false,
      };
      final mt = Microtask.fromJson(json);
      expect(mt.id, 'mt1');
      expect(mt.label, 'Open note-taking app');
      expect(mt.position, 0);
      expect(mt.estimatedMinutes, 5);
      expect(mt.status, 'pending');
      expect(mt.editedByUser, false);
    });

    test('fromJson defaults editedByUser to false when null', () {
      final json = {
        'id': 'mt2',
        'label': 'Write outline',
        'position': 1,
        'estimatedMinutes': 10,
        'status': 'pending',
      };
      final mt = Microtask.fromJson(json);
      expect(mt.editedByUser, false);
    });
  });

  group('Task', () {
    test('fromJson parses correctly with microtasks', () {
      final json = {
        'id': 'task1',
        'title': 'Write blog post',
        'status': 'open',
        'priority': 'normal',
        'createdAt': '2026-05-20T00:00:00.000Z',
        'microtasks': [
          {
            'id': 'mt1',
            'label': 'Open app',
            'position': 0,
            'estimatedMinutes': 5,
            'status': 'pending',
            'editedByUser': false,
          },
        ],
      };
      final task = Task.fromJson(json);
      expect(task.id, 'task1');
      expect(task.title, 'Write blog post');
      expect(task.status, 'open');
      expect(task.priority, 'normal');
      expect(task.createdAt, DateTime.utc(2026, 5, 20));
      expect(task.microtasks.length, 1);
      expect(task.microtasks.first.label, 'Open app');
    });

    test('fromJson handles empty microtasks list', () {
      final json = {
        'id': 'task2',
        'title': 'Shopping',
        'status': 'open',
        'priority': 'high',
        'createdAt': '2026-05-20T00:00:00.000Z',
      };
      final task = Task.fromJson(json);
      expect(task.microtasks, isEmpty);
    });
  });
}
