import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../l10n/app_localizations.dart';

import '../bloc/timer_cubit.dart';
import '../l10n/work_mode_strings.dart';
import '../models/work_mode.dart';

class TimerTab extends StatelessWidget {
  const TimerTab({super.key});

  static String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  static String _stateLabel(TimerRunState state, AppLocalizations l10n) {
    return switch (state) {
      TimerRunState.idle => l10n.timerReady,
      TimerRunState.running => l10n.timerRunning,
      TimerRunState.paused => l10n.timerPaused,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<TimerCubit, TimerState>(
      builder: (context, state) {
        final cubit = context.read<TimerCubit>();
        final scheme = Theme.of(context).colorScheme;
        final canSetMode = state.canChangeMode;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.timerWorkMode,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
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
                          value: state.activeWorkspaceId,
                          items: state.workspaces
                              .map(
                                (w) => DropdownMenuItem<String>(
                                  value: w.id,
                                  child: Text(w.name),
                                ),
                              )
                              .toList(),
                          onChanged: state.runState == TimerRunState.idle
                              ? (value) {
                                  if (value == null) return;
                                  cubit.setActiveWorkspace(value);
                                }
                              : null,
                        ),
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
                  if (canSetMode) cubit.setNextMode(s.first);
                },
                showSelectedIcon: false,
              ),
              if (!canSetMode) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.timerLockedMode,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: scheme.outline),
                ),
              ],
              const Spacer(),
              Text(
                _formatDuration(state.elapsed),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _stateLabel(state.runState, l10n),
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: scheme.secondary),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: cubit.play,
                    icon: const Icon(Icons.play_arrow),
                    label: Text(l10n.timerPlay),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: state.runState == TimerRunState.running
                        ? cubit.pause
                        : null,
                    icon: const Icon(Icons.pause),
                    label: Text(l10n.timerPause),
                  ),
                  FilledButton.icon(
                    onPressed: state.runState != TimerRunState.idle
                        ? () => cubit.stop()
                        : null,
                    icon: const Icon(Icons.stop),
                    label: Text(l10n.timerStop),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
