import 'package:meta/meta.dart';

/// Cursor-paginated page — mirrors Swift `PaginatedResult<T>`.
@immutable
class PaginatedResult<T> {
  const PaginatedResult({
    required this.items,
    this.nextCursor,
    this.totalCount,
  });

  final List<T> items;
  final String? nextCursor;
  final int? totalCount;

  bool get hasMore => nextCursor != null;
}
