class Microtask {
  final String id;
  final String label;
  final int position;
  final int estimatedMinutes;
  final String status;
  final bool editedByUser;

  Microtask({
    required this.id,
    required this.label,
    required this.position,
    required this.estimatedMinutes,
    required this.status,
    required this.editedByUser,
  });

  factory Microtask.fromJson(Map<String, dynamic> j) => Microtask(
        id: j['id'] as String,
        label: j['label'] as String,
        position: j['position'] as int,
        estimatedMinutes: j['estimatedMinutes'] as int,
        status: j['status'] as String,
        editedByUser: j['editedByUser'] as bool? ?? false,
      );
}

class Task {
  final String id;
  final String title;
  final String status;
  final String priority;
  final DateTime createdAt;
  final List<Microtask> microtasks;

  Task({
    required this.id,
    required this.title,
    required this.status,
    required this.priority,
    required this.createdAt,
    required this.microtasks,
  });

  factory Task.fromJson(Map<String, dynamic> j) => Task(
        id: j['id'] as String,
        title: j['title'] as String,
        status: j['status'] as String,
        priority: j['priority'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        microtasks: ((j['microtasks'] as List?) ?? [])
            .map((m) => Microtask.fromJson(m as Map<String, dynamic>))
            .toList(),
      );
}
