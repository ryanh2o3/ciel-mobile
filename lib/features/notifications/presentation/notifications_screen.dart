import 'package:ciel_mobile/app/providers/dependency_providers.dart';
import 'package:ciel_mobile/domain/entities/app_notification.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final List<AppNotification> _items = [];
  String? _cursor;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
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
      final page = await ref.read(notificationsUseCaseProvider).fetchNotifications(
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
        _error = e.toString();
      });
    }
  }

  Future<void> _open(AppNotification n) async {
    if (n.readAt == null) {
      try {
        await ref.read(notificationsUseCaseProvider).markRead(n.id);
      } on Object catch (_) {}
    }
    final postId = n.payload['post_id']?.toString();
    if (postId != null && mounted) {
      context.push('/post/$postId');
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
                    title: Text(n.notificationType),
                    subtitle: Text(n.payload.toString()),
                    trailing: n.readAt == null
                        ? Icon(Icons.circle, size: 10, color: Theme.of(context).colorScheme.primary)
                        : null,
                    onTap: () => _open(n),
                  );
                },
              ),
      ),
    );
  }
}
