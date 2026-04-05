import 'package:ciel_mobile/domain/entities/post.dart';
import 'package:ciel_mobile/domain/entities/user.dart';
import 'package:ciel_mobile/domain/paginated_result.dart';
import 'package:ciel_mobile/domain/repositories/search_repository.dart';

class SearchUseCase {
  SearchUseCase(this._repository);

  final SearchRepository _repository;

  Future<PaginatedResult<User>> searchUsers({
    required String query,
    required int limit,
    String? cursor,
  }) {
    return _repository.searchUsers(
      query: query,
      limit: limit,
      cursor: cursor,
    );
  }

  Future<PaginatedResult<Post>> searchPosts({
    required String query,
    required int limit,
    String? cursor,
  }) {
    return _repository.searchPosts(
      query: query,
      limit: limit,
      cursor: cursor,
    );
  }
}
