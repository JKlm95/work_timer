enum WorkMode {
  remote,
  office,
}

extension WorkModeLabels on WorkMode {
  String get labelPl => switch (this) {
        WorkMode.remote => 'Remote',
        WorkMode.office => 'Biuro',
      };

  String get storageValue => name;
}

WorkMode workModeFromStorage(String? value) {
  return WorkMode.values.firstWhere(
    (m) => m.name == value,
    orElse: () => WorkMode.office,
  );
}
