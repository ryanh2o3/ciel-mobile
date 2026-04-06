import 'dart:async';

import 'package:ciel_mobile/app/providers/dependency_providers.dart';
import 'package:ciel_mobile/domain/entities/invite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InvitesScreen extends ConsumerStatefulWidget {
  const InvitesScreen({super.key});

  @override
  ConsumerState<InvitesScreen> createState() => _InvitesScreenState();
}

class _InvitesScreenState extends ConsumerState<InvitesScreen> {
  InviteStats? _stats;
  List<InviteCode> _codes = [];
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
      final stats = await ref.read(inviteUseCaseProvider).getInviteStats();
      final list = await ref.read(inviteUseCaseProvider).getInvites();
      if (mounted) {
        setState(() {
          _stats = stats;
          _codes = list;
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

  Future<void> _create() async {
    final days = await showDialog<int>(
      context: context,
      builder: (c) => SimpleDialog(
        title: const Text('Invite validity'),
        children: [7, 14, 30].map((d) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(c, d),
            child: Text('$d days'),
          );
        }).toList(),
      ),
    );
    if (days == null) {
      return;
    }
    try {
      await ref.read(inviteUseCaseProvider).createInvite(daysValid: days);
      await _load();
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
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
    final s = _stats;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invites'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _create),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_error != null) Text(_error!),
            if (s != null) ...[
              Text('Sent: ${s.invitesSent} / ${s.maxInvites}'),
              Text('Successful signups: ${s.successfulInvites}'),
              Text('Remaining: ${s.remainingInvites}'),
              const SizedBox(height: 24),
            ],
            const Text(
              'Your codes',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ..._codes.map(
              (c) => ListTile(
                title: Text(c.code),
                subtitle: Text(
                  'Valid: ${c.isValid} · Uses ${c.useCount}/${c.maxUses}',
                ),
                trailing: c.isValid && c.usedBy == null
                    ? IconButton(
                        icon: const Icon(Icons.block),
                        onPressed: () async {
                          try {
                            await ref
                                .read(inviteUseCaseProvider)
                                .revokeInvite(c.code);
                            await _load();
                          } on Object catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(SnackBar(content: Text('$e')));
                            }
                          }
                        },
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
