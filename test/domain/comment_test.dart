import 'package:ciel_mobile/domain/entities/comment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('authorLabel prefers display name then handle', () {
    expect(
      Comment(
        id: '1',
        userId: 'u1',
        postId: 'p1',
        body: 'hi',
        createdAt: DateTime.utc(2026),
        userDisplayName: 'Alice',
        userHandle: 'alice',
      ).authorLabel,
      'Alice',
    );
    expect(
      Comment(
        id: '1',
        userId: 'u1',
        postId: 'p1',
        body: 'hi',
        createdAt: DateTime.utc(2026),
        userHandle: 'alice',
      ).authorLabel,
      '@alice',
    );
    expect(
      Comment(
        id: '1',
        userId: 'u1',
        postId: 'p1',
        body: 'hi',
        createdAt: DateTime.utc(2026),
      ).authorLabel,
      'User',
    );
  });
}
