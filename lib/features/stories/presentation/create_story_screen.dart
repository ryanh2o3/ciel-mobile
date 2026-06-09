import 'dart:async';
import 'dart:io';

import 'package:ciel_mobile/core/media/image_editor.dart';
import 'package:ciel_mobile/domain/entities/story.dart';
import 'package:ciel_mobile/features/feed/presentation/feed_notifier.dart';
import 'package:ciel_mobile/features/stories/presentation/create_story_notifier.dart';
import 'package:ciel_mobile/features/stories/presentation/story_audience_options.dart';
import 'package:ciel_mobile/features/uploads/create_upload_overlay_host.dart';
import 'package:ciel_mobile/features/uploads/create_upload_state.dart';
import 'package:ciel_mobile/features/uploads/draft/create_draft_store.dart';
import 'package:ciel_mobile/features/uploads/draft/create_drafts.dart';
import 'package:ciel_mobile/ui/ciel_audience_picker_sheet.dart';
import 'package:ciel_mobile/ui/ciel_primary_button.dart';
import 'package:ciel_mobile/ui/ciel_source_chooser_sheet.dart';
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
  final _captionFocus = FocusNode();
  XFile? _image;
  StoryVisibility _visibility = StoryVisibility.public;

  @override
  void initState() {
    super.initState();
    _caption.addListener(() {
      if (mounted) setState(() {});
      _scheduleDraftSave();
    });
    _captionFocus.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _offerDraftRestore());
  }

  @override
  void dispose() {
    _caption.dispose();
    _captionFocus.dispose();
    super.dispose();
  }

  void _scheduleDraftSave() {
    // Save synchronously on each change. SharedPreferences writes are
    // buffered by the platform, so this is cheap enough not to debounce.
    final store = ref.read(createDraftStoreProvider);
    final draft = CreateStoryDraft(
      imagePath: _image?.path,
      caption: _caption.text,
      visibility: _visibility,
      updatedAt: DateTime.now(),
    );
    unawaited(store.saveStory(draft));
  }

  Future<void> _offerDraftRestore() async {
    if (!mounted) return;
    final store = ref.read(createDraftStoreProvider);
    final draft = store.loadStory();
    if (draft == null) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 8),
        content: Text(
          draft.imagePath != null
              ? 'Restored your in-progress story.'
              : 'Restored your draft caption.',
        ),
        action: SnackBarAction(
          label: 'Discard',
          onPressed: () {
            unawaited(store.clearStory());
            if (mounted) {
              setState(() {
                _image = null;
                _caption.text = '';
                _visibility = StoryVisibility.public;
              });
            }
          },
        ),
      ),
    );
    setState(() {
      _image = draft.imagePath == null ? null : XFile(draft.imagePath!);
      _caption.text = draft.caption;
      _visibility = draft.visibility;
    });
  }

  Future<void> _pickImage() async {
    final source = await showCielPhotoSourceSheet(context);
    if (source == null || !mounted) return;
    final file = await CielImageEditor.pickAndCrop(
      context: context,
      preset: CielCropPreset.story,
      source: source == CielPhotoSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
    );
    if (file != null && mounted) {
      setState(() => _image = file);
      _scheduleDraftSave();
    }
  }

  Future<void> _editImage() async {
    final current = _image;
    if (current == null) return;
    final cropped = await CielImageEditor.crop(
      context: context,
      sourcePath: current.path,
      preset: CielCropPreset.story,
    );
    if (cropped != null && mounted) {
      setState(() => _image = cropped);
      _scheduleDraftSave();
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
      _scheduleDraftSave();
    }
  }

  void _focusCaption() {
    _captionFocus.requestFocus();
  }

  Future<void> _submit() async {
    final file = _image;
    if (file == null) return;
    FocusScope.of(context).unfocus();
    final caption = _caption.text.trim();
    final ok = await ref
        .read(createStoryControllerProvider.notifier)
        .submit(
          image: file,
          caption: caption.isEmpty ? null : caption,
          visibility: _visibility,
        );
    if (!ok || !mounted) return;
    await ref.read(createDraftStoreProvider).clearStory();
    if (!mounted) return;
    ref.invalidate(feedNotifierProvider);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final upload = ref.watch(createStoryControllerProvider);
    final busy = upload.isInFlight;
    final hasImage = _image != null;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final editing = _captionFocus.hasFocus;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. Image (or empty state) — full-bleed.
          Positioned.fill(
            child: hasImage
                ? _ImageLayer(file: File(_image!.path))
                : const _EmptyCanvas(),
          ),

          // 2. Caption overlay — sits on top of the photo.
          if (hasImage)
            _CaptionLayer(
              controller: _caption,
              focusNode: _captionFocus,
              editing: editing,
              keyboardInset: keyboardInset,
              captionLimit: _captionLimit,
              onTapPlaceholder: busy ? null : _focusCaption,
            ),

          // 3. Top + bottom scrims (only when an image is present, for
          // chrome legibility against bright photos).
          if (hasImage) ...[
            const _TopScrim(),
            const _BottomScrim(),
          ],

          // 4. Chrome — close, text tool, audience chip, share CTA.
          SafeArea(
            child: Column(
              children: [
                _TopBar(
                  busy: busy,
                  onClose: () => context.pop(),
                  onAddText: hasImage && !busy ? _focusCaption : null,
                  onReplace: hasImage && !busy ? _pickImage : null,
                  onCrop: hasImage && !busy ? _editImage : null,
                ),
                const Spacer(),
                if (hasImage && !editing)
                  _BottomBar(
                    audienceLabel: storyVisibilityLabel(_visibility),
                    onTapAudience: busy ? null : _pickAudience,
                    onShare: busy ? null : _submit,
                    busy: busy,
                  )
                else if (!hasImage)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      CielSpacing.md,
                      CielSpacing.md,
                      CielSpacing.md,
                      CielSpacing.lg,
                    ),
                    child: CielPrimaryButton(
                      label: 'Choose photo',
                      onPressed: busy ? null : _pickImage,
                    ),
                  ),
              ],
            ),
          ),

          // 5. Upload overlay (Phase 2 plumbing).
          if (busy || upload is CreateUploadFailed)
            Positioned.fill(
              child: CreateUploadOverlayHost(
                state: upload,
                onRetry: _submit,
                onDismiss: () =>
                    ref.read(createStoryControllerProvider.notifier).reset(),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyCanvas extends StatelessWidget {
  const _EmptyCanvas();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 56,
              color: Colors.white.withValues(alpha: 0.6),
            ),
            const SizedBox(height: CielSpacing.md),
            Text(
              'New story',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pick a photo to begin.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageLayer extends StatelessWidget {
  const _ImageLayer({required this.file});

  final File file;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Image.file(file, fit: BoxFit.cover),
    );
  }
}

class _TopScrim extends StatelessWidget {
  const _TopScrim();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.55),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomScrim extends StatelessWidget {
  const _BottomScrim();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: 220,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.7),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.busy,
    required this.onClose,
    required this.onAddText,
    required this.onReplace,
    required this.onCrop,
  });

  final bool busy;
  final VoidCallback onClose;
  final VoidCallback? onAddText;
  final VoidCallback? onReplace;
  final VoidCallback? onCrop;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CielSpacing.sm,
        vertical: CielSpacing.xs,
      ),
      child: Row(
        children: [
          _ChromeButton(
            icon: Icons.close,
            tooltip: 'Cancel',
            onPressed: busy ? null : onClose,
          ),
          const Spacer(),
          if (onCrop != null)
            _ChromeButton(
              icon: Icons.crop,
              tooltip: 'Crop',
              onPressed: onCrop,
            ),
          if (onReplace != null)
            _ChromeButton(
              icon: Icons.photo_library_outlined,
              tooltip: 'Replace photo',
              onPressed: onReplace,
            ),
          if (onAddText != null)
            _ChromeButton(
              icon: Icons.text_fields,
              tooltip: 'Add text',
              onPressed: onAddText,
            ),
        ],
      ),
    );
  }
}

