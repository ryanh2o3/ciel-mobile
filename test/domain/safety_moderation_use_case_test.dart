import 'package:ciel_mobile/domain/repositories/moderation_repository.dart';
import 'package:ciel_mobile/domain/repositories/safety_repository.dart';
import 'package:ciel_mobile/domain/usecases/moderation_use_case.dart';
import 'package:ciel_mobile/domain/usecases/safety_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSafetyRepository extends Mock implements SafetyRepository {}

class _MockModerationRepository extends Mock implements ModerationRepository {}

void main() {
  late _MockSafetyRepository safetyRepo;
  late _MockModerationRepository moderationRepo;

  setUp(() {
    safetyRepo = _MockSafetyRepository();
    moderationRepo = _MockModerationRepository();
  });

  test('SafetyUseCase deleteAccount delegates to repository', () async {
    when(() => safetyRepo.deleteAccount()).thenAnswer((_) async {});
    final useCase = SafetyUseCase(safetyRepo);
    await useCase.deleteAccount();
    verify(() => safetyRepo.deleteAccount()).called(1);
  });

  test('ModerationUseCase reportUser delegates to repository', () async {
    when(
      () => moderationRepo.flagUser(userId: 'u1', reason: 'spam'),
    ).thenAnswer((_) async {});
    final useCase = ModerationUseCase(moderationRepo);
    await useCase.reportUser(userId: 'u1', reason: 'spam');
    verify(
      () => moderationRepo.flagUser(userId: 'u1', reason: 'spam'),
    ).called(1);
  });

  test('ModerationUseCase reportPost delegates to repository', () async {
    when(
      () => moderationRepo.flagPost(postId: 'p1', reason: 'spam'),
    ).thenAnswer((_) async {});
    final useCase = ModerationUseCase(moderationRepo);
    await useCase.reportPost(postId: 'p1', reason: 'spam');
    verify(
      () => moderationRepo.flagPost(postId: 'p1', reason: 'spam'),
    ).called(1);
  });
}
