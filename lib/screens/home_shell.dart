import 'dart:io';

import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

import '../services/ios_deep_link_nav.dart';
import '../widgets/home_ring_nav_bar.dart';
import '../widgets/home_shell_tab_scope.dart';
import 'calendar_tab.dart';
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
    setState(() => _index = next.clamp(0, 5));
    IosDeepLinkNav.instance.pendingTabIndex.value = null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return HomeShellTabScope(
      goToTab: (i) => setState(() => _index = i.clamp(0, 5)),
      child: Scaffold(
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
            3 => const CalendarTab(key: ValueKey('calendar')),
            4 => const WorkspacesTab(key: ValueKey('workspaces')),
            5 => const SettingsTab(key: ValueKey('settings')),
            _ => const TimerTab(key: ValueKey('timer')),
          },
        ),
        bottomNavigationBar: HomeRingNavBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: [
            HomeRingNavDestination(
              icon: Icons.timer_outlined,
              selectedIcon: Icons.timer,
              label: l10n.navTimer,
            ),
            HomeRingNavDestination(
              icon: Icons.history_outlined,
              selectedIcon: Icons.history,
              label: l10n.navHistory,
            ),
            HomeRingNavDestination(
              icon: Icons.bar_chart_outlined,
              selectedIcon: Icons.bar_chart,
              label: l10n.navStats,
            ),
            HomeRingNavDestination(
              icon: Icons.calendar_month_outlined,
              selectedIcon: Icons.calendar_month,
              label: l10n.navCalendar,
            ),
            HomeRingNavDestination(
              icon: Icons.folder_outlined,
              selectedIcon: Icons.folder,
              label: l10n.navWorkspaces,
            ),
            HomeRingNavDestination(
              icon: Icons.settings_outlined,
              selectedIcon: Icons.settings,
              label: l10n.navSettings,
            ),
          ],
        ),
      ),
    );
  }
}
