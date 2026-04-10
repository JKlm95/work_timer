import 'package:flutter/material.dart';

import '../controllers/work_timer_controller.dart';
import 'history_tab.dart';
import 'timer_tab.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.controller});

  final WorkTimerController controller;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Timer'),
        centerTitle: true,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _index == 0
            ? TimerTab(key: const ValueKey('timer'), controller: widget.controller)
            : HistoryTab(key: const ValueKey('history'), controller: widget.controller),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            selectedIcon: Icon(Icons.timer),
            label: 'Timer',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Historia',
          ),
        ],
      ),
    );
  }
}
