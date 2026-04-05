import 'package:meta/meta.dart';

@immutable
class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.notificationType,
    required this.payload,
    required this.createdAt,
    this.readAt,
  });

  final String id;
  final String userId;
  final String notificationType;
  final Map<String, dynamic> payload;
  final DateTime? readAt;
  final DateTime createdAt;
}