class _ChromeButton extends StatelessWidget {
  const _ChromeButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.black.withValues(alpha: 0.35),
        shape: const CircleBorder(),
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          icon: Icon(icon),
          color: Colors.white,
          disabledColor: Colors.white.withValues(alpha: 0.4),
          padding: const EdgeInsets.all(10),
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          visualDensity: VisualDensity.compact,
          // Force a sensible splash radius for the round chrome button.
          splashRadius: 22,
          // Keep transparency obvious on press
          highlightColor: enabled
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.transparent,
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.audienceLabel,
    required this.onTapAudience,
    required this.onShare,
    required this.busy,
  });

  final String audienceLabel;
  final VoidCallback? onTapAudience;
  final VoidCallback? onShare;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CielSpacing.md,
        CielSpacing.sm,
        CielSpacing.md,
        CielSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _AudienceChip(
              label: audienceLabel,
              onTap: onTapAudience,
            ),
          ),
          const SizedBox(height: CielSpacing.md),
          CielPrimaryButton(
            label: 'Share story',
            isLoading: busy,
            onPressed: onShare,
          ),
        ],
      ),
    );
  }
}

class _AudienceChip extends StatelessWidget {
  const _AudienceChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: CielSpacing.md,
            vertical: 8,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.visibility_outlined,
                size: 18,
                color: Colors.white,
              ),
              const SizedBox(width: CielSpacing.xs),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.arrow_drop_down,
                size: 20,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CaptionLayer extends StatelessWidget {
  const _CaptionLayer({
    required this.controller,
    required this.focusNode,
    required this.editing,
    required this.keyboardInset,
    required this.captionLimit,
    required this.onTapPlaceholder,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool editing;
  final double keyboardInset;
  final int captionLimit;
  final VoidCallback? onTapPlaceholder;

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.trim().isNotEmpty;
    final mediaHeight = MediaQuery.sizeOf(context).height;
    // Anchor at the lower-third when no keyboard; lift to just above the
    // keyboard when editing.
    final bottomAnchor = editing
        ? keyboardInset + CielSpacing.lg
        : mediaHeight * 0.28;
    return Positioned(
      left: CielSpacing.md,
      right: CielSpacing.md,
      bottom: bottomAnchor,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 160),
        child: editing
            ? _CaptionEditor(
                key: const ValueKey('editor'),
                controller: controller,
                focusNode: focusNode,
                captionLimit: captionLimit,
              )
            : _CaptionPill(
                key: const ValueKey('pill'),
                text: hasText ? controller.text : 'Tap to add text',
                placeholder: !hasText,
                onTap: onTapPlaceholder,
              ),
      ),
    );
  }
}

