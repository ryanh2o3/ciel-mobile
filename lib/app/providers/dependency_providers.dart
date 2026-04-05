import 'package:ciel_mobile/core/config/app_config.dart';
import 'package:ciel_mobile/data/api/dio_module.dart';
import 'package:ciel_mobile/data/auth/auth_token_manager.dart';
import 'package:ciel_mobile/data/local/secure_refresh_token_store.dart';
import 'package:ciel_mobile/data/repositories/auth_repository_impl.dart';
import 'package:ciel_mobile/domain/repositories/auth_repository.dart';
import 'package:ciel_mobile/domain/usecases/auth_use_case.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Composition root: config, secure store, token manager, [Dio],
/// repositories, and use cases.
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

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    dio: ref.watch(dioProvider),
    tokens: ref.watch(authTokenManagerProvider),
  ),
);

final authUseCaseProvider = Provider<AuthUseCase>(
  (ref) => AuthUseCase(ref.watch(authRepositoryProvider)),
);
