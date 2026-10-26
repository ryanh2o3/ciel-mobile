import 'dart:async';

import 'package:ciel_mobile/app/providers/dependency_providers.dart';
import 'package:ciel_mobile/core/errors/app_failure_mapper.dart';
import 'package:ciel_mobile/domain/entities/followed_user.dart';
import 'package:ciel_mobile/ui/ciel_empty_state.dart';
import 'package:ciel_mobile/ui/ciel_user_list_tile.dart';
import 'package:ciel_mobile/ui/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum FollowListKind { followers, following }

class FollowListScreen extends ConsumerStatefulWidget {
  const FollowListScreen({
    required this.userId,
    required this.kind,
    super.key,
  });

  final String userId;
  final FollowListKind kind;

  @override
  ConsumerState<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends ConsumerState<FollowListScreen> {
  final List<FollowedUser> _items = [];
  String? _cursor;
  bool _loading = false;
  bool _initial = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_fetch(refresh: true));
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
      final useCase = ref.read(userUseCaseProvider);
      final page = widget.kind == FollowListKind.followers
          ? await useCase.fetchFollowers(
              id: widget.userId,
              limit: 40,
              cursor: refresh ? null : _cursor,
            )
          : await useCase.fetchFollowing(
              id: widget.userId,
              limit: 40,
              cursor: refresh ? null : _cursor,
            );
      if (mounted) {
        setState(() {
          _items.addAll(page.items);
          _cursor = page.nextCursor;
          _loading = false;
          _initial = false;
        });
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _initial = false;
          _error = mapToFailure(e).userMessage;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.kind == FollowListKind.followers
        ? 'Followers'
        : 'Following';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
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
                              child: CielEmptyState(
                                icon: Icons.people_outline,
                                title: widget.kind == FollowListKind.followers
                                    ? 'No followers yet'
                                    : 'Not following anyone',
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
                              final u = _items[i].user;
                              return CielUserListTile(
                                avatarUrl: u.avatarUrl,
                                displayName: u.displayName,
                                handle: u.handle,
                                onTap: () => context.push('/profile/${u.id}'),
                              );
                            },
                          ),
                        ),
            ),
    );
  }
}
