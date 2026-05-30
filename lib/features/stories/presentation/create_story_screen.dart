import 'dart:io';

import 'package:ciel_mobile/domain/entities/story.dart';
import 'package:ciel_mobile/features/feed/presentation/feed_notifier.dart';
import 'package:ciel_mobile/features/stories/presentation/create_story_notifier.dart';
import 'package:ciel_mobile/features/stories/presentation/story_audience_options.dart';
import 'package:ciel_mobile/features/uploads/create_upload_overlay_host.dart';
import 'package:ciel_mobile/features/uploads/create_upload_state.dart';
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

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file != null && mounted) {
      setState(() {
        _image = file;
        _formError = null;
      });
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
      setState(() => _formError = 'Choose a photo to share.');
      return;
    }
    setState(() => _formError = null);
    final caption = _caption.text.trim();
    final ok = await ref
        .read(createStoryControllerProvider.notifier)
        .submit(
          image: file,
          caption: caption.isEmpty ? null : caption,
          visibility: _visibility,
        );
    if (!ok || !mounted) return;
    ref.invalidate(feedNotifierProvider);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final upload = ref.watch(createStoryControllerProvider);
    final busy = upload.isInFlight;
    final canSubmit = !busy && _image != null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: busy ? null : () => context.pop(),
          tooltip: 'Cancel',
        ),
        title: const Text('New story'),
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
                        file: _image == null ? null : File(_image!.path),
                        controller: _caption,
                        onPickImage: busy ? null : _pickImage,
                        enabled: !busy,
                        captionLimit: _captionLimit,
                      ),
                      const SizedBox(height: CielSpacing.lg),
                      CielComposeRow(
                        icon: Icons.visibility_outlined,
                        label: 'Audience',
                        trailing: storyVisibilityLabel(_visibility),
                        enabled: !busy,
                        onTap: _pickAudience,
                      ),
                      const SizedBox(height: CielSpacing.sm),
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
                    label: 'Share story',
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
                    ref.read(createStoryControllerProvider.notifier).reset(),
              ),
            ),
        ],
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
