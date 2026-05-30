import 'dart:async';
import 'dart:io';

import 'package:ciel_mobile/features/auth/presentation/auth_notifier.dart';
import 'package:ciel_mobile/features/feed/presentation/feed_notifier.dart';
import 'package:ciel_mobile/features/post/presentation/create_post_notifier.dart';
import 'package:ciel_mobile/features/uploads/create_upload_overlay_host.dart';
import 'package:ciel_mobile/features/uploads/create_upload_state.dart';
import 'package:ciel_mobile/ui/ciel_compose_row.dart';
import 'package:ciel_mobile/ui/ciel_primary_button.dart';
import 'package:ciel_mobile/ui/ciel_thumbnail.dart';
import 'package:ciel_mobile/ui/tokens.dart';
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
  static const int _captionLimit = 2200;

  final _caption = TextEditingController();
  final List<XFile> _images = [];
  String? _formError;

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

  Future<void> _pickImages() async {
    final list = await ImagePicker().pickMultiImage();
    if (list.isNotEmpty && mounted) {
      setState(() {
        _images
          ..clear()
          ..addAll(list);
        _formError = null;
      });
    }
  }

  void _removeAt(int index) {
    setState(() => _images.removeAt(index));
  }

  Future<void> _submit() async {
    if (_images.isEmpty) {
      setState(() => _formError = 'Choose at least one photo to share.');
      return;
    }
    setState(() => _formError = null);
    final caption = _caption.text.trim();
    final ok = await ref
        .read(createPostControllerProvider.notifier)
        .submit(
          images: List.unmodifiable(_images),
          caption: caption.isEmpty ? null : caption,
        );
    if (!ok || !mounted) return;
    final user = ref.read(authNotifierProvider).user;
    unawaited(ref.read(feedNotifierProvider.notifier).refresh(user));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final upload = ref.watch(createPostControllerProvider);
    final busy = upload.isInFlight;
    final canSubmit = !busy && _images.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: busy ? null : () => context.pop(),
          tooltip: 'Cancel',
        ),
        title: const Text('New post'),
      ),
      body: Stack(
        children: [
          SafeArea(
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
                      if (_formError != null) ...[
                        _ErrorBanner(message: _formError!),
                        const SizedBox(height: CielSpacing.md),
                      ],
                      _CaptionRow(
                        leadingFile: _images.isEmpty
                            ? null
                            : File(_images.first.path),
                        leadingCount: _images.length,
                        controller: _caption,
                        onPickImage: busy ? null : _pickImages,
                        enabled: !busy,
                        captionLimit: _captionLimit,
                      ),
                      if (_images.isNotEmpty) ...[
                        const SizedBox(height: CielSpacing.md),
                        _ThumbStrip(
                          images: _images,
                          onRemove: busy ? null : _removeAt,
                          onAddMore: busy ? null : _pickImages,
                        ),
                      ],
                      const SizedBox(height: CielSpacing.lg),
                      const CielComposeRow(
                        icon: Icons.location_on_outlined,
                        label: 'Add location',
                        enabled: false,
                      ),
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
                    label: 'Share',
                    isLoading: busy,
                    onPressed: canSubmit ? _submit : null,
                  ),
                ),
              ],
            ),
          ),
          if (busy || upload is CreateUploadFailed)
            Positioned.fill(
              child: CreateUploadOverlayHost(
                state: upload,
                onRetry: _submit,
                onDismiss: () =>
                    ref.read(createPostControllerProvider.notifier).reset(),
              ),
            ),
        ],
      ),
    );
  }
}

class _CaptionRow extends StatelessWidget {
  const _CaptionRow({
    required this.leadingFile,
    required this.leadingCount,
    required this.controller,
    required this.onPickImage,
    required this.enabled,
    required this.captionLimit,
  });

  final File? leadingFile;
  final int leadingCount;
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
            file: leadingFile,
            placeholderLabel: leadingFile == null ? 'Choose' : null,
            onTap: onPickImage,
            badgeText: leadingCount > 1 ? '×$leadingCount' : null,
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
                  maxLines: 8,
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

class _ThumbStrip extends StatelessWidget {
  const _ThumbStrip({
    required this.images,
    required this.onRemove,
    required this.onAddMore,
  });

  final List<XFile> images;
  final void Function(int index)? onRemove;
  final VoidCallback? onAddMore;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: CielSpacing.sm),
        itemBuilder: (context, index) {
          if (index == images.length) {
            return SizedBox(
              width: 96,
              child: Material(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(CielRadii.lg),
                child: InkWell(
                  borderRadius: BorderRadius.circular(CielRadii.lg),
                  onTap: onAddMore,
                  child: Center(
                    child: Icon(
                      Icons.add,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            );
          }
          final file = images[index];
          return SizedBox(
            width: 96,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(CielRadii.lg),
                    child: Image.file(File(file.path), fit: BoxFit.cover),
                  ),
                ),
                if (onRemove != null)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Material(
                      color: scheme.scrim.withValues(alpha: 0.6),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => onRemove!(index),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
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
