import 'package:ciel_mobile/domain/entities/app_notification.dart';
import 'package:ciel_mobile/domain/paginated_result.dart';
import 'package:ciel_mobile/domain/repositories/notifications_repository.dart';

class NotificationsUseCase {
  NotificationsUseCase(this._repository);

  final NotificationsRepository _repository;

  Future<PaginatedResult<AppNotification>> fetchNotifications({
    required int limit,
    String? cursor,
  }) {
    return _repository.fetchNotifications(limit: limit, cursor: cursor);
  }

  Future<void> markRead(String id) => _repository.markRead(id);
}
