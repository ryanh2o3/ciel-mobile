import 'package:ciel_mobile/ui/tokens.dart';
import 'package:flutter/material.dart';

/// A tappable row used to surface compose options (audience, location, …).
///
/// Layout: leading icon · label · trailing value · chevron. Matches the
/// iOS Settings / "form row" pattern but renders on a Material surface.
class CielComposeRow extends StatelessWidget {
  const CielComposeRow({
    required this.icon,
    required this.label,
    super.key,
    this.trailing,
    this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = enabled
        ? scheme.onSurface
        : scheme.onSurface.withValues(alpha: 0.38);
    final subForeground = enabled
        ? scheme.onSurfaceVariant
        : scheme.onSurface.withValues(alpha: 0.38);

    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(CielRadii.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(CielRadii.lg),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: CielSpacing.md,
            vertical: CielSpacing.md,
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: foreground),
              const SizedBox(width: CielSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: foreground,
                  ),
                ),
              ),
              if (trailing != null) ...[
                Text(
                  trailing!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: subForeground,
                  ),
                ),
                const SizedBox(width: CielSpacing.xs),
              ],
              Icon(Icons.chevron_right, size: 20, color: subForeground),
            ],
          ),
        ),
      ),
    );
  }
}
