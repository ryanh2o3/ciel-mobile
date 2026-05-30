import 'package:ciel_mobile/domain/entities/story.dart';
import 'package:ciel_mobile/domain/paginated_result.dart';
import 'package:ciel_mobile/domain/repositories/story_repository.dart';
import 'package:ciel_mobile/domain/usecases/media_upload_progress.dart';
import 'package:ciel_mobile/domain/usecases/media_use_case.dart';

class StoryUseCase {
  StoryUseCase(this._storyRepository, this._mediaUseCase);

  final StoryRepository _storyRepository;
  final MediaUseCase _mediaUseCase;

  Future<PaginatedResult<Story>> fetchStoriesFeed({
    required int limit,
    String? cursor,
  }) {
    return _storyRepository.fetchStoriesFeed(limit: limit, cursor: cursor);
  }

  Future<PaginatedResult<Story>> fetchUserStories({
    required String userId,
    required int limit,
    String? cursor,
  }) {
    return _storyRepository.fetchUserStories(
      userId: userId,
      limit: limit,
      cursor: cursor,
    );
  }

  Future<Story> fetchStory(String id) => _storyRepository.fetchStory(id);

  Future<Story> createStoryFromImage({
    required List<int> imageBytes,
    required StoryVisibility visibility,
    String? caption,
    void Function(MediaUploadProgress progress)? onProgress,
  }) async {
    final mediaId = await _mediaUseCase.uploadImageAndWaitForMediaId(
      data: imageBytes,
      onProgress: onProgress,
    );
    return _storyRepository.createStory(
      mediaId: mediaId,
      caption: caption,
      visibility: _visibilityApiValue(visibility),
    );
  }

  Future<void> deleteStory(String id) => _storyRepository.deleteStory(id);

  Future<void> markSeen(String storyId) => _storyRepository.markSeen(storyId);

  Future<StoryReaction> addReaction({
    required String storyId,
    required String emoji,
  }) {
    return _storyRepository.addReaction(storyId: storyId, emoji: emoji);
  }

  Future<void> removeReaction(String storyId) {
    return _storyRepository.removeReaction(storyId);
  }

  Future<PaginatedResult<StoryView>> fetchViewers({
    required String storyId,
    required int limit,
    String? cursor,
  }) {
    return _storyRepository.fetchViewers(
      storyId: storyId,
      limit: limit,
      cursor: cursor,
    );
  }

  Future<PaginatedResult<StoryReaction>> fetchReactions({
    required String storyId,
    required int limit,
    String? cursor,
  }) {
    return _storyRepository.fetchReactions(
      storyId: storyId,
      limit: limit,
      cursor: cursor,
    );
  }

  List<UserStoryGroup> groupStoriesByUser(List<Story> stories) {
    final grouped = <String, List<Story>>{};
    final userInfo = <String, (String?, String?, String?)>{};

    for (final story in stories) {
      grouped.putIfAbsent(story.userId, () => []).add(story);
      userInfo.putIfAbsent(
        story.userId,
        () => (
          story.userHandle,
          story.userDisplayName,
          story.userAvatarUrl,
        ),
      );
    }

    final groups = grouped.entries.map((e) {
      final info = userInfo[e.key]!;
      final sorted = List<Story>.from(e.value)
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return UserStoryGroup(
        userId: e.key,
        userHandle: info.$1,
        userDisplayName: info.$2,
        userAvatarUrl: info.$3,
        stories: sorted,
        hasUnseenStories: true,
      );
    }).toList()..sort((a, b) => b.latestStoryDate.compareTo(a.latestStoryDate));

    return groups;
  }

  static String _visibilityApiValue(StoryVisibility v) {
    switch (v) {
      case StoryVisibility.public:
        return 'Public';
      case StoryVisibility.friendsOnly:
        return 'FriendsOnly';
      case StoryVisibility.closeFriendsOnly:
        return 'CloseFriendsOnly';
    }
  }
}
