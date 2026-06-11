import 'package:ciel_mobile/domain/entities/app_notification.dart';

String notificationMessage(AppNotification notification) {
  final payload = notification.payload;
  switch (notification.notificationType) {
    case 'user_followed':
      final handle = payload['follower_handle']?.toString();
      if (handle != null && handle.isNotEmpty) {
        return '@$handle started following you';
      }
      return 'Someone started following you';
    case 'post_liked':
      final handle = payload['liker_handle']?.toString();
      if (handle != null && handle.isNotEmpty) {
        return '@$handle liked your post';
      }
      return 'Someone liked your post';
    case 'post_commented':
      final handle = payload['commenter_handle']?.toString();
      if (handle != null && handle.isNotEmpty) {
        return '@$handle commented on your post';
      }
      return 'Someone commented on your post';
    case 'story_reaction':
      final emoji = payload['emoji']?.toString();
      final handle = payload['reactor_handle']?.toString();
      if (handle != null && emoji != null) {
        return '@$handle reacted $emoji to your story';
      }
      if (emoji != null) {
        return 'Someone reacted $emoji to your story';
      }
      return 'Someone reacted to your story';
    default:
      return notification.notificationType.replaceAll('_', ' ');
  }
}
