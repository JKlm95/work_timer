import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/timer_cubit.dart';
import '../models/workspace.dart';

class WorkspacesTab extends StatelessWidget {
  const WorkspacesTab({super.key});

  Future<void> _create(BuildContext context) async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nowy workspace'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Nazwa'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(ctrl.text.trim()),
            child: const Text('Dodaj'),
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
    final ctrl = TextEditingController(text: workspace.name);
    final next = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zmien nazwe'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Nazwa'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(ctrl.text.trim()),
            child: const Text('Zapisz'),
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
    return BlocBuilder<TimerCubit, TimerState>(
      builder: (context, state) {
        return Scaffold(
          body: ListView.builder(
            padding: const EdgeInsets.all(12),
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
                  subtitle: Text(selected ? 'Aktywny' : 'Nieaktywny'),
                  onTap: () =>
                      context.read<TimerCubit>().setActiveWorkspace(workspace.id),
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
            label: const Text('Dodaj workspace'),
          ),
        );
      },
    );
  }
}
