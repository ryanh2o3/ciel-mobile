import 'package:ciel_mobile/domain/entities/story.dart';

class StoryViewerExtra {
  StoryViewerExtra({required this.stories, required this.initialIndex});

  final List<Story> stories;
  final int initialIndex;
}
