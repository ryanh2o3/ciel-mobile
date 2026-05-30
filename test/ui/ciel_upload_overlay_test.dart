import 'package:ciel_mobile/ui/ciel_upload_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    home: Scaffold(body: SizedBox.expand(child: child)),
  );

  testWidgets('preparing phase shows the preparing copy', (tester) async {
    await tester.pumpWidget(
      host(const CielUploadOverlay(phase: CielUploadPhase.preparing)),
    );
    expect(find.text('Preparing…'), findsOneWidget);
  });

  testWidgets('sending with multiple items shows index/count', (tester) async {
    await tester.pumpWidget(
      host(
        const CielUploadOverlay(
          phase: CielUploadPhase.sending,
          itemIndex: 2,
          itemCount: 3,
          fraction: 0.5,
        ),
      ),
    );
    expect(find.text('Uploading 2 of 3…'), findsOneWidget);
    expect(find.textContaining('%'), findsOneWidget);
  });

  testWidgets('failed phase renders message and a retry button', (
    tester,
  ) async {
    var retried = 0;
    await tester.pumpWidget(
      host(
        CielUploadOverlay(
          phase: CielUploadPhase.failed,
          errorMessage: 'Network down',
          onRetry: () => retried++,
        ),
      ),
    );

    expect(find.text("Couldn't share"), findsOneWidget);
    expect(find.text('Network down'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    expect(retried, 1);
  });
}
