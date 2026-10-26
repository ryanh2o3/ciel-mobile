import 'package:ciel_mobile/ui/ciel_create_chooser_sheet.dart';
import 'package:ciel_mobile/ui/ciel_empty_state.dart';
import 'package:ciel_mobile/ui/ciel_relative_time.dart';
import 'package:ciel_mobile/ui/ciel_user_list_tile.dart';
import 'package:ciel_mobile/ui/report_user_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CielEmptyState shows title and action', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CielEmptyState(
            icon: Icons.inbox,
            title: 'Nothing here',
            subtitle: 'Try again later',
            actionLabel: 'Retry',
            onAction: () => tapped = true,
          ),
        ),
      ),
    );
    expect(find.text('Nothing here'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(tapped, isTrue);
  });

  testWidgets('CielUserListTile shows handle', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CielUserListTile(
            displayName: 'Ada',
            handle: 'ada',
            onTap: () {},
          ),
        ),
      ),
    );
    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('@ada'), findsOneWidget);
  });

  test('cielRelativeTime formats minutes', () {
    final now = DateTime(2026, 1, 1, 12);
    final then = now.subtract(const Duration(minutes: 5));
    expect(cielRelativeTime(then, now: now), '5m');
  });

  testWidgets('create chooser returns post choice', (tester) async {
    CielCreateChoice? choice;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () async {
                  choice = await showCielCreateChooserSheet(context);
                },
                child: const Text('Open'),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New post'));
    await tester.pumpAndSettle();
    expect(choice, CielCreateChoice.post);
  });

  testWidgets('report post sheet uses post title', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () => showReportPostSheet(context),
                child: const Text('Report'),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('Report'));
    await tester.pumpAndSettle();
    expect(find.text('Report post'), findsOneWidget);
  });
}
