import 'dart:async';

import 'package:ciel_mobile/app/providers/dependency_providers.dart';
import 'package:ciel_mobile/domain/entities/trust_score.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TrustScreen extends ConsumerStatefulWidget {
  const TrustScreen({super.key});

  @override
  ConsumerState<TrustScreen> createState() => _TrustScreenState();
}

class _TrustScreenState extends ConsumerState<TrustScreen> {
  TrustScore? _score;
  RateLimits? _limits;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final score = await ref.read(safetyUseCaseProvider).fetchTrustScore();
      final limits = await ref.read(safetyUseCaseProvider).fetchRateLimits();
      if (mounted) {
        setState(() {
          _score = score;
          _limits = limits;
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final s = _score;
    final l = _limits;
    return Scaffold(
      appBar: AppBar(title: const Text('Trust & safety')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_error != null) Text(_error!),
            if (s != null) ...[
              Text(
                'Level: ${s.trustLevelName}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text('Points: ${s.trustPoints}'),
              Text('Account age: ${s.accountAgeDays} days'),
              Text('Strikes: ${s.strikes}'),
              if (s.isBanned)
                const Text(
                  'Account restricted',
                  style: TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 24),
            ],
            if (l != null) ...[
              Text(
                'Rate limits (${l.trustLevel})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text('Posts / hour: ${l.postsPerHour}, day: ${l.postsPerDay}'),
              Text('Remaining posts: ${l.remaining.posts}'),
              Text('Remaining likes: ${l.remaining.likes}'),
              Text('Remaining comments: ${l.remaining.comments}'),
            ],
          ],
        ),
      ),
    );
  }
}
