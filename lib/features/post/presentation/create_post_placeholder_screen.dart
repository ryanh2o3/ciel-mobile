import 'package:ciel_mobile/ui/tokens.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CreatePostPlaceholderScreen extends StatelessWidget {
  const CreatePostPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: const Text('Create'),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(CielSpacing.lg),
          child: Text('Create post — coming soon'),
        ),
      ),
    );
  }
}
