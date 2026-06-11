import 'dart:async';

import 'package:ciel_mobile/app/providers/dependency_providers.dart';
import 'package:ciel_mobile/core/errors/app_failure_mapper.dart';
import 'package:ciel_mobile/core/errors/error_snackbar.dart';
import 'package:ciel_mobile/domain/entities/app_notification.dart';
import 'package:ciel_mobile/features/notifications/notification_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final List<AppNotification> _items = [];
  String? _cursor;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_fetch());
  }

  Future<void> _fetch({bool refresh = false}) async {
    if (_loading) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      if (refresh) {
        _items.clear();
        _cursor = null;
      }
    });
    try {
      final page = await ref
          .read(notificationsUseCaseProvider)
          .fetchNotifications(
            limit: 30,
            cursor: refresh ? null : _cursor,
          );
      setState(() {
        _items.addAll(page.items);
        _cursor = page.nextCursor;
        _loading = false;
      });
    } on Object catch (e) {
      setState(() {
        _loading = false;
        _error = mapToFailure(e).userMessage;
      });
    }
  }

  Future<void> _open(AppNotification n) async {
    if (n.readAt == null) {
      try {
        await ref.read(notificationsUseCaseProvider).markRead(n.id);
      } on Object catch (e) {
        if (mounted) {
          showErrorSnackBar(context, e);
        }
      }
    }
    final postId = n.payload['post_id']?.toString();
    if (postId != null && mounted) {
      await context.push('/post/$postId');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: RefreshIndicator(
        onRefresh: () => _fetch(refresh: true),
        child: _error != null && _items.isEmpty
            ? ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!),
                  ),
                ],
              )
            : ListView.builder(
                itemCount: _items.length,
                itemBuilder: (context, i) {
                  final n = _items[i];
                  return ListTile(
                    title: Text(notificationMessage(n)),
                    subtitle: Text(
                      _formatWhen(n.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    trailing: n.readAt == null
                        ? Icon(
                            Icons.circle,
                            size: 10,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                    onTap: () => _open(n),
                  );
                },
              ),
      ),
    );
  }

  String _formatWhen(DateTime when) {
    final diff = DateTime.now().difference(when);
    if (diff.inMinutes < 1) {
      return 'Just now';
    }
    if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    }
    if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    }
    return '${diff.inDays}d ago';
  }
}
