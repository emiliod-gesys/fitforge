import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/social_feed.dart';
import '../../core/theme/app_accent.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/feed_personal_record.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/profile.dart';
import '../../providers/app_providers.dart';

class FeedComposeSheet extends ConsumerStatefulWidget {
  const FeedComposeSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => const FeedComposeSheet(),
    );
  }

  @override
  ConsumerState<FeedComposeSheet> createState() => _FeedComposeSheetState();
}

class _FeedComposeSheetState extends ConsumerState<FeedComposeSheet> {
  final _controller = TextEditingController();
  final _picker = ImagePicker();
  XFile? _photo;
  PersonalRecord? _selectedPr;
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _remaining => SocialFeed.maxPostLength - _controller.text.length;

  bool get _canPost =>
      !_submitting &&
      (_controller.text.trim().isNotEmpty || _photo != null || _selectedPr != null);

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    setState(() => _photo = picked);
  }

  Future<void> _pickPersonalRecord() async {
    final l10n = context.l10n;
    final unitSystem = ref.read(unitSystemProvider);

    List<PersonalRecord> records;
    try {
      records = await ref.read(personalRecordsProvider.future);
    } catch (_) {
      records = const [];
    }

    final attachable = ref.read(socialServiceProvider).personalRecordsForFeedAttach(records);

    if (!mounted) return;
    if (attachable.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.feedComposeNoPrs)),
      );
      return;
    }

    final selected = await showModalBottomSheet<PersonalRecord>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                l10n.feedComposeAttachPr,
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: attachable.length,
                itemBuilder: (context, index) {
                  final pr = attachable[index];
                  final value = FeedPersonalRecord.formatValue(pr, unitSystem);
                  return ListTile(
                    leading: Icon(Icons.emoji_events, color: ctx.accentColor),
                    title: Text(pr.exerciseName),
                    subtitle: Text(value),
                    onTap: () => Navigator.pop(ctx, pr),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (selected != null && mounted) {
      setState(() => _selectedPr = selected);
    }
  }

  Future<void> _submit() async {
    if (!_canPost) return;
    final l10n = context.l10n;
    setState(() => _submitting = true);

    try {
      File? imageFile;
      if (_photo != null) imageFile = File(_photo!.path);

      await ref.read(socialServiceProvider).createUserPost(
            text: _controller.text,
            imageFile: imageFile,
            personalRecord: _selectedPr,
          );

      ref.invalidate(socialFeedProvider);
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.feedComposePublished)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final message = switch ('$e') {
        'StateError: text_too_long' => l10n.feedComposeTextTooLong,
        'StateError: post_empty' => l10n.feedComposeEmpty,
        'StateError: image_too_large' => l10n.feedComposeImageTooLarge,
        _ => l10n.feedComposeFailed('$e'),
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final unitSystem = ref.watch(unitSystemProvider);
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.92 - viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.feedComposeTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: _submitting ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                maxLength: SocialFeed.maxPostLength,
                maxLines: 4,
                minLines: 2,
                enabled: !_submitting,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: l10n.feedComposeHint,
                  counterText: '$_remaining',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              if (_photo != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 160),
                    child: Stack(
                      children: [
                        Image.file(
                          File(_photo!.path),
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton.filled(
                            style: IconButton.styleFrom(backgroundColor: Colors.black54),
                            onPressed: _submitting ? null : () => setState(() => _photo = null),
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (_selectedPr != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.emoji_events, color: context.accentColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedPr!.exerciseName,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              FeedPersonalRecord.formatValue(_selectedPr!, unitSystem),
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _submitting ? null : () => setState(() => _selectedPr = null),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton(
                    tooltip: l10n.feedComposeAddPhoto,
                    onPressed: _submitting
                        ? null
                        : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_outlined),
                  ),
                  IconButton(
                    tooltip: l10n.feedComposeTakePhoto,
                    onPressed: _submitting
                        ? null
                        : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                  ),
                  IconButton(
                    tooltip: l10n.feedComposeAttachPr,
                    onPressed: _submitting ? null : _pickPersonalRecord,
                    icon: const Icon(Icons.emoji_events_outlined),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _canPost ? _submit : null,
                    child: _submitting
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          )
                        : Text(l10n.feedComposePublish),
                  ),
                ],
              ),
              Text(
                l10n.feedComposeCompressionHint,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
