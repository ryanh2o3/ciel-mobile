import 'package:ciel_mobile/core/config/app_config.dart';
import 'package:ciel_mobile/data/api/dio_module.dart';
import 'package:ciel_mobile/data/auth/auth_token_manager.dart';
import 'package:ciel_mobile/data/local/secure_refresh_token_store.dart';
import 'package:ciel_mobile/data/repositories/auth_repository_impl.dart';
import 'package:ciel_mobile/data/repositories/feed_repository_impl.dart';
import 'package:ciel_mobile/data/repositories/invite_repository_impl.dart';
import 'package:ciel_mobile/data/repositories/media_repository_impl.dart';
import 'package:ciel_mobile/data/repositories/moderation_repository_impl.dart';
import 'package:ciel_mobile/data/repositories/notifications_repository_impl.dart';
import 'package:ciel_mobile/data/repositories/post_repository_impl.dart';
import 'package:ciel_mobile/data/repositories/safety_repository_impl.dart';
import 'package:ciel_mobile/data/repositories/search_repository_impl.dart';
import 'package:ciel_mobile/data/repositories/story_repository_impl.dart';
import 'package:ciel_mobile/data/repositories/user_repository_impl.dart';
import 'package:ciel_mobile/domain/repositories/auth_repository.dart';
import 'package:ciel_mobile/domain/repositories/feed_repository.dart';
import 'package:ciel_mobile/domain/repositories/invite_repository.dart';
import 'package:ciel_mobile/domain/repositories/media_repository.dart';
import 'package:ciel_mobile/domain/repositories/moderation_repository.dart';
import 'package:ciel_mobile/domain/repositories/notifications_repository.dart';
import 'package:ciel_mobile/domain/repositories/post_repository.dart';
import 'package:ciel_mobile/domain/repositories/safety_repository.dart';
import 'package:ciel_mobile/domain/repositories/search_repository.dart';
import 'package:ciel_mobile/domain/repositories/story_repository.dart';
import 'package:ciel_mobile/domain/repositories/user_repository.dart';
import 'package:ciel_mobile/domain/usecases/auth_use_case.dart';
import 'package:ciel_mobile/domain/usecases/feed_use_case.dart';
import 'package:ciel_mobile/domain/usecases/invite_use_case.dart';
import 'package:ciel_mobile/domain/usecases/media_use_case.dart';
import 'package:ciel_mobile/domain/usecases/moderation_use_case.dart';
import 'package:ciel_mobile/domain/usecases/notifications_use_case.dart';
import 'package:ciel_mobile/domain/usecases/post_use_case.dart';
import 'package:ciel_mobile/domain/usecases/safety_use_case.dart';
import 'package:ciel_mobile/domain/usecases/search_use_case.dart';
import 'package:ciel_mobile/domain/usecases/story_use_case.dart';
import 'package:ciel_mobile/domain/usecases/user_use_case.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment(),
);

final secureRefreshTokenStoreProvider = Provider<SecureRefreshTokenStore>(
  (ref) => SecureRefreshTokenStore(),
);

final authTokenManagerProvider = Provider<AuthTokenManager>(
  (ref) => AuthTokenManager(ref.watch(secureRefreshTokenStoreProvider)),
);

final dioProvider = Provider<Dio>(
  (ref) => createAppDio(
    config: ref.watch(appConfigProvider),
    tokenManager: ref.watch(authTokenManagerProvider),
  ),
);

final presignedUploadDioProvider = Provider<Dio>(
  (ref) => createPresignedUploadDio(),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    dio: ref.watch(dioProvider),
    tokens: ref.watch(authTokenManagerProvider),
  ),
);

final feedRepositoryProvider = Provider<FeedRepository>(
  (ref) => FeedRepositoryImpl(ref.watch(dioProvider)),
);

final postRepositoryProvider = Provider<PostRepository>(
  (ref) => PostRepositoryImpl(ref.watch(dioProvider)),
);

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepositoryImpl(ref.watch(dioProvider)),
);

final mediaRepositoryProvider = Provider<MediaRepository>(
  (ref) => MediaRepositoryImpl(
    apiDio: ref.watch(dioProvider),
    presignedUploadDio: ref.watch(presignedUploadDioProvider),
  ),
);

final storyRepositoryProvider = Provider<StoryRepository>(
  (ref) => StoryRepositoryImpl(ref.watch(dioProvider)),
);

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepositoryImpl(ref.watch(dioProvider)),
);

final searchRepositoryProvider = Provider<SearchRepository>(
  (ref) => SearchRepositoryImpl(ref.watch(dioProvider)),
);

final inviteRepositoryProvider = Provider<InviteRepository>(
  (ref) => InviteRepositoryImpl(ref.watch(dioProvider)),
);

final safetyRepositoryProvider = Provider<SafetyRepository>(
  (ref) => SafetyRepositoryImpl(ref.watch(dioProvider)),
);

final moderationRepositoryProvider = Provider<ModerationRepository>(
  (ref) => ModerationRepositoryImpl(ref.watch(dioProvider)),
);

final authUseCaseProvider = Provider<AuthUseCase>(
  (ref) => AuthUseCase(ref.watch(authRepositoryProvider)),
);

final feedUseCaseProvider = Provider<FeedUseCase>(
  (ref) => FeedUseCase(ref.watch(feedRepositoryProvider)),
);

final postUseCaseProvider = Provider<PostUseCase>(
  (ref) => PostUseCase(ref.watch(postRepositoryProvider)),
);

final userUseCaseProvider = Provider<UserUseCase>(
  (ref) => UserUseCase(ref.watch(userRepositoryProvider)),
);

final mediaUseCaseProvider = Provider<MediaUseCase>(
  (ref) => MediaUseCase(ref.watch(mediaRepositoryProvider)),
);

final storyUseCaseProvider = Provider<StoryUseCase>(
  (ref) => StoryUseCase(
    ref.watch(storyRepositoryProvider),
    ref.watch(mediaUseCaseProvider),
  ),
);

final notificationsUseCaseProvider = Provider<NotificationsUseCase>(
  (ref) => NotificationsUseCase(ref.watch(notificationsRepositoryProvider)),
);

final searchUseCaseProvider = Provider<SearchUseCase>(
  (ref) => SearchUseCase(ref.watch(searchRepositoryProvider)),
);

final inviteUseCaseProvider = Provider<InviteUseCase>(
  (ref) => InviteUseCase(ref.watch(inviteRepositoryProvider)),
);

final safetyUseCaseProvider = Provider<SafetyUseCase>(
  (ref) => SafetyUseCase(ref.watch(safetyRepositoryProvider)),
);

final moderationUseCaseProvider = Provider<ModerationUseCase>(
  (ref) => ModerationUseCase(ref.watch(moderationRepositoryProvider)),
);
