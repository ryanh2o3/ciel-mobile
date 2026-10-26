import 'dart:async';

import 'package:ciel_mobile/app/providers/dependency_providers.dart';
import 'package:ciel_mobile/core/errors/error_snackbar.dart';
import 'package:ciel_mobile/domain/entities/post.dart';
import 'package:ciel_mobile/domain/entities/user.dart';
import 'package:ciel_mobile/ui/ciel_empty_state.dart';
import 'package:ciel_mobile/ui/ciel_network_image.dart';
import 'package:ciel_mobile/ui/ciel_user_list_tile.dart';
import 'package:ciel_mobile/ui/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  final _q = TextEditingController();
  List<User> _users = [];
  List<Post> _posts = [];
  bool _busy = false;
  bool _searched = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _q.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _q
      ..removeListener(_onQueryChanged)
      ..dispose();
    _tabs.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    final query = _q.text.trim();
    if (query.length < 2) {
      setState(() {
        _users = [];
        _posts = [];
        _searched = false;
        _busy = false;
      });
      return;
    }
    _debounce = Timer(CielDurations.slow, () {
      unawaited(_run());
    });
  }

  Future<void> _run() async {
    final query = _q.text.trim();
    if (query.length < 2) {
      return;
    }
    setState(() => _busy = true);
    try {
      final users = await ref.read(searchUseCaseProvider).searchUsers(
            query: query,
            limit: 30,
          );
      final posts = await ref.read(searchUseCaseProvider).searchPosts(
            query: query,
            limit: 30,
          );
      if (mounted && _q.text.trim() == query) {
        setState(() {
          _users = users.items;
          _posts = posts.items;
          _busy = false;
          _searched = true;
        });
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showErrorSnackBar(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _q,
          decoration: const InputDecoration(
            hintText: 'Search',
            border: InputBorder.none,
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _run(),
          autofocus: true,
        ),
        actions: [
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(CielSpacing.md),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(icon: const Icon(Icons.search), onPressed: _run),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Users'),
            Tab(text: 'Posts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _usersBody(),
          _postsBody(),
        ],
      ),
    );
  }

  Widget _usersBody() {
    if (!_searched && !_busy) {
      return const CielEmptyState(
        icon: Icons.search,
        title: 'Search people',
        subtitle: 'Type at least 2 characters to find users.',
      );
    }
    if (_busy && _users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_users.isEmpty) {
      return const CielEmptyState(
        icon: Icons.person_search_outlined,
        title: 'No users found',
      );
    }
    return ListView.builder(
      itemCount: _users.length,
      itemBuilder: (context, i) {
        final u = _users[i];
        return CielUserListTile(
          avatarUrl: u.avatarUrl,
          displayName: u.displayName,
          handle: u.handle,
          onTap: () => context.push('/profile/${u.id}'),
        );
      },
    );
  }

  Widget _postsBody() {
    if (!_searched && !_busy) {
      return const CielEmptyState(
        icon: Icons.photo_outlined,
        title: 'Search posts',
        subtitle: 'Find posts by caption text.',
      );
    }
    if (_busy && _posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_posts.isEmpty) {
      return const CielEmptyState(
        icon: Icons.image_not_supported_outlined,
        title: 'No posts found',
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: _posts.length,
      itemBuilder: (context, i) {
        final p = _posts[i];
        final thumb =
            p.primaryMedia?.mediumUrl ?? p.primaryMedia?.thumbUrl;
        return GestureDetector(
          onTap: () => context.push('/post/${p.id}'),
          child: CielNetworkImage(imageUrl: thumb),
        );
      },
    );
  }
}
