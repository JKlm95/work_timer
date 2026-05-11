import 'package:cloud_firestore/cloud_firestore.dart';

import 'entry_type.dart';
import 'work_mode.dart';
import 'workspace.dart';

class WorkEntry {
  WorkEntry({
    required this.id,
    required this.workspaceId,
    required this.start,
    required this.end,
    required this.mode,
    required this.updatedAt,
    this.isDeleted = false,
    this.taskTitle,
    this.note,
    this.isBillable = true,
    this.entryType = EntryType.work,
  });

  final String id;
  final String workspaceId;
  final DateTime start;
  final DateTime end;
  final WorkMode mode;
  final DateTime updatedAt;
  final bool isDeleted;

  final String? taskTitle;
  final String? note;

  /// Dla rozliczeń; domyślnie true (sesja timera).
  final bool isBillable;
  final EntryType entryType;

  Duration get duration => end.difference(start);

  /// Czy wpis liczy się do szacowanego przychodu (stawka × czas).
  bool get countsTowardEarningsEstimate =>
      !isDeleted &&
      entryType == EntryType.work &&
      isBillable &&
      start.isBefore(end);

  WorkEntry copyWith({
    String? workspaceId,
    DateTime? start,
    DateTime? end,
    WorkMode? mode,
    DateTime? updatedAt,
    bool? isDeleted,
    String? taskTitle,
    String? note,
    bool? isBillable,
    EntryType? entryType,
  }) {
    return WorkEntry(
      id: id,
      workspaceId: workspaceId ?? this.workspaceId,
      start: start ?? this.start,
      end: end ?? this.end,
      mode: mode ?? this.mode,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      taskTitle: taskTitle ?? this.taskTitle,
      note: note ?? this.note,
      isBillable: isBillable ?? this.isBillable,
      entryType: entryType ?? this.entryType,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'workspaceId': workspaceId,
    'start': start.toIso8601String(),
    'end': end.toIso8601String(),
    'mode': mode.storageValue,
    'updatedAt': updatedAt.toIso8601String(),
    'isDeleted': isDeleted,
    'taskTitle': taskTitle,
    'note': note,
    'isBillable': isBillable,
    'entryType': entryTypeStorage(entryType),
  };

  Map<String, dynamic> toFirestore() => {
    'workspaceId': workspaceId,
    'start': start,
    'end': end,
    'mode': mode.storageValue,
    'updatedAt': updatedAt,
    'isDeleted': isDeleted,
    'isBillable': isBillable,
    'entryType': entryTypeStorage(entryType),
    if (taskTitle != null && taskTitle!.trim().isNotEmpty)
      'taskTitle': taskTitle!.trim(),
    if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
  };

  factory WorkEntry.fromJson(Map<String, dynamic> json) {
    bool billable(dynamic v, EntryType type) {
      if (v is bool) return v;
      if (type != EntryType.work) return false;
      return true;
    }

    final type = entryTypeFromStorage(json['entryType'] as String?);
    return WorkEntry(
      id: json['id'] as String,
      workspaceId: json['workspaceId'] as String? ?? Workspace.defaultId,
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
      mode: workModeFromStorage(json['mode'] as String?),
      updatedAt: DateTime.parse(
        json['updatedAt'] as String? ?? json['end'] as String,
      ),
      isDeleted: json['isDeleted'] as bool? ?? false,
      taskTitle: json['taskTitle'] as String?,
      note: json['note'] as String?,
      isBillable: billable(json['isBillable'], type),
      entryType: type,
    );
  }

  factory WorkEntry.fromFirestore(String id, Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      if (value is Timestamp) return value.toDate();
      return DateTime.now();
    }

    bool billable(dynamic v, EntryType type) {
      if (v is bool) return v;
      if (type != EntryType.work) return false;
      return true;
    }

    final type = entryTypeFromStorage(json['entryType'] as String?);

    return WorkEntry(
      id: id,
      workspaceId: json['workspaceId'] as String? ?? Workspace.defaultId,
      start: parseDate(json['start']),
      end: parseDate(json['end']),
      mode: workModeFromStorage(json['mode'] as String?),
      updatedAt: parseDate(json['updatedAt']),
      isDeleted: json['isDeleted'] as bool? ?? false,
      taskTitle: json['taskTitle'] as String?,
      note: json['note'] as String?,
      isBillable: billable(json['isBillable'], type),
      entryType: type,
    );
  }
}
