import 'dart:io';

import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

import '../services/ios_deep_link_nav.dart';
import 'history_tab.dart';
import 'settings_tab.dart';
import 'stats_tab.dart';
import 'timer_tab.dart';
import 'workspaces_tab.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.onSignOut});

  final Future<void> Function() onSignOut;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    if (Platform.isIOS) {
      IosDeepLinkNav.instance.init();
      IosDeepLinkNav.instance.pendingTabIndex.addListener(_onIosDeepLinkTab);
    }
  }

  @override
  void dispose() {
    if (Platform.isIOS) {
      IosDeepLinkNav.instance.pendingTabIndex.removeListener(_onIosDeepLinkTab);
    }
    super.dispose();
  }

  void _onIosDeepLinkTab() {
    final next = IosDeepLinkNav.instance.pendingTabIndex.value;
    if (next == null || !mounted) return;
    setState(() => _index = next.clamp(0, 4));
    IosDeepLinkNav.instance.pendingTabIndex.value = null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        centerTitle: true,
        elevation: 0,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: widget.onSignOut,
            icon: const Icon(Icons.logout),
            tooltip: l10n.signOut,
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: switch (_index) {
          0 => const TimerTab(key: ValueKey('timer')),
          1 => const HistoryTab(key: ValueKey('history')),
          2 => const StatsTab(key: ValueKey('stats')),
          3 => const WorkspacesTab(key: ValueKey('workspaces')),
          4 => const SettingsTab(key: ValueKey('settings')),
          _ => const TimerTab(key: ValueKey('timer')),
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.timer_outlined),
            selectedIcon: const Icon(Icons.timer),
            label: l10n.navTimer,
          ),
          NavigationDestination(
            icon: const Icon(Icons.history_outlined),
            selectedIcon: const Icon(Icons.history),
            label: l10n.navHistory,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: const Icon(Icons.bar_chart),
            label: l10n.navStats,
          ),
          NavigationDestination(
            icon: const Icon(Icons.workspaces_outline),
            selectedIcon: const Icon(Icons.workspaces),
            label: l10n.navWorkspaces,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.navSettings,
          ),
        ],
      ),
    );
  }
}
