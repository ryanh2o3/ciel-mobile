import 'dart:convert';

import 'package:ciel_mobile/domain/entities/story.dart';
import 'package:meta/meta.dart';

/// In-progress story compose state. Persisted across launches so the
/// user doesn't lose a caption or chosen photo if they background the
/// app or accidentally pop the route.
@immutable
class CreateStoryDraft {
  const CreateStoryDraft({
    required this.caption,
    required this.visibility,
    required this.updatedAt,
    this.imagePath,
  });

  final String? imagePath;
  final String caption;
  final StoryVisibility visibility;
  final DateTime updatedAt;

  bool get isEmpty => imagePath == null && caption.isEmpty;

  Map<String, dynamic> toJson() => {
    'imagePath': imagePath,
    'caption': caption,
    'visibility': visibility.name,
    'updatedAt': updatedAt.toIso8601String(),
  };

  static CreateStoryDraft? fromJsonString(String raw) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return CreateStoryDraft(
        imagePath: map['imagePath'] as String?,
        caption: (map['caption'] as String?) ?? '',
        visibility: StoryVisibility.values.firstWhere(
          (v) => v.name == map['visibility'],
          orElse: () => StoryVisibility.public,
        ),
        updatedAt:
            DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
    } on Object {
      return null;
    }
  }
}

@immutable
class CreatePostDraft {
  const CreatePostDraft({
    required this.imagePaths,
    required this.caption,
    required this.updatedAt,
  });

  final List<String> imagePaths;
  final String caption;
  final DateTime updatedAt;

  bool get isEmpty => imagePaths.isEmpty && caption.isEmpty;

  Map<String, dynamic> toJson() => {
    'imagePaths': imagePaths,
    'caption': caption,
    'updatedAt': updatedAt.toIso8601String(),
  };

  static CreatePostDraft? fromJsonString(String raw) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final paths = (map['imagePaths'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList();
      return CreatePostDraft(
        imagePaths: paths,
        caption: (map['caption'] as String?) ?? '',
        updatedAt:
            DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
    } on Object {
      return null;
    }
  }
}
