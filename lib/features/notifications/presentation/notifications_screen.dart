import 'dart:async';

import 'package:ciel_mobile/app/providers/dependency_providers.dart';
import 'package:ciel_mobile/core/errors/app_failure_mapper.dart';
import 'package:ciel_mobile/core/errors/error_snackbar.dart';
import 'package:ciel_mobile/domain/entities/app_notification.dart';
import 'package:ciel_mobile/features/notifications/notification_message.dart';
import 'package:ciel_mobile/features/notifications/presentation/notifications_unread_provider.dart';
import 'package:ciel_mobile/ui/ciel_avatar.dart';
import 'package:ciel_mobile/ui/ciel_empty_state.dart';
import 'package:ciel_mobile/ui/ciel_relative_time.dart';
import 'package:ciel_mobile/ui/tokens.dart';
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
  bool _initial = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_fetch(refresh: true));
  }

  void _syncUnreadBadge() {
    final hasUnread = _items.any((n) => n.readAt == null);
    ref
        .read(notificationsHasUnreadProvider.notifier)
        .setHasUnread(value: hasUnread);
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
        _initial = false;
      });
      _syncUnreadBadge();
    } on Object catch (e) {
      setState(() {
        _loading = false;
        _initial = false;
        _error = mapToFailure(e).userMessage;
      });
    }
  }

  String? _actorHandle(AppNotification n) {
    final payload = n.payload;
    return switch (n.notificationType) {
      'user_followed' => payload['follower_handle']?.toString(),
      'post_liked' => payload['liker_handle']?.toString(),
      'post_commented' => payload['commenter_handle']?.toString(),
      'story_reaction' => payload['reactor_handle']?.toString(),
      _ => null,
    };
  }

  String? _actorId(AppNotification n) {
    final payload = n.payload;
    return switch (n.notificationType) {
      'user_followed' =>
        payload['follower_id']?.toString() ?? payload['actor_id']?.toString(),
      'post_liked' =>
        payload['liker_id']?.toString() ?? payload['actor_id']?.toString(),
      'post_commented' =>
        payload['commenter_id']?.toString() ?? payload['actor_id']?.toString(),
      'story_reaction' =>
        payload['reactor_id']?.toString() ?? payload['actor_id']?.toString(),
      _ => payload['actor_id']?.toString(),
    };
  }

  String? _avatarUrl(AppNotification n) {
    return n.payload['actor_avatar_url']?.toString() ??
        n.payload['avatar_url']?.toString();
  }

  Future<void> _open(AppNotification n) async {
    if (n.readAt == null) {
      try {
        await ref.read(notificationsUseCaseProvider).markRead(n.id);
        final i = _items.indexWhere((x) => x.id == n.id);
        if (i >= 0 && mounted) {
          setState(() {
            _items[i] = AppNotification(
              id: n.id,
              userId: n.userId,
              notificationType: n.notificationType,
              payload: n.payload,
              createdAt: n.createdAt,
              readAt: DateTime.now(),
            );
          });
          _syncUnreadBadge();
        }
      } on Object catch (e) {
        if (mounted) {
          showErrorSnackBar(context, e);
        }
      }
    }

    if (!mounted) {
      return;
    }

    if (n.notificationType == 'user_followed') {
      final userId = _actorId(n);
      if (userId != null) {
        await context.push('/profile/$userId');
        return;
      }
    }

    final postId = n.payload['post_id']?.toString();
    if (postId != null) {
      await context.push('/post/$postId');
      return;
    }

    final userId = _actorId(n);
    if (userId != null) {
      await context.push('/profile/$userId');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: _initial && _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _fetch(refresh: true),
              child: _error != null && _items.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.sizeOf(context).height * 0.5,
                          child: CielEmptyState(
                            icon: Icons.error_outline,
                            title: _error!,
                            actionLabel: 'Retry',
                            onAction: () => _fetch(refresh: true),
                          ),
                        ),
                      ],
                    )
                  : _items.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.sizeOf(context).height * 0.5,
                              child: const CielEmptyState(
                                icon: Icons.notifications_none,
                                title: 'You’re all caught up',
                                subtitle: 'Likes, comments, and follows '
                                    'will show up here.',
                              ),
                            ),
                          ],
                        )
                      : NotificationListener<ScrollNotification>(
                          onNotification: (n) {
                            if (n.metrics.pixels >
                                    n.metrics.maxScrollExtent - 200 &&
                                _cursor != null &&
                                !_loading) {
                              unawaited(_fetch());
                            }
                            return false;
                          },
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: _items.length + (_loading ? 1 : 0),
                            itemBuilder: (context, i) {
                              if (i >= _items.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(CielSpacing.md),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              final n = _items[i];
                              final unread = n.readAt == null;
                              final handle = _actorHandle(n);
                              return ListTile(
                                tileColor: unread
                                    ? scheme.primaryContainer
                                        .withValues(alpha: 0.25)
                                    : null,
                                leading: CielAvatar(
                                  imageUrl: _avatarUrl(n),
                                  size: CielAvatarSize.sm,
                                  label: handle ?? '?',
                                ),
                                title: Text(
                                  notificationMessage(n),
                                  style: TextStyle(
                                    fontWeight: unread
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                                subtitle: Text(
                                  cielRelativeTime(n.createdAt),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                trailing: unread
                                    ? Icon(
                                        Icons.circle,
                                        size: 10,
                                        color: scheme.primary,
                                      )
                                    : null,
                                onTap: () => _open(n),
                              );
                            },
                          ),
                        ),
            ),
    );
  }
}
