import 'package:ciel_mobile/ui/ciel_compose_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    home: Scaffold(
      body: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  );

  testWidgets('renders icon, label and trailing value', (tester) async {
    await tester.pumpWidget(
      host(
        const CielComposeRow(
          icon: Icons.visibility_outlined,
          label: 'Audience',
          trailing: 'Public',
        ),
      ),
    );

    expect(find.text('Audience'), findsOneWidget);
    expect(find.text('Public'), findsOneWidget);
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });

  testWidgets('invokes onTap when enabled', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(
        CielComposeRow(
          icon: Icons.public,
          label: 'Audience',
          onTap: () => taps++,
        ),
      ),
    );

    await tester.tap(find.byType(CielComposeRow));
    expect(taps, 1);
  });

  testWidgets('swallows taps when disabled', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(
        CielComposeRow(
          icon: Icons.public,
          label: 'Audience',
          enabled: false,
          onTap: () => taps++,
        ),
      ),
    );

    await tester.tap(find.byType(CielComposeRow));
    expect(taps, 0);
  });
}
