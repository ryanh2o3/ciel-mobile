import 'dart:io';

import 'package:ciel_mobile/app/providers/dependency_providers.dart';
import 'package:ciel_mobile/domain/entities/post.dart';
import 'package:ciel_mobile/domain/repositories/media_repository.dart';
import 'package:ciel_mobile/domain/repositories/post_repository.dart';
import 'package:ciel_mobile/features/post/presentation/create_post_notifier.dart';
import 'package:ciel_mobile/features/uploads/create_upload_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';

class _MockMediaRepository extends Mock implements MediaRepository {}

class _MockPostRepository extends Mock implements PostRepository {}

Future<XFile> _tempImage(String tag) async {
  final path =
      '${Directory.systemTemp.path}/post_${tag}_${DateTime.now().microsecondsSinceEpoch}.jpg';
  final file = await File(path).create();
  await file.writeAsBytes([0xff, 0xd8, 0xff, 0xd9]);
  return XFile(file.path);
}

Post _stubPost() => Post(
  id: 'p1',
  ownerId: 'u1',
  mediaIds: const ['m1', 'm2'],
  visibility: PostVisibility.public,
  createdAt: DateTime.utc(2026),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(<int>[]);
    registerFallbackValue(<String, String>{});
    registerFallbackValue(const <String>[]);
  });

  late _MockMediaRepository media;
  late _MockPostRepository posts;

  setUp(() {
    media = _MockMediaRepository();
    posts = _MockPostRepository();
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        mediaRepositoryProvider.overrideWithValue(media),
        postRepositoryProvider.overrideWithValue(posts),
      ],
    );
  }

  test('rejects empty image list with a form-friendly failure', () async {
    final container = makeContainer();
    addTearDown(container.dispose);
    container.listen<CreateUploadState>(
      createPostControllerProvider,
      (_, _) {},
    );

    final ok = await container
        .read(createPostControllerProvider.notifier)
        .submit(images: const []);

    expect(ok, isFalse);
    final state = container.read(createPostControllerProvider);
    expect(state, isA<CreateUploadFailed>());
  });

  test('multi-image happy path advances itemIndex per upload', () async {
    var intentCalls = 0;
    when(
      () => media.createUploadIntent(
        contentType: any(named: 'contentType'),
        bytes: any(named: 'bytes'),
      ),
    ).thenAnswer((_) async {
      intentCalls++;
      return MediaUploadIntent(
        uploadId: 'up-$intentCalls',
        uploadUrl: 'https://example.test/u$intentCalls',
        headers: const {},
      );
    });
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
      cb?.call(50, 100);
    });
    when(() => media.completeUpload(any())).thenAnswer((_) async {});
    when(() => media.uploadStatus(any())).thenAnswer(
      (invocation) async => MediaUploadStatus(
        status: 'completed',
        processedMediaId: 'mid-${invocation.positionalArguments.first}',
      ),
    );
    when(
      () => posts.createPost(
        mediaIds: any(named: 'mediaIds'),
        caption: any(named: 'caption'),
      ),
    ).thenAnswer((_) async => _stubPost());

    final container = makeContainer();
    addTearDown(container.dispose);
    final emitted = <CreateUploadState>[];
    container.listen<CreateUploadState>(
      createPostControllerProvider,
      (_, next) => emitted.add(next),
    );

    final ok = await container
        .read(createPostControllerProvider.notifier)
        .submit(
          images: [await _tempImage('a'), await _tempImage('b')],
        );

    expect(ok, isTrue);
    final sendings = emitted.whereType<CreateUploadSending>().toList();
    expect(sendings.any((s) => s.itemIndex == 1 && s.itemCount == 2), isTrue);
    expect(sendings.any((s) => s.itemIndex == 2 && s.itemCount == 2), isTrue);
    expect(emitted.last, isA<CreateUploadDone>());
    verify(
      () => posts.createPost(
        mediaIds: any(named: 'mediaIds'),
        caption: any(named: 'caption'),
      ),
    ).called(1);
  });
}
