import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../l10n/app_localizations.dart';

import '../bloc/timer_cubit.dart';
import '../models/workspace.dart';

class WorkspacesTab extends StatelessWidget {
  const WorkspacesTab({super.key});

  Future<void> _create(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.workspacesNewTitle),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(labelText: l10n.workspacesNameLabel),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(ctrl.text.trim()),
            child: Text(l10n.commonAdd),
          ),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty || !context.mounted) return;
    await context.read<TimerCubit>().createWorkspace(name);
  }

  Future<void> _rename(
    BuildContext context, {
    required Workspace workspace,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final ctrl = TextEditingController(text: workspace.name);
    final next = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.workspacesRenameTitle),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(labelText: l10n.workspacesNameLabel),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(ctrl.text.trim()),
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
    if (next == null || next.trim().isEmpty || !context.mounted) return;
    await context.read<TimerCubit>().renameWorkspace(
      workspaceId: workspace.id,
      name: next,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<TimerCubit, TimerState>(
      builder: (context, state) {
        return Scaffold(
          body: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.workspaces.length,
            itemBuilder: (context, index) {
              final workspace = state.workspaces[index];
              final selected = workspace.id == state.activeWorkspaceId;
              return Card(
                child: ListTile(
                  leading: Icon(
                    selected ? Icons.check_circle : Icons.circle_outlined,
                  ),
                  title: Text(workspace.name),
                  subtitle: Text(
                    selected ? l10n.workspacesActive : l10n.workspacesInactive,
                  ),
                  onTap: () => context.read<TimerCubit>().setActiveWorkspace(
                    workspace.id,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _rename(context, workspace: workspace),
                  ),
                ),
              );
            },
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _create(context),
            icon: const Icon(Icons.add),
            label: Text(l10n.workspacesFab),
          ),
        );
      },
    );
  }
}
