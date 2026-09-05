import 'dart:async';
import 'dart:io';

import 'package:ciel_mobile/app/providers/dependency_providers.dart';
import 'package:ciel_mobile/core/errors/error_snackbar.dart';
import 'package:ciel_mobile/core/media/image_normalizer.dart';
import 'package:ciel_mobile/domain/entities/post.dart';
import 'package:ciel_mobile/domain/entities/relationship.dart';
import 'package:ciel_mobile/domain/entities/user.dart';
import 'package:ciel_mobile/features/auth/presentation/auth_notifier.dart';
import 'package:ciel_mobile/ui/ciel_avatar.dart';
import 'package:ciel_mobile/ui/ciel_network_image.dart';
import 'package:ciel_mobile/ui/report_user_sheet.dart';
import 'package:ciel_mobile/ui/tokens.dart';
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
  bool _refreshing = false;
  bool _avatarUploading = false;
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

  Future<void> _load(String id, {bool soft = false}) async {
    if (soft && _user != null) {
      setState(() {
        _refreshing = true;
        _error = null;
      });
    } else {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
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
          _refreshing = false;
        });
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _refreshing = false;
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
      await _load(u.id, soft: true);
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
      await _load(u.id, soft: true);
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
    if (me == null || _avatarUploading) {
      return;
    }
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) {
      return;
    }
    setState(() => _avatarUploading = true);
    try {
      final normalized = await ImageNormalizer.normalizeExifOrientation(
        File(file.path),
      );
      final bytes = await normalized.readAsBytes();
      final thumbKey = await ref
          .read(mediaUseCaseProvider)
          .uploadImageAndWaitForThumbKey(
            data: bytes,
          );
      await ref
          .read(userUseCaseProvider)
          .updateProfile(
            id: me.id,
            avatarKey: thumbKey,
          );
      await _load(me.id, soft: true);
      unawaited(ref.read(authNotifierProvider.notifier).restoreSession());
    } on Object catch (e) {
      if (mounted) {
        showErrorSnackBar(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _avatarUploading = false);
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
    if (_error != null && _user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(CielSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error ?? 'Not signed in', textAlign: TextAlign.center),
                const SizedBox(height: CielSpacing.md),
                if (_resolvedId != null)
                  FilledButton(
                    onPressed: () => unawaited(_load(_resolvedId!)),
                    child: const Text('Retry'),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    final u = _user!;
    final rel = _rel;
    final scheme = Theme.of(context).colorScheme;

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
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => _load(u.id, soft: true),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(CielSpacing.md),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CielAvatar(
                              imageUrl: u.avatarUrl,
                              size: CielAvatarSize.xl,
                              label: u.displayName,
                              onTap: isSelf ? _changeAvatar : null,
                            ),
                            if (isSelf)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Material(
                                  color: scheme.primary,
                                  shape: const CircleBorder(),
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: _avatarUploading
                                        ? null
                                        : _changeAvatar,
                                    child: Padding(
                                      padding: const EdgeInsets.all(6),
                                      child: Icon(
                                        Icons.camera_alt,
                                        size: 16,
                                        color: scheme.onPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: CielSpacing.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '@${u.handle}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: CielSpacing.sm),
                              Row(
                                children: [
                                  _StatChip(
                                    label: 'posts',
                                    value: u.postsCount,
                                  ),
                                  const SizedBox(width: CielSpacing.md),
                                  _StatChip(
                                    label: 'followers',
                                    value: u.followersCount,
                                  ),
                                  const SizedBox(width: CielSpacing.md),
                                  _StatChip(
                                    label: 'following',
                                    value: u.followingCount,
                                  ),
                                ],
                              ),
                              if (u.bio != null && u.bio!.isNotEmpty) ...[
                                const SizedBox(height: CielSpacing.sm),
                                Text(u.bio!),
                              ],
                              if (!isSelf && rel != null) ...[
                                const SizedBox(height: CielSpacing.md),
                                FilledButton(
                                  onPressed:
                                      rel.isBlockedBy ? null : _toggleFollow,
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
                if (_posts.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(CielSpacing.lg),
                        child: Text(
                          isSelf
                              ? 'No posts yet. Share your first photo.'
                              : 'No posts yet',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ),
                  )
                else
                  SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 2,
                      crossAxisSpacing: 2,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final post = _posts[index];
                        final thumbUrl = post.primaryMedia?.mediumUrl ??
                            post.primaryMedia?.thumbUrl;
                        return GestureDetector(
                          onTap: () => context.push('/post/${post.id}'),
                          child: CielNetworkImage(imageUrl: thumbUrl),
                        );
                      },
                      childCount: _posts.length,
                    ),
                  ),
              ],
            ),
          ),
          if (_avatarUploading || _refreshing)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: scheme.surface.withValues(alpha: 0),
              ),
            ),
          if (_avatarUploading)
            const ModalBarrier(dismissible: false, color: Colors.black26),
          if (_avatarUploading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
