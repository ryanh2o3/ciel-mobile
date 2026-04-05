import 'dart:io';

import 'package:ciel_mobile/app/providers/dependency_providers.dart';
import 'package:ciel_mobile/domain/entities/story.dart';
import 'package:ciel_mobile/features/feed/presentation/feed_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class CreateStoryScreen extends ConsumerStatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  ConsumerState<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends ConsumerState<CreateStoryScreen> {
  final _caption = TextEditingController();
  XFile? _image;
  StoryVisibility _vis = StoryVisibility.public;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final f = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (f != null) {
      setState(() => _image = f);
    }
  }

  Future<void> _submit() async {
    final file = _image;
    if (file == null) {
      setState(() => _error = 'Select a photo');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final bytes = await File(file.path).readAsBytes();
      await ref.read(storyUseCaseProvider).createStoryFromImage(
            imageBytes: bytes,
            caption: _caption.text.trim().isEmpty ? null : _caption.text.trim(),
            visibility: _vis,
          );
      if (mounted) {
        ref.invalidate(feedNotifierProvider);
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
        title: const Text('New story'),
        actions: [
          TextButton(
            onPressed: _busy ? null : _submit,
            child: const Text('Post'),
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
            icon: const Icon(Icons.photo_outlined),
            label: const Text('Choose photo'),
          ),
          const SizedBox(height: 12),
          if (_image != null)
            AspectRatio(
              aspectRatio: 1,
              child: Image.file(File(_image!.path), fit: BoxFit.cover),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _caption,
            decoration: const InputDecoration(
              labelText: 'Caption',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<StoryVisibility>(
            initialValue: _vis,
            decoration: const InputDecoration(labelText: 'Visibility'),
            items: const [
              DropdownMenuItem(value: StoryVisibility.public, child: Text('Public')),
              DropdownMenuItem(
                value: StoryVisibility.friendsOnly,
                child: Text('Friends only'),
              ),
              DropdownMenuItem(
                value: StoryVisibility.closeFriendsOnly,
                child: Text('Close friends'),
              ),
            ],
            onChanged: _busy
                ? null
                : (v) {
                    if (v != null) {
                      setState(() => _vis = v);
                    }
                  },
          ),
          if (_busy) const LinearProgressIndicator(),
        ],
      ),
    );
  }
}
