import 'package:ciel_mobile/app/ciel_app.dart';
import 'package:ciel_mobile/app/providers/shared_preferences_provider.dart';
import 'package:ciel_mobile/features/auth/presentation/auth_notifier.dart';
import 'package:ciel_mobile/features/auth/presentation/auth_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'CielApp boots without pending network timers',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            authNotifierProvider.overrideWith(_ImmediateUnauthNotifier.new),
          ],
          child: const CielApp(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(CielApp), findsOneWidget);
    },
  );
}

/// Skips [restoreSession] I/O — router sends unauthenticated users to /auth.
class _ImmediateUnauthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState.unauthenticated();

  @override
  Future<void> restoreSession() async {}
}
