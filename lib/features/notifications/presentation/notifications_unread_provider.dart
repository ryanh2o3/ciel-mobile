import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Client-derived unread flag for the shell tab badge (no server unread count).
final notificationsHasUnreadProvider = NotifierProvider<
    NotificationsHasUnreadNotifier, bool>(
  NotificationsHasUnreadNotifier.new,
);

class NotificationsHasUnreadNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setHasUnread({required bool value}) {
    if (state != value) {
      state = value;
    }
  }
}
