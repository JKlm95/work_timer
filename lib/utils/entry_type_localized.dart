import '../l10n/app_localizations.dart';
import '../models/entry_type.dart';

String entryTypeLocalized(EntryType type, AppLocalizations l10n) {
  switch (type) {
    case EntryType.work:
      return l10n.entryTypeWork;
    case EntryType.vacation:
      return l10n.entryTypeVacation;
    case EntryType.sickLeave:
      return l10n.entryTypeSickLeave;
    case EntryType.businessTrip:
      return l10n.entryTypeBusinessTrip;
    case EntryType.other:
      return l10n.entryTypeOther;
  }
}
