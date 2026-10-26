import 'package:ciel_mobile/ui/ciel_avatar.dart';
import 'package:ciel_mobile/ui/tokens.dart';
import 'package:flutter/material.dart';

/// Avatar + display name + @handle with optional trailing action.
class CielUserListTile extends StatelessWidget {
  const CielUserListTile({
    required this.displayName,
    required this.handle,
    super.key,
    this.avatarUrl,
    this.trailing,
    this.onTap,
  });

  final String? avatarUrl;
  final String displayName;
  final String handle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: CielSpacing.md),
      leading: CielAvatar(
        imageUrl: avatarUrl,
        size: CielAvatarSize.sm,
        label: displayName.isNotEmpty ? displayName : handle,
        onTap: onTap,
      ),
      title: Text(
        displayName.isNotEmpty ? displayName : handle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        handle.startsWith('@') ? handle : '@$handle',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
