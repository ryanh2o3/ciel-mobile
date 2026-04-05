import 'package:ciel_mobile/domain/paginated_result.dart';

PaginatedResult<T> paginatedFromJson<T>(
  Map<String, dynamic> json,
  T Function(Map<String, dynamic> j) item,
) {
  final raw = json['items'] as List<dynamic>? ?? [];
  return PaginatedResult<T>(
    items: raw.map((e) => item(e as Map<String, dynamic>)).toList(),
    nextCursor: json['next_cursor'] as String?,
    totalCount: (json['total_count'] as num?)?.toInt(),
  );
}
