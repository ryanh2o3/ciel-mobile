import 'package:ciel_mobile/ui/tokens.dart';
import 'package:flutter/material.dart';

class NotificationsPlaceholderScreen extends StatelessWidget {
  const NotificationsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(CielSpacing.lg),
          child: Text('Notifications — coming soon'),
        ),
      ),
    );
  }
}
