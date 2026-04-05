import 'package:ciel_mobile/app/providers/theme_mode_notifier.dart';
import 'package:ciel_mobile/features/auth/presentation/auth_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeNotifierProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Appearance'),
            subtitle: Text(mode.name),
            onTap: () async {
              final next = switch (mode) {
                ThemeMode.system => ThemeMode.light,
                ThemeMode.light => ThemeMode.dark,
                ThemeMode.dark => ThemeMode.system,
              };
              await ref.read(themeModeNotifierProvider.notifier).setMode(next);
            },
          ),
          ListTile(
            title: const Text('Invites'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/invites'),
          ),
          ListTile(
            title: const Text('Trust & rate limits'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/trust'),
          ),
          ListTile(
            title: const Text('Log out'),
            onTap: () async {
              await ref.read(authNotifierProvider.notifier).logout();
              if (context.mounted) {
                context.go('/auth');
              }
            },
          ),
        ],
      ),
    );
  }
}
