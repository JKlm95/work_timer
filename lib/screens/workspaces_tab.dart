import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../l10n/app_localizations.dart';

import '../bloc/timer_cubit.dart';
import '../models/workspace.dart';
import '../utils/workspace_color.dart';
import '../widgets/project_detail_sheet.dart';
import '../widgets/project_editor_sheet.dart';

class WorkspacesTab extends StatelessWidget {
  const WorkspacesTab({super.key});

  Future<void> _openEditor(BuildContext context, {Workspace? workspace}) async {
    final saved = await showProjectEditorSheet(context, initial: workspace);
    if (saved == null || !context.mounted) return;
    await context.read<TimerCubit>().saveProject(saved);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return BlocBuilder<TimerCubit, TimerState>(
      builder: (context, state) {
        final open =
            state.workspaces.where((w) => !w.isArchived).toList(growable: false)
              ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        final archived =
            state.workspaces.where((w) => w.isArchived).toList(growable: false)
              ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

        Widget tile(Workspace workspace) {
          final selected = workspace.id == state.activeWorkspaceId;
          final accent = workspaceAccentColor(
            workspace.colorHex,
            scheme.primary,
          );

          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: accent.withValues(alpha: 0.4),
                child: Icon(
                  selected ? Icons.check_circle : Icons.folder_outlined,
                  color: scheme.onSurface,
                  size: 22,
                ),
              ),
              title: Text(workspace.name),
              subtitle: Text(
                selected
                    ? l10n.workspacesActiveDetailHint
                    : l10n.workspacesInactiveDetailHint,
              ),
              onTap: () =>
                  showProjectDetailSheet(context, workspace: workspace),
              trailing: PopupMenuButton<String>(
                onSelected: (value) async {
                  if (!context.mounted) return;
                  if (value == 'edit') {
                    await _openEditor(context, workspace: workspace);
                  } else if (value == 'archive') {
                    await context.read<TimerCubit>().saveProject(
                      workspace.copyWith(
                        isArchived: true,
                        updatedAt: DateTime.now(),
                      ),
                    );
                  } else if (value == 'restore') {
                    await context.read<TimerCubit>().saveProject(
                      workspace.copyWith(
                        isArchived: false,
                        updatedAt: DateTime.now(),
                      ),
                    );
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text(l10n.historyMenuEdit),
                  ),
                  if (!workspace.isArchived)
                    PopupMenuItem(
                      value: 'archive',
                      child: Text(l10n.projectsArchiveAction),
                    )
                  else
                    PopupMenuItem(
                      value: 'restore',
                      child: Text(l10n.projectsRestoreAction),
                    ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            children: [
              Text(
                l10n.navWorkspaces,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              if (open.isEmpty && archived.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      children: [
                        Icon(
                          Icons.folder_off_outlined,
                          size: 52,
                          color: scheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.workspacesEmptyTitle,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.workspacesEmptyBody,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: scheme.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: () => _openEditor(context),
                          icon: const Icon(Icons.add),
                          label: Text(l10n.projectsFab),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                ...open.map(tile),
                if (archived.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    l10n.projectsArchivedSection,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...archived.map(tile),
                ],
              ],
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openEditor(context),
            icon: const Icon(Icons.add),
            label: Text(l10n.projectsFab),
          ),
        );
      },
    );
  }
}
