import 'package:ciel_mobile/domain/entities/post.dart';
import 'package:ciel_mobile/domain/entities/user.dart';
import 'package:ciel_mobile/domain/paginated_result.dart';

abstract class SearchRepository {
  Future<PaginatedResult<User>> searchUsers({
    required String query,
    required int limit,
    String? cursor,
  });

  Future<PaginatedResult<Post>> searchPosts({
    required String query,
    required int limit,
    String? cursor,
  });
}
