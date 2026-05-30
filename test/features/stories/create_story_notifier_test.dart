import 'dart:io';

import 'package:ciel_mobile/app/providers/dependency_providers.dart';
import 'package:ciel_mobile/domain/entities/story.dart';
import 'package:ciel_mobile/domain/repositories/media_repository.dart';
import 'package:ciel_mobile/domain/repositories/story_repository.dart';
import 'package:ciel_mobile/features/stories/presentation/create_story_notifier.dart';
import 'package:ciel_mobile/features/uploads/create_upload_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';

class _MockMediaRepository extends Mock implements MediaRepository {}

class _MockStoryRepository extends Mock implements StoryRepository {}

Future<XFile> _tempImage() async {
  final path =
      '${Directory.systemTemp.path}/story_${DateTime.now().microsecondsSinceEpoch}.jpg';
  final file = await File(path).create();
  await file.writeAsBytes([0xff, 0xd8, 0xff, 0xd9]);
  return XFile(file.path);
}

Story _stubStory() => Story(
  id: 's1',
  userId: 'u1',
  mediaId: 'm1',
  createdAt: DateTime.utc(2026),
  expiresAt: DateTime.utc(2026, 1, 2),
  visibility: StoryVisibility.public,
  viewCount: 0,
  reactionCount: 0,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(<int>[]);
    registerFallbackValue(<String, String>{});
  });

  late _MockMediaRepository media;
  late _MockStoryRepository stories;

  setUp(() {
    media = _MockMediaRepository();
    stories = _MockStoryRepository();
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        mediaRepositoryProvider.overrideWithValue(media),
        storyRepositoryProvider.overrideWithValue(stories),
      ],
    );
  }

  test('happy path emits preparing → sending → processing → done', () async {
    when(
      () => media.createUploadIntent(
        contentType: any(named: 'contentType'),
        bytes: any(named: 'bytes'),
      ),
    ).thenAnswer(
      (_) async => const MediaUploadIntent(
        uploadId: 'up',
        uploadUrl: 'https://example.test/u',
        headers: {},
      ),
    );
    when(
      () => media.uploadBytes(
        uploadUrl: any(named: 'uploadUrl'),
        headers: any(named: 'headers'),
        data: any(named: 'data'),
        onSendProgress: any(named: 'onSendProgress'),
      ),
    ).thenAnswer((invocation) async {
      final cb =
          invocation.namedArguments[#onSendProgress]
              as void Function(int, int)?;
      cb?.call(40, 100);
      cb?.call(100, 100);
    });
    when(() => media.completeUpload(any())).thenAnswer((_) async {});
    when(
      () => media.uploadStatus(any()),
    ).thenAnswer(
      (_) async =>
          const MediaUploadStatus(status: 'completed', processedMediaId: 'mid'),
    );
    when(
      () => stories.createStory(
        mediaId: any(named: 'mediaId'),
        caption: any(named: 'caption'),
        visibility: any(named: 'visibility'),
      ),
    ).thenAnswer((_) async => _stubStory());

    final container = makeContainer();
    addTearDown(container.dispose);
    final emitted = <CreateUploadState>[];
    container.listen<CreateUploadState>(
      createStoryControllerProvider,
      (_, next) => emitted.add(next),
    );

    final ok = await container
        .read(createStoryControllerProvider.notifier)
        .submit(image: await _tempImage(), visibility: StoryVisibility.public);

    expect(ok, isTrue);
    expect(emitted.whereType<CreateUploadPreparing>(), isNotEmpty);
    expect(emitted.whereType<CreateUploadSending>(), isNotEmpty);
    expect(emitted.whereType<CreateUploadProcessing>(), isNotEmpty);
    expect(emitted.whereType<CreateUploadFinalizing>(), isNotEmpty);
    expect(emitted.last, isA<CreateUploadDone>());
  });

  test('failure during intent maps to friendly failure state', () async {
    when(
      () => media.createUploadIntent(
        contentType: any(named: 'contentType'),
        bytes: any(named: 'bytes'),
      ),
    ).thenThrow(const SocketException('offline'));

    final container = makeContainer();
    addTearDown(container.dispose);
    container.listen<CreateUploadState>(
      createStoryControllerProvider,
      (_, _) {},
    );

    final ok = await container
        .read(createStoryControllerProvider.notifier)
        .submit(image: await _tempImage(), visibility: StoryVisibility.public);

    expect(ok, isFalse);
    final state = container.read(createStoryControllerProvider);
    expect(state, isA<CreateUploadFailed>());
    expect(
      (state as CreateUploadFailed).message,
      contains("Couldn't reach PicShare"),
    );
  });

  test('reset returns to idle', () async {
    final container = makeContainer();
    addTearDown(container.dispose);
    container.listen<CreateUploadState>(
      createStoryControllerProvider,
      (_, _) {},
    );

    container.read(createStoryControllerProvider.notifier).reset();
    expect(
      container.read(createStoryControllerProvider),
      isA<CreateUploadIdle>(),
    );
  });
}
