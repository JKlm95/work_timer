class Workspace {
  Workspace({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.isArchived = false,
  });

  static const String defaultId = 'default';

  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isArchived;

  factory Workspace.defaultWorkspace() {
    final now = DateTime.now();
    return Workspace(
      id: defaultId,
      name: 'Domyslny',
      createdAt: now,
      updatedAt: now,
    );
  }

  Workspace copyWith({String? name, DateTime? updatedAt, bool? isArchived}) {
    return Workspace(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'isArchived': isArchived,
  };

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'isArchived': isArchived,
  };

  factory Workspace.fromJson(Map<String, dynamic> json) {
    return Workspace(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Workspace',
      createdAt: DateTime.parse(
        json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] as String? ??
            json['createdAt'] as String? ??
            DateTime.now().toIso8601String(),
      ),
      isArchived: json['isArchived'] as bool? ?? false,
    );
  }
}
