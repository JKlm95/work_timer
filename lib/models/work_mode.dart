enum WorkMode { remote, office }

extension WorkModeStorage on WorkMode {
  String get storageValue => name;
}

WorkMode workModeFromStorage(String? value) {
  return WorkMode.values.firstWhere(
    (m) => m.name == value,
    orElse: () => WorkMode.office,
  );
}
