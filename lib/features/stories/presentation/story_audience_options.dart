import 'package:ciel_mobile/domain/entities/story.dart';
import 'package:ciel_mobile/ui/ciel_audience_picker_sheet.dart';
import 'package:flutter/material.dart';

/// Canonical option set for [StoryVisibility].
const List<CielAudienceOption<StoryVisibility>> kStoryAudienceOptions = [
  CielAudienceOption(
    value: StoryVisibility.public,
    icon: Icons.public,
    title: 'Public',
    description: 'Anyone on PicShare can see this story.',
  ),
  CielAudienceOption(
    value: StoryVisibility.friendsOnly,
    icon: Icons.group_outlined,
    title: 'Friends',
    description: 'People you follow back can see this story.',
  ),
  CielAudienceOption(
    value: StoryVisibility.closeFriendsOnly,
    icon: Icons.star_outline,
    title: 'Close friends',
    description: 'Only your close friends list will see this.',
  ),
];

String storyVisibilityLabel(StoryVisibility visibility) {
  return switch (visibility) {
    StoryVisibility.public => 'Public',
    StoryVisibility.friendsOnly => 'Friends',
    StoryVisibility.closeFriendsOnly => 'Close friends',
  };
}
