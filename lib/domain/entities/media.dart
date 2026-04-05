import 'package:meta/meta.dart';

@immutable
class Media {
  const Media({
    required this.id,
    required this.ownerId,
    required this.originalKey,
    required this.thumbKey,
    required this.mediumKey,
    required this.width,
    required this.height,
    required this.bytes,
    required this.createdAt,
    this.thumbUrl,
    this.mediumUrl,
    this.originalUrl,
  });

  final String id;
  final String ownerId;
  final String originalKey;
  final String thumbKey;
  final String mediumKey;
  final int width;
  final int height;
  final int bytes;
  final DateTime createdAt;
  final String? thumbUrl;
  final String? mediumUrl;
  final String? originalUrl;
}
