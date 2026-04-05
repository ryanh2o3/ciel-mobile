import 'package:ciel_mobile/domain/entities/user.dart';
import 'package:ciel_mobile/domain/repositories/auth_repository.dart';
import 'package:ciel_mobile/domain/usecases/auth_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repo;
  late AuthUseCase useCase;

  setUp(() {
    repo = _MockAuthRepository();
    useCase = AuthUseCase(repo);
  });

  test('restoreSession returns user when fetchMe succeeds', () async {
    final user = User(
      id: '1',
      handle: 'demo',
      displayName: 'Demo',
      createdAt: DateTime.utc(2024, 1, 1),
    );
    when(() => repo.fetchMe()).thenAnswer((_) async => user);

    final result = await useCase.restoreSession();

    expect(result, user);
    verify(() => repo.fetchMe()).called(1);
    verifyNever(() => repo.clearLocalSession());
  });

  test('restoreSession returns null and clears session when fetchMe fails', () async {
    when(() => repo.fetchMe()).thenThrow(Exception('network'));
    when(() => repo.clearLocalSession()).thenAnswer((_) async {});

    final result = await useCase.restoreSession();

    expect(result, isNull);
    verify(() => repo.fetchMe()).called(1);
    verify(() => repo.clearLocalSession()).called(1);
  });
}
