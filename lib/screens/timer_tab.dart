import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../bloc/settings_cubit.dart';
import '../bloc/timer_cubit.dart';
import '../l10n/app_localizations.dart';
import '../l10n/work_mode_strings.dart';
import '../models/work_entry.dart';
import '../models/work_mode.dart';
import '../models/workspace.dart';
import '../theme/app_layout.dart';
import '../utils/calendar_utils.dart';
import '../utils/format_duration.dart';
import '../utils/workspace_color.dart';
import '../widgets/stop_session_debrief_dialog.dart';
import '../widgets/ui/app_empty_state.dart';

class TimerTab extends StatelessWidget {
  const TimerTab({super.key});

  static String _formatClock(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  static Duration _sumDur(Iterable<WorkEntry> items) =>
      items.fold(Duration.zero, (a, e) => a + e.duration);

  static WorkEntry? _latestSession(List<WorkEntry> entries) {
    if (entries.isEmpty) return null;
    final sorted = [...entries]..sort((a, b) => b.start.compareTo(a.start));
    return sorted.first;
  }

  static String _statusLabel(TimerRunState state, AppLocalizations l10n) {
    return switch (state) {
      TimerRunState.idle => l10n.timerStatusIdle,
      TimerRunState.running => l10n.timerStatusRunning,
      TimerRunState.paused => l10n.timerStatusPaused,
    };
  }

  static List<Workspace> _pickerProjects(TimerState s) {
    final open = s.workspaces
        .where((w) => !w.isArchived)
        .toList(growable: false);
    return open.isNotEmpty ? open : [...s.workspaces];
  }

  static String _pickerWorkspaceId(TimerState s) {
    final list = _pickerProjects(s);
    if (list.any((w) => w.id == s.activeWorkspaceId)) {
      return s.activeWorkspaceId;
    }
    if (list.isNotEmpty) {
      return list.first.id;
    }
    return s.activeWorkspaceId;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lc = Localizations.localeOf(context).languageCode;

    return BlocBuilder<TimerCubit, TimerState>(
      builder: (context, state) {
        final cubit = context.read<TimerCubit>();
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        final textTheme = theme.textTheme;
        final now = DateTime.now();

        final todayEntries = entriesStartingOnDay(state.statsEntries, now);
        final weekEntries = entriesInCurrentWeek(state.statsEntries, now);
        final todayTotal = _sumDur(todayEntries);
        final weekTotal = _sumDur(weekEntries);
        final last = _latestSession(state.statsEntries);

        final workspaceNames = {for (final w in state.workspaces) w.id: w.name};

        late final VoidCallback primaryOnPressed;
        late final String primaryLabel;
        late final IconData primaryIcon;
        switch (state.runState) {
          case TimerRunState.idle:
            primaryOnPressed = () {
              if (state.activeWorkspace.isArchived) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.timerArchivedProjectSnack)),
                );
                return;
              }
              cubit.play();
            };
            primaryLabel = l10n.timerActionStart;
            primaryIcon = Icons.play_arrow_rounded;
            break;
          case TimerRunState.running:
            primaryOnPressed = cubit.pause;
            primaryLabel = l10n.timerPause;
            primaryIcon = Icons.pause_rounded;
            break;
          case TimerRunState.paused:
            primaryOnPressed = () {
              if (state.activeWorkspace.isArchived) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.timerArchivedProjectSnack)),
                );
                return;
              }
              cubit.play();
            };
            primaryLabel = l10n.timerActionResume;
            primaryIcon = Icons.play_arrow_rounded;
            break;
        }

        final pickerList = _pickerProjects(state);
        final pickerValue = _pickerWorkspaceId(state);

        final pulse =
            state.runState == TimerRunState.running &&
            state.elapsed.inSeconds.isEven;

        final dateFmt = DateFormat.yMMMd(lc);
        final timeFmt = DateFormat.Hm(lc);
        final noStatsYet = state.statsEntries.isEmpty;

        return CustomScrollView(
          slivers: [
            if (state.historyOfflineFallback)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.cloud_off_outlined,
                            size: 22,
                            color: scheme.onSecondaryContainer,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l10n.syncOfflineBanner,
                              style: textTheme.bodySmall?.copyWith(
                                color: scheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Text(
                  l10n.navTimer,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.timerWorkspace,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InputDecorator(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                          ),
                          child: state.workspaces.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  child: Text(l10n.timerWorkspaceLoading),
                                )
                              : DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    value: pickerValue,
                                    items: pickerList
                                        .map(
                                          (w) => DropdownMenuItem<String>(
                                            value: w.id,
                                            child: Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 8,
                                                  backgroundColor:
                                                      workspaceAccentColor(
                                                        w.colorHex,
                                                        scheme.primary,
                                                      ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    w.isArchived
                                                        ? '${w.name} · ${l10n.projectsArchived}'
                                                        : w.name,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged:
                                        state.runState == TimerRunState.idle
                                        ? (value) {
                                            if (value == null) return;
                                            cubit.setActiveWorkspace(value);
                                          }
                                        : null,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          l10n.timerWorkMode,
                          style: textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SegmentedButton<WorkMode>(
                          segments: [
                            ButtonSegment(
                              value: WorkMode.remote,
                              label: Text(WorkMode.remote.localized(l10n)),
                              icon: const Icon(Icons.home_outlined, size: 20),
                            ),
                            ButtonSegment(
                              value: WorkMode.office,
                              label: Text(WorkMode.office.localized(l10n)),
                              icon: const Icon(
                                Icons.apartment_outlined,
                                size: 20,
                              ),
                            ),
                          ],
                          selected: {state.nextSessionMode},
                          onSelectionChanged: (s) {
                            if (state.canChangeMode) cubit.setNextMode(s.first);
                          },
                          showSelectedIcon: false,
                          style: ButtonStyle(
                            visualDensity: VisualDensity.comfortable,
                            tapTargetSize: MaterialTapTargetSize.padded,
                          ),
                        ),
                        if (!state.canChangeMode) ...[
                          const SizedBox(height: 8),
                          Text(
                            l10n.timerLockedMode,
                            style: textTheme.bodySmall?.copyWith(
                              color: scheme.outline,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              sliver: SliverToBoxAdapter(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(
                    vertical: 32,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppLayout.radiusLg + 8),
                    color: switch (state.runState) {
                      TimerRunState.running =>
                        scheme.primaryContainer.withValues(
                          alpha: theme.brightness == Brightness.dark
                              ? 0.2
                              : 0.32,
                        ),
                      TimerRunState.paused =>
                        scheme.tertiaryContainer.withValues(
                          alpha: theme.brightness == Brightness.dark
                              ? 0.16
                              : 0.28,
                        ),
                      TimerRunState.idle =>
                        scheme.surfaceContainerHighest.withValues(
                          alpha: theme.brightness == Brightness.dark
                              ? 0.35
                              : 0.55,
                        ),
                    },
                    border: Border.all(
                      color: switch (state.runState) {
                        TimerRunState.idle => scheme.outlineVariant.withValues(
                          alpha: 0.55,
                        ),
                        TimerRunState.running => scheme.primary.withValues(
                          alpha: pulse ? 0.9 : 0.5,
                        ),
                        TimerRunState.paused => scheme.tertiary.withValues(
                          alpha: 0.55,
                        ),
                      },
                      width: state.runState == TimerRunState.idle ? 1 : 2.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Semantics(
                        label:
                            '${l10n.navTimer}: ${_formatClock(state.elapsed)}',
                        child: Text(
                          _formatClock(state.elapsed),
                          textAlign: TextAlign.center,
                          style: textTheme.displayMedium?.copyWith(
                            fontFamily: 'monospace',
                            fontFeatures: const [FontFeature.tabularFigures()],
                            letterSpacing: 3,
                            fontWeight: FontWeight.w600,
                            height: 1.05,
                            fontSize: (textTheme.displayMedium?.fontSize ?? 45)
                                .clamp(38, 56),
                            color: switch (state.runState) {
                              TimerRunState.running => scheme.primary,
                              TimerRunState.paused => scheme.onSurfaceVariant,
                              TimerRunState.idle => scheme.onSurface,
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.circle,
                            size: 10,
                            color: switch (state.runState) {
                              TimerRunState.idle => scheme.outline,
                              TimerRunState.running => scheme.primary,
                              TimerRunState.paused => scheme.tertiary,
                            },
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _statusLabel(state.runState, l10n).toUpperCase(),
                            style: textTheme.labelLarge?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                      if (state.workspaces.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.surface.withValues(
                              alpha: theme.brightness == Brightness.dark
                                  ? 0.22
                                  : 0.75,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppLayout.radiusMd,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 10,
                                backgroundColor: workspaceAccentColor(
                                  state.activeWorkspace.colorHex,
                                  scheme.primary,
                                ).withValues(alpha: 0.5),
                                child: Icon(
                                  Icons.folder_outlined,
                                  size: 16,
                                  color: scheme.onSurface,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  state.activeWorkspace.name,
                                  style: textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (state.activeWorkspace.hourlyRate != null &&
                            state.activeWorkspace.hourlyRate! > 0) ...[
                          const SizedBox(height: 8),
                          Text(
                            '${state.activeWorkspace.hourlyRate} '
                            '${state.activeWorkspace.currencyCode ?? ''}/h',
                            style: textTheme.labelMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: AppLayout.primaryButtonHeight,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            textStyle: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onPressed: primaryOnPressed,
                          icon: Icon(primaryIcon, size: 26),
                          label: Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Text(primaryLabel),
                          ),
                        ),
                      ),
                    ),
                    if (state.runState != TimerRunState.idle) ...[
                      const SizedBox(width: 12),
                      Tooltip(
                        message: l10n.timerStop,
                        child: SizedBox(
                          width: AppLayout.primaryButtonHeight,
                          height: AppLayout.primaryButtonHeight,
                          child: IconButton.filledTonal(
                            style: IconButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppLayout.radiusSm + 2,
                                ),
                              ),
                            ),
                            onPressed: () async {
                              final settings = context.read<SettingsCubit>();
                              StopSessionDebriefResult? r;
                              if (settings.state.showDebriefAfterStop &&
                                  context.mounted) {
                                r = await showStopSessionDebriefDialog(context);
                              }
                              if (!context.mounted) return;
                              if (r?.neverShowAgain == true) {
                                await settings.setShowDebriefAfterStop(false);
                              }
                              final skipFields = r == null || r.skipped;
                              await cubit.stop(
                                taskTitle: skipFields ? null : r.taskTitle,
                                note: skipFields ? null : r.note,
                                isBillable: r?.isBillable ?? true,
                              );
                            },
                            icon: const Icon(Icons.stop_circle_outlined),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Text(
                  l10n.statsBasicTitle,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            if (noStatsYet)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: AppEmptyState(
                    icon: Icons.event_note_outlined,
                    title: l10n.dashboardNoSessionsTitle,
                    body: l10n.dashboardNoSessionsBody,
                  ),
                ),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: l10n.dashboardToday,
                          value: formatDurationHm(todayTotal),
                          icon: Icons.wb_sunny_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: l10n.dashboardThisWeek,
                          value: formatDurationHm(weekTotal),
                          icon: Icons.date_range_outlined,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (last != null)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  sliver: SliverToBoxAdapter(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  last.mode == WorkMode.remote
                                      ? Icons.home_outlined
                                      : Icons.apartment_outlined,
                                  color: scheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    l10n.dashboardLastSession,
                                    style: textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              dateFmt.format(last.start),
                              style: textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${timeFmt.format(last.start)} — ${timeFmt.format(last.end)}',
                              style: textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              formatDurationHm(last.duration),
                              style: textTheme.labelLarge?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if ((workspaceNames[last.workspaceId] ?? '')
                                .isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                l10n.historyWorkspaceLabel(
                                  workspaceNames[last.workspaceId] ?? '',
                                ),
                                style: textTheme.bodySmall?.copyWith(
                                  color: scheme.outline,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
            const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22, color: scheme.primary),
            const SizedBox(height: 12),
            Text(
              title,
              style: textTheme.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
