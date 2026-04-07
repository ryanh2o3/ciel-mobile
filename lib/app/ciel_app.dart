import 'package:ciel_mobile/app/providers/theme_mode_notifier.dart';
import 'package:ciel_mobile/app/router/app_router.dart';
import 'package:ciel_mobile/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CielApp extends ConsumerWidget {
  const CielApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final themeMode = ref.watch(themeModeNotifierProvider);
    return MaterialApp.router(
      title: 'Ciel',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
