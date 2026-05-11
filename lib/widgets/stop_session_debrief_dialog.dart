import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../l10n/app_localizations.dart';

void _popDebrief(
  BuildContext dialogContext,
  StopSessionDebriefResult result,
) {
  FocusManager.instance.primaryFocus?.unfocus();
  SchedulerBinding.instance.addPostFrameCallback((_) {
    if (dialogContext.mounted) {
      Navigator.of(dialogContext).pop(result);
    }
  });
}

/// Pola po zatrzymaniu timera. [skipped] — pomiń bez tytułu/notatki; [neverShowAgain] wyłącza dialog.
class StopSessionDebriefResult {
  StopSessionDebriefResult({
    this.taskTitle,
    this.note,
    required this.isBillable,
    required this.neverShowAgain,
    this.skipped = false,
  });

  final String? taskTitle;
  final String? note;
  final bool isBillable;
  final bool neverShowAgain;

  /// Użytkownik wybrał „Pomiń” zamiast „Zapisz”.
  final bool skipped;
}

Future<StopSessionDebriefResult?> showStopSessionDebriefDialog(
  BuildContext context,
) async {
  final l10n = AppLocalizations.of(context)!;
  final taskCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  var billable = true;
  var hideNext = false;

  final result = await showDialog<StopSessionDebriefResult>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setS) => AlertDialog(
        title: Text(l10n.debriefTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: taskCtrl,
                decoration: InputDecoration(
                  labelText: l10n.debriefTaskLabel,
                  border: const OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                decoration: InputDecoration(
                  labelText: l10n.debriefNoteLabel,
                  border: const OutlineInputBorder(),
                ),
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: billable,
                onChanged: (v) => setS(() => billable = v ?? true),
                title: Text(l10n.debriefBillableLabel),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: hideNext,
                onChanged: (v) => setS(() => hideNext = v ?? false),
                title: Text(l10n.debriefDontShowAgain),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _popDebrief(
              dialogContext,
              StopSessionDebriefResult(
                isBillable: billable,
                neverShowAgain: hideNext,
                skipped: true,
              ),
            ),
            child: Text(l10n.debriefSkip),
          ),
          FilledButton(
            onPressed: () {
              String? tt = taskCtrl.text.trim();
              if (tt.isEmpty) tt = null;
              String? nt = noteCtrl.text.trim();
              if (nt.isEmpty) nt = null;
              _popDebrief(
                dialogContext,
                StopSessionDebriefResult(
                  taskTitle: tt,
                  note: nt,
                  isBillable: billable,
                  neverShowAgain: hideNext,
                ),
              );
            },
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    ),
  );

  taskCtrl.dispose();
  noteCtrl.dispose();
  return result;
}
