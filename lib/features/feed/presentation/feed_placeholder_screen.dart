import 'package:ciel_mobile/ui/tokens.dart';
import 'package:flutter/material.dart';

class FeedPlaceholderScreen extends StatelessWidget {
  const FeedPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(CielSpacing.lg),
          child: Text('Feed — coming soon'),
        ),
      ),
    );
  }
}
