import 'dart:async';
import 'dart:io';

import 'package:ciel_mobile/app/providers/dependency_providers.dart';
import 'package:ciel_mobile/core/media/image_normalizer.dart';
import 'package:ciel_mobile/features/auth/presentation/auth_notifier.dart';
import 'package:ciel_mobile/features/feed/presentation/feed_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _caption = TextEditingController();
  final List<XFile> _images = [];
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final picker = ImagePicker();
    final list = await picker.pickMultiImage();
    if (list.isNotEmpty) {
      setState(() {
        _images
          ..clear()
          ..addAll(list);
      });
    }
  }

  Future<void> _submit() async {
    if (_images.isEmpty) {
      setState(() => _error = 'Select at least one photo');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final media = ref.read(mediaUseCaseProvider);
      final post = ref.read(postUseCaseProvider);
      final ids = <String>[];
      for (final file in _images) {
        final normalized = await ImageNormalizer.normalizeExifOrientation(File(file.path));
        final bytes = await normalized.readAsBytes();
        final id = await media.uploadImageAndWaitForMediaId(data: bytes);
        ids.add(id);
      }
      await post.createPost(
        mediaIds: ids,
        caption: _caption.text.trim().isEmpty ? null : _caption.text.trim(),
      );
      if (mounted) {
        final user = ref.read(authNotifierProvider).user;
        unawaited(ref.read(feedNotifierProvider.notifier).refresh(user));
        context.pop();
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New post'),
        actions: [
          TextButton(
            onPressed: _busy ? null : _submit,
            child: const Text('Share'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_error != null)
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          FilledButton.icon(
            onPressed: _busy ? null : _pick,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Choose photos'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _images
                  .map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Image.file(File(f.path), width: 120, fit: BoxFit.cover),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _caption,
            decoration: const InputDecoration(
              labelText: 'Caption',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
          ),
          if (_busy) const LinearProgressIndicator(),
        ],
      ),
    );
  }
}
