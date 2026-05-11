enum EntryType { work, vacation, sickLeave, businessTrip, other }

String entryTypeStorage(EntryType t) => t.name;

EntryType entryTypeFromStorage(String? raw) {
  if (raw == null) return EntryType.work;
  for (final v in EntryType.values) {
    if (v.name == raw) return v;
  }
  return EntryType.work;
}
