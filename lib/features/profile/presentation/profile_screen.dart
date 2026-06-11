import 'dart:async';
import 'dart:io';

import 'package:ciel_mobile/app/providers/dependency_providers.dart';
import 'package:ciel_mobile/core/errors/error_snackbar.dart';
import 'package:ciel_mobile/core/media/image_normalizer.dart';
import 'package:ciel_mobile/domain/entities/post.dart';
import 'package:ciel_mobile/domain/entities/relationship.dart';
import 'package:ciel_mobile/domain/entities/user.dart';
import 'package:ciel_mobile/features/auth/presentation/auth_notifier.dart';
import 'package:ciel_mobile/ui/ciel_network_image.dart';
import 'package:ciel_mobile/ui/report_user_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

/// Shell tab: [userId] is null (self). Pushed routes pass [userId].
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({this.userId, super.key});

  final String? userId;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  User? _user;
  Relationship? _rel;
  List<Post> _posts = [];
  bool _loading = true;
  String? _error;
  String? _resolvedId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final id = widget.userId ?? ref.read(authNotifierProvider).user?.id;
      if (id != null && id != _resolvedId) {
        _resolvedId = id;
        unawaited(_load(id));
      }
    });
  }

  Future<void> _load(String id) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await ref.read(userUseCaseProvider).fetchUser(id);
      Relationship? rel;
      final me = ref.read(authNotifierProvider).user;
      if (me != null && me.id != id) {
        rel = await ref.read(userUseCaseProvider).fetchRelationship(id);
      }
      final page = await ref
          .read(userUseCaseProvider)
          .fetchUserPosts(
            id: id,
            limit: 30,
          );
      if (mounted) {
        setState(() {
          _user = user;
          _rel = rel;
          _posts = page.items;
          _loading = false;
        });
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _toggleFollow() async {
    final u = _user;
    final r = _rel;
    if (u == null || r == null) {
      return;
    }
    try {
      if (r.isFollowing) {
        await ref.read(userUseCaseProvider).unfollow(u.id);
      } else {
        await ref.read(userUseCaseProvider).follow(u.id);
      }
      await _load(u.id);
    } on Object catch (e) {
      if (mounted) {
        showErrorSnackBar(context, e);
      }
    }
  }

  Future<void> _toggleBlock() async {
    final u = _user;
    final r = _rel;
    if (u == null || r == null) {
      return;
    }
    try {
      if (r.isBlocking) {
        await ref.read(userUseCaseProvider).unblock(u.id);
        if (mounted) {
          showSuccessSnackBar(context, 'User unblocked');
        }
      } else {
        final ok = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Block user?'),
            content: const Text(
              'They will no longer be able to see your content or '
              'interact with you.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('Block'),
              ),
            ],
          ),
        );
        if (ok != true) {
          return;
        }
        await ref.read(userUseCaseProvider).block(u.id);
        if (mounted) {
          showSuccessSnackBar(context, 'User blocked');
        }
      }
      await _load(u.id);
    } on Object catch (e) {
      if (mounted) {
        showErrorSnackBar(context, e);
      }
    }
  }

  Future<void> _reportUser() async {
    final u = _user;
    if (u == null) {
      return;
    }
    final reason = await showReportUserSheet(context);
    if (reason == null) {
      return;
    }
    try {
      await ref
          .read(moderationUseCaseProvider)
          .reportUser(userId: u.id, reason: reason.isEmpty ? null : reason);
      if (mounted) {
        showSuccessSnackBar(context, 'Report submitted');
      }
    } on Object catch (e) {
      if (mounted) {
        showErrorSnackBar(context, e);
      }
    }
  }

  Future<void> _changeAvatar() async {
    final me = ref.read(authNotifierProvider).user;
    if (me == null) {
      return;
    }
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) {
      return;
    }
    try {
      final normalized = await ImageNormalizer.normalizeExifOrientation(
        File(file.path),
      );
      final bytes = await normalized.readAsBytes();
      final mediaId = await ref
          .read(mediaUseCaseProvider)
          .uploadImageAndWaitForMediaId(
            data: bytes,
          );
      await ref
          .read(userUseCaseProvider)
          .updateProfile(
            id: me.id,
            avatarKey: mediaId,
          );
      await _load(me.id);
      unawaited(ref.read(authNotifierProvider.notifier).restoreSession());
    } on Object catch (e) {
      if (mounted) {
        showErrorSnackBar(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(authNotifierProvider).user;
    final isSelf = widget.userId == null || widget.userId == me?.id;

    if (_loading && _user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(child: Text(_error ?? 'Not signed in')),
      );
    }

    final u = _user!;
    final rel = _rel;

    return Scaffold(
      appBar: AppBar(
        title: Text(u.displayName),
        actions: [
          if (isSelf)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.push('/settings'),
            )
          else if (rel != null)
            PopupMenuButton<String>(
              onSelected: (value) async {
                switch (value) {
                  case 'block':
                    await _toggleBlock();
                  case 'report':
                    await _reportUser();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'block',
                  child: Text(rel.isBlocking ? 'Unblock' : 'Block'),
                ),
                const PopupMenuItem(
                  value: 'report',
                  child: Text('Report'),
                ),
              ],
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: isSelf ? _changeAvatar : null,
                    child: CircleAvatar(
                      radius: 40,
                      child: ClipOval(
                        child: CielNetworkImage(
                          imageUrl: u.avatarUrl,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '@${u.handle}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${u.postsCount} posts · '
                          '${u.followersCount} followers · '
                          '${u.followingCount} following',
                        ),
                        if (!isSelf && rel != null) ...[
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: rel.isBlockedBy ? null : _toggleFollow,
                            child: Text(
                              rel.isFollowing ? 'Unfollow' : 'Follow',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final post = _posts[index];
                final thumbUrl =
                    post.primaryMedia?.mediumUrl ?? post.primaryMedia?.thumbUrl;
                return GestureDetector(
                  onTap: () => context.push('/post/${post.id}'),
                  child: CielNetworkImage(
                    imageUrl: thumbUrl,
                  ),
                );
              },
              childCount: _posts.length,
            ),
          ),
        ],
      ),
    );
  }
}
