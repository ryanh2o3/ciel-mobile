import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Swift `AppTabsView`: Home, Create (modal), Notifications, Profile.
class MainShellScreen extends StatelessWidget {
  const MainShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  int _visualIndexFromBranch(int branchIndex) {
    return switch (branchIndex) {
      0 => 0,
      1 => 2,
      2 => 3,
      _ => 0,
    };
  }

  int _branchFromVisualIndex(int visualIndex) {
    if (visualIndex <= 0) return 0;
    if (visualIndex >= 3) return 2;
    return visualIndex - 1;
  }

  @override
  Widget build(BuildContext context) {
    final selectedVisual = _visualIndexFromBranch(navigationShell.currentIndex);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedVisual,
        onDestinationSelected: (visualIndex) {
          if (visualIndex == 1) {
            context.push('/create');
            return;
          }
          navigationShell.goBranch(_branchFromVisualIndex(visualIndex));
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_box_outlined),
            selectedIcon: Icon(Icons.add_box),
            label: 'Create',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Notifications',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
