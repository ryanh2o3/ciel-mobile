import 'package:ciel_mobile/domain/entities/signup_request.dart';
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
      createdAt: DateTime.utc(2024),
    );
    when(() => repo.fetchMe()).thenAnswer((_) async => user);

    final result = await useCase.restoreSession();

    expect(result, user);
    verify(() => repo.fetchMe()).called(1);
    verifyNever(() => repo.clearLocalSession());
  });

  test(
    'restoreSession returns null and clears session when fetchMe fails',
    () async {
      when(() => repo.fetchMe()).thenThrow(Exception('network'));
      when(() => repo.clearLocalSession()).thenAnswer((_) async {});

      final result = await useCase.restoreSession();

      expect(result, isNull);
      verify(() => repo.fetchMe()).called(1);
      verify(() => repo.clearLocalSession()).called(1);
    },
  );

  test('signup registers then logs in and returns user', () async {
    const request = SignupRequest(
      handle: 'h',
      email: 'e@e.com',
      displayName: 'D',
      password: 'secret',
      inviteCode: 'abc',
    );
    final user = User(
      id: '1',
      handle: 'h',
      displayName: 'D',
      createdAt: DateTime.utc(2024),
    );
    when(() => repo.signup(request)).thenAnswer((_) async => user);
    when(
      () => repo.login(email: request.email, password: request.password),
    ).thenAnswer((_) async => user);

    final result = await useCase.signup(request);

    expect(result, user);
    verify(() => repo.signup(request)).called(1);
    verify(
      () => repo.login(email: request.email, password: request.password),
    ).called(1);
  });
}
