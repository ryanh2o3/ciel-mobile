import 'package:ciel_mobile/app/providers/dependency_providers.dart';
import 'package:ciel_mobile/app/providers/shared_preferences_provider.dart';
import 'package:ciel_mobile/domain/entities/post.dart';
import 'package:ciel_mobile/domain/entities/story.dart';
import 'package:ciel_mobile/domain/paginated_result.dart';
import 'package:ciel_mobile/domain/repositories/feed_repository.dart';
import 'package:ciel_mobile/domain/repositories/media_repository.dart';
import 'package:ciel_mobile/domain/repositories/post_repository.dart';
import 'package:ciel_mobile/domain/repositories/story_repository.dart';
import 'package:ciel_mobile/features/auth/presentation/auth_notifier.dart';
import 'package:ciel_mobile/features/auth/presentation/auth_state.dart';
import 'package:ciel_mobile/features/stories/presentation/create_story_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeFeedRepository extends Mock implements FeedRepository {}

class _FakePostRepository extends Mock implements PostRepository {}

class _FakeStoryRepository extends Mock implements StoryRepository {}

class _FakeMediaRepository extends Mock implements MediaRepository {}

class _UnauthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState.unauthenticated();

  @override
  Future<void> restoreSession() async {}
}

Future<void> pumpScreen(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final feed = _FakeFeedRepository();
  final posts = _FakePostRepository();
  final stories = _FakeStoryRepository();
  final media = _FakeMediaRepository();

  when(
    () => feed.fetchFeed(
      limit: any(named: 'limit'),
      cursor: any(named: 'cursor'),
    ),
  ).thenAnswer((_) async => const PaginatedResult<Post>(items: []));
  when(
    () => stories.fetchStoriesFeed(
      limit: any(named: 'limit'),
      cursor: any(named: 'cursor'),
    ),
  ).thenAnswer((_) async => const PaginatedResult<Story>(items: []));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        feedRepositoryProvider.overrideWithValue(feed),
        postRepositoryProvider.overrideWithValue(posts),
        storyRepositoryProvider.overrideWithValue(stories),
        mediaRepositoryProvider.overrideWithValue(media),
        authNotifierProvider.overrideWith(_UnauthNotifier.new),
      ],
      child: const MaterialApp(home: CreateStoryScreen()),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('empty state shows the choose-photo CTA', (tester) async {
    await pumpScreen(tester);

    expect(find.text('New story'), findsOneWidget);
    expect(find.text('Pick a photo to begin.'), findsOneWidget);
    expect(find.text('Choose photo'), findsOneWidget);
    expect(find.text('Share story'), findsNothing);
  });
}
