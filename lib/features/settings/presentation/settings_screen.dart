import 'package:ciel_mobile/app/providers/dependency_providers.dart';
import 'package:ciel_mobile/app/providers/theme_mode_notifier.dart';
import 'package:ciel_mobile/core/errors/error_snackbar.dart';
import 'package:ciel_mobile/features/auth/presentation/auth_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        showErrorSnackBar(context, 'Could not open link');
      }
    }
  }

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete account?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'This permanently deletes your account and signs you out. '
              'Type DELETE to confirm.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Type DELETE',
                border: OutlineInputBorder(),
              ),
              autocorrect: false,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () {
              if (controller.text.trim() == 'DELETE') {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Delete account'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (confirmed != true || !context.mounted) {
      return;
    }
    try {
      await ref.read(safetyUseCaseProvider).deleteAccount();
      await ref.read(authNotifierProvider.notifier).logout();
      if (context.mounted) {
        context.go('/auth');
      }
    } on Object catch (e) {
      if (context.mounted) {
        showErrorSnackBar(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeNotifierProvider);
    final config = ref.watch(appConfigProvider);
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
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => _openUrl(context, config.privacyPolicyUrl),
          ),
          ListTile(
            title: const Text('Terms of Use'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => _openUrl(context, config.termsOfUseUrl),
          ),
          ListTile(
            title: Text(
              'Delete account',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () => _confirmDeleteAccount(context, ref),
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
