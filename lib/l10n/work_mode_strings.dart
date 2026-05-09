import '../models/work_mode.dart';
import 'app_localizations.dart';

extension WorkModeStrings on WorkMode {
  String localized(AppLocalizations l10n) => switch (this) {
    WorkMode.remote => l10n.workModeRemote,
    WorkMode.office => l10n.workModeOffice,
  };
}
