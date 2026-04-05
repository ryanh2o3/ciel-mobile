import 'package:ciel_mobile/core/config/app_config.dart';
import 'package:ciel_mobile/data/api/dio_module.dart';
import 'package:ciel_mobile/data/auth/auth_token_manager.dart';
import 'package:ciel_mobile/data/local/secure_refresh_token_store.dart';
import 'package:ciel_mobile/data/repositories/auth_repository_impl.dart';
import 'package:ciel_mobile/domain/repositories/auth_repository.dart';
import 'package:ciel_mobile/domain/usecases/auth_use_case.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

final GetIt getIt = GetIt.instance;

/// Registers dependencies in construction order:
/// `AppConfig` → secure store → token manager → `Dio` → repositories → use cases.
Future<void> configureDependencies() async {
  if (getIt.isRegistered<AppConfig>()) {
    return;
  }

  getIt.registerSingleton<AppConfig>(AppConfig.fromEnvironment());

  getIt.registerLazySingleton<SecureRefreshTokenStore>(SecureRefreshTokenStore.new);

  getIt.registerLazySingleton<AuthTokenManager>(
    () => AuthTokenManager(getIt<SecureRefreshTokenStore>()),
  );

  getIt.registerLazySingleton<Dio>(
    () => createAppDio(
      config: getIt<AppConfig>(),
      tokenManager: getIt<AuthTokenManager>(),
    ),
  );

  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      dio: getIt<Dio>(),
      tokens: getIt<AuthTokenManager>(),
    ),
  );

  getIt.registerLazySingleton<AuthUseCase>(
    () => AuthUseCase(getIt<AuthRepository>()),
  );
}
