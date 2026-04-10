import 'package:flutter/material.dart';

import '../controllers/work_timer_controller.dart';
import '../models/work_mode.dart';

class TimerTab extends StatelessWidget {
  const TimerTab({super.key, required this.controller});

  final WorkTimerController controller;

  static String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  static String _stateLabel(TimerRunState state) {
    return switch (state) {
      TimerRunState.idle => 'Gotowy',
      TimerRunState.running => 'Liczę…',
      TimerRunState.paused => 'Pauza',
    };
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final scheme = Theme.of(context).colorScheme;
        final canSetMode = controller.canChangeMode;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tryb pracy',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SegmentedButton<WorkMode>(
                segments: [
                  ButtonSegment(
                    value: WorkMode.remote,
                    label: Text(WorkMode.remote.labelPl),
                    icon: const Icon(Icons.home_outlined),
                  ),
                  ButtonSegment(
                    value: WorkMode.office,
                    label: Text(WorkMode.office.labelPl),
                    icon: const Icon(Icons.apartment_outlined),
                  ),
                ],
                selected: {controller.nextSessionMode},
                onSelectionChanged: (s) {
                  if (canSetMode) controller.setNextMode(s.first);
                },
                showSelectedIcon: false,
              ),
              if (!canSetMode) ...[
                const SizedBox(height: 8),
                Text(
                  'Tryb zablokowany na czas sesji.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.outline,
                      ),
                ),
              ],
              const Spacer(),
              Text(
                _formatDuration(controller.elapsed),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                      letterSpacing: 2,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                _stateLabel(controller.runState),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: scheme.secondary,
                    ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () => controller.play(),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Play'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: controller.runState == TimerRunState.running
                        ? controller.pause
                        : null,
                    icon: const Icon(Icons.pause),
                    label: const Text('Pause'),
                  ),
                  FilledButton.icon(
                    onPressed: controller.runState != TimerRunState.idle
                        ? () => controller.stop()
                        : null,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop'),
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
