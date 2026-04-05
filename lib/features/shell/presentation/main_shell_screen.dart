import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Branch order for StatefulNavigationShell must match app router branches:
/// 0 = `/feed`, 1 = `/notifications`, 2 = `/profile`.
abstract final class _ShellBranchIndex {
  static const int feed = 0;
  static const int notifications = 1;
  static const int profile = 2;
}

/// Bottom bar positions: Create is slot 1 but is not a shell branch
/// (opens `/create` on root stack).
abstract final class _NavBarSlot {
  static const int home = 0;
  static const int create = 1;
  static const int notifications = 2;
  static const int profile = 3;
}

/// Swift `AppTabsView`: Home, Create (modal), Notifications, Profile.
/// Uses [CupertinoTabBar] on iOS for native chrome; Material [NavigationBar] elsewhere.
class MainShellScreen extends StatelessWidget {
  const MainShellScreen({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  int _navBarIndexFromBranch(int branchIndex) {
    return switch (branchIndex) {
      _ShellBranchIndex.feed => _NavBarSlot.home,
      _ShellBranchIndex.notifications => _NavBarSlot.notifications,
      _ShellBranchIndex.profile => _NavBarSlot.profile,
      _ => _NavBarSlot.home,
    };
  }

  int _branchFromNavBarSlot(int slotIndex) {
    if (slotIndex <= _NavBarSlot.home) return _ShellBranchIndex.feed;
    if (slotIndex >= _NavBarSlot.profile) return _ShellBranchIndex.profile;
    return slotIndex - 1;
  }

  void _onSlotSelected(BuildContext context, int slotIndex) {
    if (slotIndex == _NavBarSlot.create) {
      unawaited(context.push('/create'));
      return;
    }
    navigationShell.goBranch(_branchFromNavBarSlot(slotIndex));
  }

  @override
  Widget build(BuildContext context) {
    final selectedNavBarIndex =
        _navBarIndexFromBranch(navigationShell.currentIndex);
    final isIos = Theme.of(context).platform == TargetPlatform.iOS;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: isIos
          ? CupertinoTabBar(
              currentIndex: selectedNavBarIndex,
              onTap: (i) => _onSlotSelected(context, i),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.add_circled),
                  label: 'Create',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.heart),
                  label: 'Notifications',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.person),
                  label: 'Profile',
                ),
              ],
            )
          : NavigationBar(
              selectedIndex: selectedNavBarIndex,
              onDestinationSelected: (slotIndex) =>
                  _onSlotSelected(context, slotIndex),
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
