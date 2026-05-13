enum EntryType { work, vacation, sickLeave, businessTrip, other }

String entryTypeStorage(EntryType t) => t.name;

EntryType entryTypeFromStorage(String? raw) {
  if (raw == null) return EntryType.work;
  final key = raw.trim().toLowerCase();
  if (key.isEmpty) return EntryType.work;
  for (final v in EntryType.values) {
    if (v.name.toLowerCase() == key) return v;
  }
  return EntryType.work;
}
