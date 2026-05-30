import 'package:ciel_mobile/ui/ciel_audience_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

enum _TestAudience { a, b, c }

void main() {
  const options = [
    CielAudienceOption(
      value: _TestAudience.a,
      icon: Icons.public,
      title: 'Public',
      description: 'Anyone can see.',
    ),
    CielAudienceOption(
      value: _TestAudience.b,
      icon: Icons.group_outlined,
      title: 'Friends',
      description: 'People you follow back.',
    ),
    CielAudienceOption(
      value: _TestAudience.c,
      icon: Icons.star_outline,
      title: 'Close friends',
      description: 'Your close-friends list.',
    ),
  ];

  Future<_TestAudience?> openSheet(WidgetTester tester) async {
    _TestAudience? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result = await showCielAudiencePicker<_TestAudience>(
                    context: context,
                    options: options,
                    selected: _TestAudience.a,
                  );
                },
                child: const Text('open'),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('shows all options with the current selection marked', (
    tester,
  ) async {
    await openSheet(tester);

    expect(find.text('Public'), findsOneWidget);
    expect(find.text('Friends'), findsOneWidget);
    expect(find.text('Close friends'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('returns the tapped value', (tester) async {
    _TestAudience? captured;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                captured = await showCielAudiencePicker<_TestAudience>(
                  context: context,
                  options: options,
                  selected: _TestAudience.a,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Friends'));
    await tester.pumpAndSettle();

    expect(captured, _TestAudience.b);
  });
}
