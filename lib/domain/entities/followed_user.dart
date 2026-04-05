import 'package:ciel_mobile/domain/entities/user.dart';
import 'package:meta/meta.dart';

@immutable
class FollowedUser {
  const FollowedUser({
    required this.user,
    required this.followedAt,
  });

  final User user;
  final DateTime followedAt;
}
