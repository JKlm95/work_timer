import 'work_mode.dart';

class WorkEntry {
  WorkEntry({
    required this.id,
    required this.start,
    required this.end,
    required this.mode,
  });

  final String id;
  final DateTime start;
  final DateTime end;
  final WorkMode mode;

  Duration get duration => end.difference(start);

  Map<String, dynamic> toJson() => {
        'id': id,
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
        'mode': mode.storageValue,
      };

  factory WorkEntry.fromJson(Map<String, dynamic> json) {
    return WorkEntry(
      id: json['id'] as String,
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
      mode: workModeFromStorage(json['mode'] as String?),
    );
  }
}
