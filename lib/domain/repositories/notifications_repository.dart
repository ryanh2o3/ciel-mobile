import 'package:ciel_mobile/domain/entities/app_notification.dart';
import 'package:ciel_mobile/domain/paginated_result.dart';

abstract class NotificationsRepository {
  Future<PaginatedResult<AppNotification>> fetchNotifications({
    required int limit,
    String? cursor,
  });

  Future<void> markRead(String id);
}
