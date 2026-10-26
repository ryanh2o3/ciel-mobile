import 'package:ciel_mobile/ui/tokens.dart';
import 'package:flutter/material.dart';

/// Returns the reason text entered by the user, or `null` if cancelled.
Future<String?> showReportSheet(
  BuildContext context, {
  String title = 'Report',
  String description =
      'Tell us why you are reporting this. Our team will review your report.',
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      final controller = TextEditingController();
      return Padding(
        padding: EdgeInsets.only(
          left: CielSpacing.md,
          right: CielSpacing.md,
          top: CielSpacing.md,
          bottom: MediaQuery.viewInsetsOf(context).bottom + CielSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: CielSpacing.sm),
            Text(description),
            const SizedBox(height: CielSpacing.md - 4),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Reason (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: CielSpacing.md - 4),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Submit report'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    },
  );
}

/// Convenience for reporting a user account.
Future<String?> showReportUserSheet(BuildContext context) {
  return showReportSheet(
    context,
    title: 'Report user',
    description:
        'Tell us why you are reporting this account. '
        'Our team will review your report.',
  );
}

/// Convenience for reporting a post.
Future<String?> showReportPostSheet(BuildContext context) {
  return showReportSheet(
    context,
    title: 'Report post',
    description:
        'Tell us why you are reporting this post. '
        'Our team will review your report.',
  );
}
