import 'dart:convert';
import 'dart:io';

import 'package:ciel_mobile/app/providers/shared_preferences_provider.dart';
import 'package:ciel_mobile/features/uploads/draft/create_drafts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local persistence for in-progress story/post compose state.
///
/// One slot per type. Stored as JSON in [SharedPreferences]. On load,
/// missing-file paths (the OS may have purged the temp dir between
/// launches) are scrubbed so the screen sees a partially-restored draft
/// rather than a broken one.
class CreateDraftStore {
  CreateDraftStore(this._prefs);

  final SharedPreferences _prefs;

  static const String _storyKey = 'compose:story_draft';
  static const String _postKey = 'compose:post_draft';

  CreateStoryDraft? loadStory() {
    final raw = _prefs.getString(_storyKey);
    if (raw == null) return null;
    final draft = CreateStoryDraft.fromJsonString(raw);
    if (draft == null || draft.isEmpty) return null;
    final path = draft.imagePath;
    if (path != null && !File(path).existsSync()) {
      return CreateStoryDraft(
        caption: draft.caption,
        visibility: draft.visibility,
        updatedAt: draft.updatedAt,
      );
    }
    return draft;
  }

  Future<void> saveStory(CreateStoryDraft draft) async {
    if (draft.isEmpty) {
      await clearStory();
      return;
    }
    await _prefs.setString(_storyKey, jsonEncode(draft.toJson()));
  }

  Future<void> clearStory() => _prefs.remove(_storyKey);

  CreatePostDraft? loadPost() {
    final raw = _prefs.getString(_postKey);
    if (raw == null) return null;
    final draft = CreatePostDraft.fromJsonString(raw);
    if (draft == null || draft.isEmpty) return null;
    final liveOnly = draft.imagePaths
        .where((p) => File(p).existsSync())
        .toList(growable: false);
    if (liveOnly.length == draft.imagePaths.length) return draft;
    final scrubbed = CreatePostDraft(
      imagePaths: liveOnly,
      caption: draft.caption,
      updatedAt: draft.updatedAt,
    );
    return scrubbed.isEmpty ? null : scrubbed;
  }

  Future<void> savePost(CreatePostDraft draft) async {
    if (draft.isEmpty) {
      await clearPost();
      return;
    }
    await _prefs.setString(_postKey, jsonEncode(draft.toJson()));
  }

  Future<void> clearPost() => _prefs.remove(_postKey);
}

final createDraftStoreProvider = Provider<CreateDraftStore>(
  (ref) => CreateDraftStore(ref.watch(sharedPreferencesProvider)),
);
