import 'package:ciel_mobile/domain/entities/app_notification.dart';
import 'package:ciel_mobile/features/notifications/notification_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('notificationMessage', () {
    test('formats user_followed with handle', () {
      final message = notificationMessage(
        AppNotification(
          id: '1',
          userId: 'u1',
          notificationType: 'user_followed',
          payload: const {'follower_handle': 'alice'},
          createdAt: DateTime.utc(2026),
        ),
      );
      expect(message, '@alice started following you');
    });

    test('formats post_liked without handle', () {
      final message = notificationMessage(
        AppNotification(
          id: '1',
          userId: 'u1',
          notificationType: 'post_liked',
          payload: const {},
          createdAt: DateTime.utc(2026),
        ),
      );
      expect(message, 'Someone liked your post');
    });

    test('formats story_reaction with emoji and handle', () {
      final message = notificationMessage(
        AppNotification(
          id: '1',
          userId: 'u1',
          notificationType: 'story_reaction',
          payload: const {'emoji': '❤️', 'reactor_handle': 'bob'},
          createdAt: DateTime.utc(2026),
        ),
      );
      expect(message, '@bob reacted ❤️ to your story');
    });
  });
}
