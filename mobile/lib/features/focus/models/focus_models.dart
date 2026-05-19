class FocusSession {
  final String id;
  final int plannedMinutes;
  final int? actualMinutes;
  final String status;
  FocusSession(
      {required this.id,
      required this.plannedMinutes,
      this.actualMinutes,
      required this.status,});
  factory FocusSession.fromJson(Map<String, dynamic> j) => FocusSession(
        id: j['id'] as String,
        plannedMinutes: j['plannedMinutes'] as int,
        actualMinutes: j['actualMinutes'] as int?,
        status: j['status'] as String,
      );
}