class _CaptionPill extends StatelessWidget {
  const _CaptionPill({
    required this.text,
    required this.placeholder,
    required this.onTap,
    super.key,
  });

  final String text;
  final bool placeholder;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      color: placeholder ? Colors.white.withValues(alpha: 0.85) : Colors.white,
      fontWeight: FontWeight.w600,
    );
    return Center(
      child: Material(
        color: Colors.black.withValues(alpha: placeholder ? 0.35 : 0.55),
        borderRadius: BorderRadius.circular(CielRadii.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(CielRadii.lg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: CielSpacing.md,
              vertical: CielSpacing.sm,
            ),
            child: Text(
              text,
              style: textStyle,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}

class _CaptionEditor extends StatelessWidget {
  const _CaptionEditor({
    required this.controller,
    required this.focusNode,
    required this.captionLimit,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final int captionLimit;

  @override
  Widget build(BuildContext context) {
    final length = controller.text.characters.length;
    final warn = length > (captionLimit * 0.85).round();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CielSpacing.md,
        vertical: CielSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(CielRadii.lg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: true,
            maxLines: 4,
            minLines: 1,
            maxLength: captionLimit,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => focusNode.unfocus(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            cursorColor: Colors.white,
            decoration: InputDecoration(
              hintText: 'Write a caption…',
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              counterText: '',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$length / $captionLimit',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: warn ? Colors.amberAccent : Colors.white.withValues(
                alpha: 0.7,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
