import 'package:ciel_mobile/ui/ciel_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('placeholder shows the add-photo icon and the label', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(const CielThumbnail(placeholderLabel: 'Choose')),
    );

    expect(find.byIcon(Icons.add_photo_alternate_outlined), findsOneWidget);
    expect(find.text('Choose'), findsOneWidget);
  });

  testWidgets('invokes onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(CielThumbnail(onTap: () => taps++)),
    );

    await tester.tap(find.byType(CielThumbnail));
    expect(taps, 1);
  });

  testWidgets('shows the badge text overlay', (tester) async {
    await tester.pumpWidget(
      host(const CielThumbnail(badgeText: '×3')),
    );
    expect(find.text('×3'), findsOneWidget);
  });
}
