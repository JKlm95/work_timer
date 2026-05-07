import 'package:cloud_firestore/cloud_firestore.dart';

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
  });

  final String id;
  final String workspaceId;
  final DateTime start;
  final DateTime end;
  final WorkMode mode;
  final DateTime updatedAt;
  final bool isDeleted;

  Duration get duration => end.difference(start);

  Map<String, dynamic> toJson() => {
    'id': id,
    'workspaceId': workspaceId,
    'start': start.toIso8601String(),
    'end': end.toIso8601String(),
    'mode': mode.storageValue,
    'updatedAt': updatedAt.toIso8601String(),
    'isDeleted': isDeleted,
  };

  Map<String, dynamic> toFirestore() => {
    'workspaceId': workspaceId,
    'start': start,
    'end': end,
    'mode': mode.storageValue,
    'updatedAt': updatedAt,
    'isDeleted': isDeleted,
  };

  factory WorkEntry.fromJson(Map<String, dynamic> json) {
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
    );
  }

  factory WorkEntry.fromFirestore(String id, Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      if (value is Timestamp) return value.toDate();
      return DateTime.now();
    }

    return WorkEntry(
      id: id,
      workspaceId: json['workspaceId'] as String? ?? Workspace.defaultId,
      start: parseDate(json['start']),
      end: parseDate(json['end']),
      mode: workModeFromStorage(json['mode'] as String?),
      updatedAt: parseDate(json['updatedAt']),
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }
}
