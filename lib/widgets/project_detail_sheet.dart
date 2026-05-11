import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../bloc/timer_cubit.dart';
import '../l10n/app_localizations.dart';
import '../models/workspace.dart';
import '../screens/project_report_screen.dart';
import '../services/stats_service.dart';
import '../utils/format_duration.dart';
import '../utils/workspace_color.dart';
import 'home_shell_tab_scope.dart';
import 'project_editor_sheet.dart';

/// Bottom sheet: podsumowanie projektu i akcje (bez zmiany koncepcji list w zakładce Projekty).
Future<void> showProjectDetailSheet(
  BuildContext context, {
  required Workspace workspace,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final hostForTabNav = context;
  final timerCubit = context.read<TimerCubit>();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      // Trasa modala nie zawsze widzi BlocProvider z HomeShell — podajemy cubit jawnie.
      return BlocProvider<TimerCubit>.value(
        value: timerCubit,
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(ctx).bottom),
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.72,
            minChildSize: 0.45,
            maxChildSize: 0.94,
            builder: (context, scrollCtrl) {
              return BlocBuilder<TimerCubit, TimerState>(
                builder: (context, state) {
                  Workspace wsheet = workspace;
                  for (final w in state.workspaces) {
                    if (w.id == workspace.id) {
                      wsheet = w;
                      break;
                    }
                  }

                  final theme = Theme.of(context);
                  final scheme = theme.colorScheme;
                  final statsService = StatsService();
                  final now = DateTime.now();
                  final monthRange = DateTimeRange(
                    start: DateTime(now.year, now.month, 1),
                    end: DateTime(
                      now.year,
                      now.month,
                      now.day,
                      23,
                      59,
                      59,
                      999,
                    ),
                  );
                  final wsMap = {for (final w in state.workspaces) w.id: w};
                  final monthEntries = state.statsEntries.where((e) {
                    return !e.isDeleted &&
                        e.workspaceId == wsheet.id &&
                        !e.start.isBefore(monthRange.start) &&
                        !e.start.isAfter(monthRange.end);
                  }).toList();
                  final estimate = statsService.buildBillingEstimate(
                    entries: state.statsEntries,
                    from: monthRange.start,
                    to: monthRange.end,
                    workspaceIds: {wsheet.id},
                    workspaces: wsMap,
                  );
                  final accent = workspaceAccentColor(
                    wsheet.colorHex,
                    scheme.primary,
                  );
                  final rateLine =
                      wsheet.hourlyRate != null &&
                          wsheet.hourlyRate! > 0 &&
                          (wsheet.currencyCode ?? '').isNotEmpty
                      ? '${wsheet.hourlyRate} ${wsheet.currencyCode}/h'
                      : null;

                  Future<void> archiveToggle() async {
                    final next = wsheet.copyWith(
                      isArchived: !wsheet.isArchived,
                      updatedAt: DateTime.now(),
                    );
                    await context.read<TimerCubit>().saveProject(next);
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  }

                  Future<void> edit() async {
                    final saved = await showProjectEditorSheet(
                      context,
                      initial: wsheet,
                    );
                    if (!context.mounted || saved == null) return;
                    await context.read<TimerCubit>().saveProject(saved);
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  }

                  void openReport() {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => BlocProvider.value(
                          value: context.read<TimerCubit>(),
                          child: ProjectReportScreen(workspaceId: wsheet.id),
                        ),
                      ),
                    );
                  }

                  void goTimer() async {
                    await context.read<TimerCubit>().setActiveWorkspace(
                      wsheet.id,
                    );
                    if (!ctx.mounted || !context.mounted) return;
                    Navigator.of(ctx).pop();
                    HomeShellTabScope.maybeOf(hostForTabNav)?.goToTab(0);
                  }

                  return ListView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: accent.withValues(alpha: 0.35),
                            child: Icon(
                              Icons.folder_outlined,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  wsheet.name,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if ((wsheet.companyName ?? '')
                                    .trim()
                                    .isNotEmpty)
                                  Text(
                                    wsheet.companyName!.trim(),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                if (wsheet.isArchived)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      l10n.projectsArchived,
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                            color: scheme.tertiary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                if (rateLine != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      rateLine,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: scheme.outline,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.projectDetailMonthSummary,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _SheetTile(
                              title: l10n.reportTotalTime,
                              value: formatDurationHm(
                                monthEntries.fold(
                                  Duration.zero,
                                  (a, e) => a + e.duration,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SheetTile(
                              title: l10n.statsBillableHours,
                              value: formatDurationHm(estimate.billableWorked),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _SheetTile(
                        title: l10n.reportEstimatedEarnings,
                        value: estimate.earningsByCurrency.isEmpty
                            ? '—'
                            : () {
                                final lc = Localizations.localeOf(
                                  context,
                                ).languageCode;
                                final fmt = NumberFormat('#,##0.00', lc);
                                return estimate.earningsByCurrency.entries
                                    .map(
                                      (e) => '${fmt.format(e.value)} ${e.key}',
                                    )
                                    .join(' · ');
                              }(),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: wsheet.isArchived ? null : () => goTimer(),
                        icon: const Icon(Icons.timer_outlined),
                        label: Text(l10n.projectDetailUseForTimer),
                      ),
                      if (wsheet.isArchived)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            l10n.projectsArchivedSubtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.outline,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: edit,
                        icon: const Icon(Icons.edit_outlined),
                        label: Text(l10n.projectsEditTitle),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: openReport,
                        icon: const Icon(Icons.assignment_outlined),
                        label: Text(l10n.projectDetailOpenReport),
                      ),
                      const SizedBox(height: 10),
                      wsheet.isArchived
                          ? OutlinedButton.icon(
                              onPressed: archiveToggle,
                              icon: const Icon(Icons.unarchive_outlined),
                              label: Text(l10n.projectsRestoreAction),
                            )
                          : TextButton.icon(
                              onPressed: archiveToggle,
                              icon: const Icon(Icons.archive_outlined),
                              label: Text(l10n.projectsArchiveAction),
                            ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      );
    },
  );
}

class _SheetTile extends StatelessWidget {
  const _SheetTile({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
