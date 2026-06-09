import 'dart:io';

import 'package:ciel_mobile/domain/entities/story.dart';
import 'package:ciel_mobile/features/uploads/draft/create_draft_store.dart';
import 'package:ciel_mobile/features/uploads/draft/create_drafts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<File> _liveTempFile(String tag) async {
  final path =
      '${Directory.systemTemp.path}/draft_${tag}_${DateTime.now().microsecondsSinceEpoch}.jpg';
  final file = await File(path).create();
  await file.writeAsBytes([0xff, 0xd8, 0xff, 0xd9]);
  return file;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late CreateDraftStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    store = CreateDraftStore(prefs);
  });

  group('story drafts', () {
    test('round-trips a draft with a live image', () async {
      final file = await _liveTempFile('story');
      final draft = CreateStoryDraft(
        imagePath: file.path,
        caption: 'hello',
        visibility: StoryVisibility.friendsOnly,
        updatedAt: DateTime.utc(2026, 6, 1, 12),
      );

      await store.saveStory(draft);
      final loaded = store.loadStory();

      expect(loaded, isNotNull);
      expect(loaded!.imagePath, file.path);
      expect(loaded.caption, 'hello');
      expect(loaded.visibility, StoryVisibility.friendsOnly);
    });

    test('returns null when no draft is stored', () {
      expect(store.loadStory(), isNull);
    });

    test('save on an empty draft clears the slot', () async {
      await store.saveStory(
        CreateStoryDraft(
          caption: '',
          visibility: StoryVisibility.public,
          updatedAt: DateTime.now(),
        ),
      );
      expect(store.loadStory(), isNull);
    });

    test('scrubs imagePath when the file is gone', () async {
      final missing = '${Directory.systemTemp.path}/__nope__.jpg';
      await store.saveStory(
        CreateStoryDraft(
          imagePath: missing,
          caption: 'caption survives',
          visibility: StoryVisibility.public,
          updatedAt: DateTime.now(),
        ),
      );

      final loaded = store.loadStory();
      expect(loaded, isNotNull);
      expect(loaded!.imagePath, isNull);
      expect(loaded.caption, 'caption survives');
    });

    test('clearStory removes the slot', () async {
      await store.saveStory(
        CreateStoryDraft(
          caption: 'x',
          visibility: StoryVisibility.public,
          updatedAt: DateTime.now(),
        ),
      );
      await store.clearStory();
      expect(store.loadStory(), isNull);
    });
  });

  group('post drafts', () {
    test('round-trips paths and caption', () async {
      final f1 = await _liveTempFile('p1');
      final f2 = await _liveTempFile('p2');
      await store.savePost(
        CreatePostDraft(
          imagePaths: [f1.path, f2.path],
          caption: 'two pics',
          updatedAt: DateTime.now(),
        ),
      );

      final loaded = store.loadPost();
      expect(loaded, isNotNull);
      expect(loaded!.imagePaths, [f1.path, f2.path]);
      expect(loaded.caption, 'two pics');
    });

    test('scrubs missing image paths from the list', () async {
      final live = await _liveTempFile('p3');
      await store.savePost(
        CreatePostDraft(
          imagePaths: [
            live.path,
            '${Directory.systemTemp.path}/__nope1__.jpg',
            '${Directory.systemTemp.path}/__nope2__.jpg',
          ],
          caption: 'mix',
          updatedAt: DateTime.now(),
        ),
      );

      final loaded = store.loadPost();
      expect(loaded, isNotNull);
      expect(loaded!.imagePaths, [live.path]);
    });

    test('returns null when only missing paths and empty caption', () async {
      await store.savePost(
        CreatePostDraft(
          imagePaths: ['${Directory.systemTemp.path}/__nope__.jpg'],
          caption: '',
          updatedAt: DateTime.now(),
        ),
      );
      expect(store.loadPost(), isNull);
    });
  });
}
