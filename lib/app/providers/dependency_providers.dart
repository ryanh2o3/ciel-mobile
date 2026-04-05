import 'package:ciel_mobile/app/di/injection.dart';
import 'package:ciel_mobile/domain/usecases/auth_use_case.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bridges [get_it] into Riverpod without pulling service-locator into widgets.
final authUseCaseProvider = Provider<AuthUseCase>(
  (ref) => getIt<AuthUseCase>(),
);
