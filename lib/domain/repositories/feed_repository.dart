import 'package:ciel_mobile/domain/entities/post.dart';
import 'package:ciel_mobile/domain/paginated_result.dart';

abstract class FeedRepository {
  Future<PaginatedResult<Post>> fetchFeed({required int limit, String? cursor});

  Future<void> refreshFeedCache();
}
