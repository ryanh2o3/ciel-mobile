import 'package:ciel_mobile/domain/entities/comment.dart';
import 'package:ciel_mobile/domain/entities/like.dart';
import 'package:ciel_mobile/domain/entities/post.dart';
import 'package:ciel_mobile/domain/paginated_result.dart';
import 'package:ciel_mobile/domain/repositories/post_repository.dart';

class PostUseCase {
  PostUseCase(this._repository);

  final PostRepository _repository;

  Future<Post> createPost({required List<String> mediaIds, String? caption}) {
    return _repository.createPost(mediaIds: mediaIds, caption: caption);
  }

  Future<Post> fetchPost(String id) => _repository.fetchPost(id);

  Future<Post> updatePost({required String id, String? caption}) {
    return _repository.updatePost(id: id, caption: caption);
  }

  Future<void> deletePost(String id) => _repository.deletePost(id);

  Future<void> likePost(String id) => _repository.likePost(id);

  Future<void> unlikePost(String id) => _repository.unlikePost(id);

  Future<PaginatedResult<Like>> fetchLikes({
    required String postId,
    required int limit,
    String? cursor,
  }) {
    return _repository.fetchLikes(id: postId, limit: limit, cursor: cursor);
  }

  Future<Comment> addComment({required String postId, required String body}) {
    return _repository.addComment(postId: postId, body: body);
  }

  Future<PaginatedResult<Comment>> fetchComments({
    required String postId,
    required int limit,
    String? cursor,
  }) {
    return _repository.fetchComments(
      postId: postId,
      limit: limit,
      cursor: cursor,
    );
  }

  Future<void> deleteComment({
    required String postId,
    required String commentId,
  }) {
    return _repository.deleteComment(postId: postId, commentId: commentId);
  }
}
