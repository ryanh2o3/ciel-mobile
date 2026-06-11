import 'package:ciel_mobile/app/providers/dependency_providers.dart';
import 'package:ciel_mobile/core/errors/error_snackbar.dart';
import 'package:ciel_mobile/domain/entities/post.dart';
import 'package:ciel_mobile/domain/entities/user.dart';
import 'package:ciel_mobile/ui/ciel_network_image.dart';
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

  @override
  void dispose() {
    _tabs.dispose();
    _q.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final query = _q.text.trim();
    if (query.isEmpty) {
      return;
    }
    setState(() => _busy = true);
    try {
      final users = await ref
          .read(searchUseCaseProvider)
          .searchUsers(
            query: query,
            limit: 30,
          );
      final posts = await ref
          .read(searchUseCaseProvider)
          .searchPosts(
            query: query,
            limit: 30,
          );
      if (mounted) {
        setState(() {
          _users = users.items;
          _posts = posts.items;
          _busy = false;
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
          onSubmitted: (_) => _run(),
        ),
        actions: [
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
      body: _busy && _users.isEmpty && _posts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabs,
              children: [
                ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, i) {
                    final u = _users[i];
                    return ListTile(
                      leading: CircleAvatar(
                        child: ClipOval(
                          child: CielNetworkImage(
                            imageUrl: u.avatarUrl,
                          ),
                        ),
                      ),
                      title: Text(u.displayName),
                      subtitle: Text('@${u.handle}'),
                      onTap: () => context.push('/profile/${u.id}'),
                    );
                  },
                ),
                ListView.builder(
                  itemCount: _posts.length,
                  itemBuilder: (context, i) {
                    final p = _posts[i];
                    return ListTile(
                      title: Text(p.caption ?? 'Post'),
                      subtitle: Text('@${p.ownerHandle ?? ''}'),
                      onTap: () => context.push('/post/${p.id}'),
                    );
                  },
                ),
              ],
            ),
    );
  }
}
