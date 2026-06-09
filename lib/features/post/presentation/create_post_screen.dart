import 'dart:async';
import 'dart:io';

import 'package:ciel_mobile/core/media/image_editor.dart';
import 'package:ciel_mobile/features/auth/presentation/auth_notifier.dart';
import 'package:ciel_mobile/features/feed/presentation/feed_notifier.dart';
import 'package:ciel_mobile/features/post/presentation/create_post_notifier.dart';
import 'package:ciel_mobile/features/post/presentation/post_image_reorder.dart';
import 'package:ciel_mobile/features/uploads/create_upload_overlay_host.dart';
import 'package:ciel_mobile/features/uploads/create_upload_state.dart';
import 'package:ciel_mobile/features/uploads/draft/create_draft_store.dart';
import 'package:ciel_mobile/features/uploads/draft/create_drafts.dart';
import 'package:ciel_mobile/ui/ciel_compose_row.dart';
import 'package:ciel_mobile/ui/ciel_primary_button.dart';
import 'package:ciel_mobile/ui/ciel_source_chooser_sheet.dart';
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
    _caption.addListener(() {
      setState(() {});
      _scheduleDraftSave();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _offerDraftRestore());
  }

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  void _scheduleDraftSave() {
    final store = ref.read(createDraftStoreProvider);
    final draft = CreatePostDraft(
      imagePaths: _images.map((f) => f.path).toList(growable: false),
      caption: _caption.text,
      updatedAt: DateTime.now(),
    );
    unawaited(store.savePost(draft));
  }

  Future<void> _offerDraftRestore() async {
    if (!mounted) return;
    final store = ref.read(createDraftStoreProvider);
    final draft = store.loadPost();
    if (draft == null) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 8),
        content: Text(
          draft.imagePaths.isNotEmpty
              ? 'Restored your in-progress post.'
              : 'Restored your draft caption.',
        ),
        action: SnackBarAction(
          label: 'Discard',
          onPressed: () {
            unawaited(store.clearPost());
            if (mounted) {
              setState(() {
                _images.clear();
                _caption.text = '';
              });
            }
          },
        ),
      ),
    );
    setState(() {
      _images
        ..clear()
        ..addAll(draft.imagePaths.map(XFile.new));
      _caption.text = draft.caption;
    });
  }

  Future<void> _pickImages() async {
    final source = await showCielPhotoSourceSheet(context);
    if (source == null || !mounted) return;
    if (source == CielPhotoSource.camera) {
      final file = await CielImageEditor.pickAndCrop(
        context: context,
        preset: CielCropPreset.square,
        source: ImageSource.camera,
      );
      if (file != null && mounted) {
        setState(() {
          _images
            ..clear()
            ..add(file);
          _formError = null;
        });
        _scheduleDraftSave();
      }
      return;
    }
    final list = await ImagePicker().pickMultiImage();
    if (list.isNotEmpty && mounted) {
      setState(() {
        _images
          ..clear()
          ..addAll(list);
        _formError = null;
      });
      _scheduleDraftSave();
    }
  }

  Future<void> _editAt(int index) async {
    final src = _images[index];
    final cropped = await CielImageEditor.crop(
      context: context,
      sourcePath: src.path,
      preset: CielCropPreset.square,
    );
    if (cropped != null && mounted) {
      setState(() => _images[index] = cropped);
      _scheduleDraftSave();
    }
  }

  void _removeAt(int index) {
    setState(() => _images.removeAt(index));
    _scheduleDraftSave();
  }

  void _reorder(int oldIndex, int newIndex) {
    final reordered = applyReorder(_images, oldIndex, newIndex);
    if (identical(reordered, _images)) return;
    setState(() {
      _images
        ..clear()
        ..addAll(reordered);
    });
    _scheduleDraftSave();
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
    await ref.read(createDraftStoreProvider).clearPost();
    if (!mounted) return;
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
                          onEdit: busy ? null : _editAt,
                          onReorder: busy ? null : _reorder,
                          onAddMore: busy ? null : _pickImages,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: CielSpacing.xs),
                          child: Text(
                            'Long-press a photo to reorder · tap to crop',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
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
    required this.onEdit,
    required this.onReorder,
    required this.onAddMore,
  });

  final List<XFile> images;
  final void Function(int index)? onRemove;
  final void Function(int index)? onEdit;
  final void Function(int oldIndex, int newIndex)? onReorder;
  final VoidCallback? onAddMore;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 96,
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        buildDefaultDragHandles: false,
        itemCount: images.length + 1,
        proxyDecorator: (child, _, _) => Material(
          color: Colors.transparent,
          elevation: 8,
          borderRadius: BorderRadius.circular(CielRadii.lg),
          child: child,
        ),
        onReorder: (oldIndex, newIndex) =>
            onReorder?.call(oldIndex, newIndex),
        itemBuilder: (context, index) {
          if (index == images.length) {
            return Padding(
              key: const ValueKey('__add_more__'),
              padding: const EdgeInsets.only(right: CielSpacing.sm),
              child: SizedBox(
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
              ),
            );
          }
          final file = images[index];
          return Padding(
            key: ValueKey('thumb_${file.path}'),
            padding: const EdgeInsets.only(right: CielSpacing.sm),
            child: ReorderableDelayedDragStartListener(
              index: index,
              child: SizedBox(
                width: 96,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(CielRadii.lg),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: onEdit == null ? null : () => onEdit!(index),
                          child: Image.file(File(file.path), fit: BoxFit.cover),
                        ),
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
              ),
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
