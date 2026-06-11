import 'package:ciel_mobile/app/providers/shared_preferences_provider.dart';
import 'package:ciel_mobile/features/auth/presentation/auth_notifier.dart';
import 'package:ciel_mobile/features/auth/presentation/auth_state.dart';
import 'package:ciel_mobile/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Settings shows legal links and delete account', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authNotifierProvider.overrideWith(_UnauthNotifier.new),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Terms of Use'), findsOneWidget);
    expect(find.text('Delete account'), findsOneWidget);
  });
}

class _UnauthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState.unauthenticated();
}
