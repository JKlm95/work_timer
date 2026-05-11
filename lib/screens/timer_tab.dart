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
import '../utils/calendar_utils.dart';
import '../utils/format_duration.dart';
import '../utils/workspace_color.dart';
import '../widgets/stop_session_debrief_dialog.dart';

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
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        InputDecorator(
                          decoration: InputDecoration(
                            labelText: l10n.timerWorkspace,
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                          child: state.workspaces.isEmpty
                              ? Text(l10n.timerWorkspaceLoading)
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
                                                  radius: 7,
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
                        const SizedBox(height: 16),
                        Text(
                          l10n.timerWorkMode,
                          style: textTheme.titleSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<WorkMode>(
                          segments: [
                            ButtonSegment(
                              value: WorkMode.remote,
                              label: Text(WorkMode.remote.localized(l10n)),
                              icon: const Icon(Icons.home_outlined),
                            ),
                            ButtonSegment(
                              value: WorkMode.office,
                              label: Text(WorkMode.office.localized(l10n)),
                              icon: const Icon(Icons.apartment_outlined),
                            ),
                          ],
                          selected: {state.nextSessionMode},
                          onSelectionChanged: (s) {
                            if (state.canChangeMode) cubit.setNextMode(s.first);
                          },
                          showSelectedIcon: false,
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
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              sliver: SliverToBoxAdapter(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(
                    vertical: 28,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: switch (state.runState) {
                        TimerRunState.idle => scheme.outlineVariant.withValues(
                          alpha: 0.6,
                        ),
                        TimerRunState.running => scheme.primary.withValues(
                          alpha: pulse ? 0.85 : 0.45,
                        ),
                        TimerRunState.paused => scheme.tertiary.withValues(
                          alpha: 0.65,
                        ),
                      },
                      width: state.runState == TimerRunState.idle ? 1 : 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _formatClock(state.elapsed),
                        textAlign: TextAlign.center,
                        style: textTheme.displayLarge?.copyWith(
                          fontFamily: 'monospace',
                          fontFeatures: const [FontFeature.tabularFigures()],
                          letterSpacing: 2,
                          fontWeight: FontWeight.w500,
                          color: switch (state.runState) {
                            TimerRunState.running => scheme.primary,
                            TimerRunState.paused => scheme.onSurfaceVariant,
                            TimerRunState.idle => scheme.onSurface,
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
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
                            _statusLabel(state.runState, l10n),
                            style: textTheme.titleMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (state.workspaces.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 8,
                              backgroundColor: workspaceAccentColor(
                                state.activeWorkspace.colorHex,
                                scheme.primary,
                              ).withValues(alpha: 0.45),
                              child: Icon(
                                Icons.folder_outlined,
                                size: 14,
                                color: scheme.onSurface,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                state.activeWorkspace.name,
                                style: textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        if (state.activeWorkspace.hourlyRate != null &&
                            state.activeWorkspace.hourlyRate! > 0) ...[
                          const SizedBox(height: 8),
                          Text(
                            '${state.activeWorkspace.hourlyRate} '
                            '${state.activeWorkspace.currencyCode ?? ''}/h',
                            style: textTheme.bodySmall?.copyWith(
                              color: scheme.outline,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 54,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          textStyle: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: primaryOnPressed,
                        icon: Icon(primaryIcon),
                        label: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(primaryLabel),
                        ),
                      ),
                    ),
                    if (state.runState != TimerRunState.idle) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
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
                          label: Text(l10n.timerStop),
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
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.event_note_outlined,
                            size: 48,
                            color: scheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.dashboardNoSessionsTitle,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.dashboardNoSessionsBody,
                            style: textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
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
        padding: const EdgeInsets.all(16),
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
