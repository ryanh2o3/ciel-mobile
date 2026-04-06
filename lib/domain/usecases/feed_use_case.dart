import 'package:ciel_mobile/domain/entities/post.dart';
import 'package:ciel_mobile/domain/paginated_result.dart';
import 'package:ciel_mobile/domain/repositories/feed_repository.dart';

class FeedUseCase {
  FeedUseCase(this._repository);

  final FeedRepository _repository;

  Future<PaginatedResult<Post>> fetchFeed({
    required int limit,
    String? cursor,
  }) {
    return _repository.fetchFeed(limit: limit, cursor: cursor);
  }

  Future<void> refreshFeedCache() => _repository.refreshFeedCache();
}
