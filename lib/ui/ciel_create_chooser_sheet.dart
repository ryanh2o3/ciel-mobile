import 'package:ciel_mobile/ui/tokens.dart';
import 'package:flutter/material.dart';

enum CielCreateChoice { post, story }

Future<CielCreateChoice?> showCielCreateChooserSheet(BuildContext context) {
  return showModalBottomSheet<CielCreateChoice>(
    context: context,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: CielSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.grid_on_outlined),
                title: const Text('New post'),
                subtitle: const Text('Share photos to your profile'),
                onTap: () => Navigator.pop(context, CielCreateChoice.post),
              ),
              ListTile(
                leading: const Icon(Icons.auto_awesome_outlined),
                title: const Text('New story'),
                subtitle: const Text('Visible for 24 hours'),
                onTap: () => Navigator.pop(context, CielCreateChoice.story),
              ),
            ],
          ),
        ),
      );
    },
  );
}
