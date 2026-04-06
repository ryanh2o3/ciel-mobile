import 'package:ciel_mobile/domain/entities/story.dart';
import 'package:ciel_mobile/domain/paginated_result.dart';

abstract class StoryRepository {
  Future<PaginatedResult<Story>> fetchStoriesFeed({
    required int limit,
    String? cursor,
  });

  Future<PaginatedResult<Story>> fetchUserStories({
    required String userId,
    required int limit,
    String? cursor,
  });

  Future<Story> fetchStory(String id);

  Future<Story> createStory({
    required String mediaId,
    required String visibility,
    String? caption,
  });

  Future<void> deleteStory(String id);

  Future<void> markSeen(String storyId);

  Future<StoryReaction> addReaction({
    required String storyId,
    required String emoji,
  });

  Future<void> removeReaction(String storyId);

  Future<PaginatedResult<StoryView>> fetchViewers({
    required String storyId,
    required int limit,
    String? cursor,
  });

  Future<PaginatedResult<StoryReaction>> fetchReactions({
    required String storyId,
    required int limit,
    String? cursor,
  });
}
