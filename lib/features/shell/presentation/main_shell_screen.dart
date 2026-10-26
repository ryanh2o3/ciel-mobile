import 'dart:async';

import 'package:ciel_mobile/app/providers/dependency_providers.dart';
import 'package:ciel_mobile/features/notifications/presentation/notifications_unread_provider.dart';
import 'package:ciel_mobile/ui/ciel_create_chooser_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Branch order for StatefulNavigationShell must match app router branches:
/// 0 = `/feed`, 1 = `/notifications`, 2 = `/profile`.
abstract final class _ShellBranchIndex {
  static const int feed = 0;
  static const int notifications = 1;
  static const int profile = 2;
}

/// Bottom bar positions: Create is slot 1 but is not a shell branch
/// (opens create chooser on root stack).
abstract final class _NavBarSlot {
  static const int home = 0;
  static const int create = 1;
  static const int notifications = 2;
  static const int profile = 3;
}

/// Swift `AppTabsView`: Home, Create (modal), Notifications, Profile.
class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_prefetchUnread());
    });
  }

  Future<void> _prefetchUnread() async {
    try {
      final page = await ref
          .read(notificationsUseCaseProvider)
          .fetchNotifications(limit: 20);
      final hasUnread = page.items.any((n) => n.readAt == null);
      if (mounted) {
        ref
            .read(notificationsHasUnreadProvider.notifier)
            .setHasUnread(value: hasUnread);
      }
    } on Object {
      // Badge stays false until NotificationsScreen loads.
    }
  }

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

  Future<void> _onCreate(BuildContext context) async {
    final choice = await showCielCreateChooserSheet(context);
    if (!context.mounted || choice == null) {
      return;
    }
    switch (choice) {
      case CielCreateChoice.post:
        await context.push('/create');
      case CielCreateChoice.story:
        await context.push('/stories/create');
    }
  }

  void _onSlotSelected(BuildContext context, int slotIndex) {
    if (slotIndex == _NavBarSlot.create) {
      unawaited(_onCreate(context));
      return;
    }
    widget.navigationShell.goBranch(_branchFromNavBarSlot(slotIndex));
  }

  @override
  Widget build(BuildContext context) {
    final selectedNavBarIndex = _navBarIndexFromBranch(
      widget.navigationShell.currentIndex,
    );
    final isIos = Theme.of(context).platform == TargetPlatform.iOS;
    final hasUnread = ref.watch(notificationsHasUnreadProvider);

    Widget notifIcon({required IconData outlined, required IconData filled}) {
      final selected = selectedNavBarIndex == _NavBarSlot.notifications;
      return Badge(
        isLabelVisible: hasUnread,
        smallSize: 8,
        child: Icon(selected ? filled : outlined),
      );
    }

    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: isIos
          ? CupertinoTabBar(
              currentIndex: selectedNavBarIndex,
              onTap: (i) => _onSlotSelected(context, i),
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.home),
                  label: 'Home',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.add_circled),
                  label: 'Create',
                ),
                BottomNavigationBarItem(
                  icon: notifIcon(
                    outlined: CupertinoIcons.heart,
                    filled: CupertinoIcons.heart_fill,
                  ),
                  label: 'Notifications',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.person),
                  label: 'Profile',
                ),
              ],
            )
          : NavigationBar(
              selectedIndex: selectedNavBarIndex,
              onDestinationSelected: (slotIndex) =>
                  _onSlotSelected(context, slotIndex),
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.add_box_outlined),
                  selectedIcon: Icon(Icons.add_box),
                  label: 'Create',
                ),
                NavigationDestination(
                  icon: notifIcon(
                    outlined: Icons.favorite_border,
                    filled: Icons.favorite,
                  ),
                  selectedIcon: notifIcon(
                    outlined: Icons.favorite_border,
                    filled: Icons.favorite,
                  ),
                  label: 'Notifications',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
    );
  }
}
