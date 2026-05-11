import 'package:flutter/material.dart';

/// Model jednej zakładki (ikony + etykieta pod środkiem).
class HomeRingNavDestination {
  const HomeRingNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Dolna nawigacja: **środek = wybrana** zakładka (większa), **boki** to sąsiedzi
/// na „kole” (mniejsze). Widoczne jest 5 slotów z [length] zakładek (cyklicznie).
/// Swipe w lewo / prawo przesuwa aktywną zakładkę o jeden.
class HomeRingNavBar extends StatelessWidget {
  const HomeRingNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<HomeRingNavDestination> destinations;

  static const int _slots = 5;

  @override
  Widget build(BuildContext context) {
    final n = destinations.length;
    assert(n >= 3, 'HomeRingNavBar needs at least 3 destinations');
    final safeIndex = selectedIndex.clamp(0, n - 1);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    int wrap(int i) => (i % n + n) % n;

    final ring = List.generate(_slots, (k) => wrap(safeIndex - 2 + k));

    return Material(
      elevation: 6,
      shadowColor: Colors.black26,
      color: Color.alphaBlend(
        scheme.primary.withValues(alpha: 0.04),
        scheme.surfaceContainerHighest,
      ),
      child: SafeArea(
        top: false,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragEnd: (details) {
            final v = details.primaryVelocity ?? 0;
            if (v < -120) {
              onDestinationSelected(wrap(safeIndex + 1));
            } else if (v > 120) {
              onDestinationSelected(wrap(safeIndex - 1));
            }
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(2, 10, 2, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(_slots, (slot) {
                final tabIndex = ring[slot];
                final isCenter = slot == 2;
                final d = destinations[tabIndex];

                final content = isCenter
                    ? _CenterRingItem(
                        icon: d.selectedIcon,
                        label: d.label,
                        scheme: scheme,
                        textTheme: textTheme,
                      )
                    : _SideRingItem(
                        icon: d.icon,
                        label: d.label,
                        scheme: scheme,
                        onTap: () => onDestinationSelected(tabIndex),
                      );

                return Expanded(
                  flex: isCenter ? 26 : 16,
                  child: Center(
                    child: AnimatedScale(
                      scale: isCenter ? 1.0 : 0.78,
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                      child: AnimatedOpacity(
                        opacity: isCenter ? 1.0 : 0.68,
                        duration: const Duration(milliseconds: 240),
                        child: content,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _CenterRingItem extends StatelessWidget {
  const _CenterRingItem({
    required this.icon,
    required this.label,
    required this.scheme,
    required this.textTheme,
  });

  final IconData icon;
  final String label;
  final ColorScheme scheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.22),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, size: 28, color: scheme.onPrimaryContainer),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: textTheme.labelMedium?.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SideRingItem extends StatelessWidget {
  const _SideRingItem({
    required this.icon,
    required this.label,
    required this.scheme,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final ColorScheme scheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Icon(icon, size: 24, color: scheme.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}
