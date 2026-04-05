import 'package:ciel_mobile/domain/entities/comment.dart';
import 'package:ciel_mobile/domain/entities/like.dart';
import 'package:ciel_mobile/domain/entities/post.dart';
import 'package:ciel_mobile/domain/paginated_result.dart';

abstract class PostRepository {
  Future<Post> createPost({required List<String> mediaIds, String? caption});

  Future<Post> fetchPost(String id);

  Future<Post> updatePost({required String id, String? caption});

  Future<void> deletePost(String id);

  Future<void> likePost(String id);

  Future<void> unlikePost(String id);

  Future<PaginatedResult<Like>> fetchLikes({
    required String id,
    required int limit,
    String? cursor,
  });

  Future<Comment> addComment({required String postId, required String body});

  Future<PaginatedResult<Comment>> fetchComments({
    required String postId,
    required int limit,
    String? cursor,
  });

  Future<void> deleteComment({required String postId, required String commentId});
}
