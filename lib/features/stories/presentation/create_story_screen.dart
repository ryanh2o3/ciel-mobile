import 'dart:io';

import 'package:ciel_mobile/app/providers/dependency_providers.dart';
import 'package:ciel_mobile/core/media/image_normalizer.dart';
import 'package:ciel_mobile/domain/entities/story.dart';
import 'package:ciel_mobile/features/feed/presentation/feed_notifier.dart';
import 'package:ciel_mobile/features/stories/presentation/story_audience_options.dart';
import 'package:ciel_mobile/ui/ciel_audience_picker_sheet.dart';
import 'package:ciel_mobile/ui/ciel_compose_row.dart';
import 'package:ciel_mobile/ui/ciel_primary_button.dart';
import 'package:ciel_mobile/ui/ciel_thumbnail.dart';
import 'package:ciel_mobile/ui/tokens.dart';
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
  static const int _captionLimit = 280;

  final _caption = TextEditingController();
  XFile? _image;
  StoryVisibility _visibility = StoryVisibility.public;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _caption.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file != null && mounted) {
      setState(() => _image = file);
    }
  }

  Future<void> _pickAudience() async {
    final picked = await showCielAudiencePicker<StoryVisibility>(
      context: context,
      options: kStoryAudienceOptions,
      selected: _visibility,
    );
    if (picked != null && mounted) {
      setState(() => _visibility = picked);
    }
  }

  Future<void> _submit() async {
    final file = _image;
    if (file == null) {
      setState(() => _error = 'Choose a photo to share.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final normalized = await ImageNormalizer.normalizeExifOrientation(
        File(file.path),
      );
      final bytes = await normalized.readAsBytes();
      final caption = _caption.text.trim();
      await ref
          .read(storyUseCaseProvider)
          .createStoryFromImage(
            imageBytes: bytes,
            caption: caption.isEmpty ? null : caption,
            visibility: _visibility,
          );
      if (!mounted) return;
      ref.invalidate(feedNotifierProvider);
      context.pop();
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
    final canSubmit = !_busy && _image != null;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _busy ? null : () => context.pop(),
          tooltip: 'Cancel',
        ),
        title: const Text('New story'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  CielSpacing.md,
                  CielSpacing.sm,
                  CielSpacing.md,
                  CielSpacing.md,
                ),
                children: [
                  if (_error != null) ...[
                    _ErrorBanner(message: _error!),
                    const SizedBox(height: CielSpacing.md),
                  ],
                  _CaptionRow(
                    file: _image == null ? null : File(_image!.path),
                    controller: _caption,
                    onPickImage: _busy ? null : _pickImage,
                    enabled: !_busy,
                    captionLimit: _captionLimit,
                  ),
                  const SizedBox(height: CielSpacing.lg),
                  CielComposeRow(
                    icon: Icons.visibility_outlined,
                    label: 'Audience',
                    trailing: storyVisibilityLabel(_visibility),
                    enabled: !_busy,
                    onTap: _pickAudience,
                  ),
                  const SizedBox(height: CielSpacing.sm),
                  const CielComposeRow(
                    icon: Icons.location_on_outlined,
                    label: 'Add location',
                    enabled: false,
                  ),
                  if (_busy) ...[
                    const SizedBox(height: CielSpacing.lg),
                    const LinearProgressIndicator(),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                CielSpacing.md,
                CielSpacing.sm,
                CielSpacing.md,
                CielSpacing.md,
              ),
              child: CielPrimaryButton(
                label: 'Share story',
                isLoading: _busy,
                onPressed: canSubmit ? _submit : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptionRow extends StatelessWidget {
  const _CaptionRow({
    required this.file,
    required this.controller,
    required this.onPickImage,
    required this.enabled,
    required this.captionLimit,
  });

  final File? file;
  final TextEditingController controller;
  final VoidCallback? onPickImage;
  final bool enabled;
  final int captionLimit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final length = controller.text.characters.length;
    final warn = length > (captionLimit * 0.8).round();
    return Container(
      padding: const EdgeInsets.all(CielSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(CielRadii.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CielThumbnail(
            file: file,
            placeholderLabel: file == null ? 'Choose' : null,
            onTap: onPickImage,
          ),
          const SizedBox(width: CielSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: controller,
                  enabled: enabled,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: captionLimit,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    hintText: 'Write a caption…',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    counterText: '',
                  ),
                ),
                const SizedBox(height: CielSpacing.xs),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '$length / $captionLimit',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: warn ? scheme.error : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(CielSpacing.md),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(CielRadii.lg),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: scheme.onErrorContainer),
          const SizedBox(width: CielSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
