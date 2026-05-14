import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/validators.dart';
import '../../auth/providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../../data/models/item_model.dart';
import '../providers/shelf_detail_provider.dart';

class AddEditItemScreen extends ConsumerStatefulWidget {
  const AddEditItemScreen({super.key, required this.shelfId, this.itemId});
  final String shelfId;
  final String? itemId;

  @override
  ConsumerState<AddEditItemScreen> createState() =>
      _AddEditItemScreenState();
}

class _AddEditItemScreenState extends ConsumerState<AddEditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _unitWeightCtrl = TextEditingController(text: '100');
  final _tareWeightCtrl = TextEditingController(text: '0');
  final _thresholdCtrl = TextEditingController(text: '2');
  final _slotCtrl = TextEditingController();

  XFile? _pickedImage;        // newly picked local file
  String? _existingImageUrl;  // current URL when editing
  bool _prefilled = false;    // guard so we only pre-fill once

  bool get _isEdit => widget.itemId != null;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _unitWeightCtrl.dispose();
    _tareWeightCtrl.dispose();
    _thresholdCtrl.dispose();
    _slotCtrl.dispose();
    super.dispose();
  }

  /// Populate form fields from the loaded item — called once.
  void _prefill(ItemModel item) {
    if (_prefilled) return;
    _prefilled = true;
    _nameCtrl.text = item.name;
    _unitWeightCtrl.text = item.unitWeightG.toStringAsFixed(
        item.unitWeightG % 1 == 0 ? 0 : 1);
    _tareWeightCtrl.text = item.tareWeightG.toStringAsFixed(
        item.tareWeightG % 1 == 0 ? 0 : 1);
    _thresholdCtrl.text = item.minThreshold.toString();
    if (item.slotNumber != null) {
      _slotCtrl.text = item.slotNumber.toString();
    }
    if (item.imageUrl != null) {
      _existingImageUrl = item.imageUrl;
    }
  }

  Future<void> _pickImage() async {
    final storage = ref.read(storageRepositoryProvider);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ImageSourceSheet(),
    );
    if (source == null || !mounted) return;

    final file = source == ImageSource.gallery
        ? await storage.pickFromGallery()
        : await storage.pickFromCamera();

    if (file != null && mounted) {
      setState(() => _pickedImage = file);
    }
  }

  Future<void> _submit(ItemModel? existingItem) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final notifier = ref.read(itemFormProvider.notifier);

    bool ok;
    if (_isEdit && existingItem != null) {
      // Build updated item preserving fields not on the form (weight, qty…)
      final updated = existingItem.copyWith(
        name: _nameCtrl.text.trim(),
        unitWeightG: double.tryParse(_unitWeightCtrl.text) ?? existingItem.unitWeightG,
        tareWeightG: double.tryParse(_tareWeightCtrl.text) ?? existingItem.tareWeightG,
        minThreshold: int.tryParse(_thresholdCtrl.text) ?? existingItem.minThreshold,
        slotNumber: _slotCtrl.text.isEmpty
            ? existingItem.slotNumber
            : int.tryParse(_slotCtrl.text),
        // keep existing URL unless user picked new image or cleared it
        imageUrl: _pickedImage != null ? null : _existingImageUrl,
      );
      ok = await notifier.updateItem(updated, imageFile: _pickedImage);
    } else {
      ok = await notifier.createItem(
        shelfId: widget.shelfId,
        name: _nameCtrl.text.trim(),
        unitWeightG: double.parse(_unitWeightCtrl.text),
        tareWeightG: double.parse(_tareWeightCtrl.text),
        minThreshold: int.parse(_thresholdCtrl.text),
        slotNumber:
            _slotCtrl.text.isEmpty ? null : int.tryParse(_slotCtrl.text),
        imageFile: _pickedImage,
      );
    }
    if (ok && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(itemFormProvider);

    // When editing, watch the item so we can pre-fill and show its data.
    ItemModel? existingItem;
    if (_isEdit) {
      final itemAsync = ref.watch(singleItemProvider(widget.itemId!));
      itemAsync.whenData((item) {
        if (item != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _prefill(item));
          });
          existingItem = item;
        }
      });
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXl),
        ),
      ),
      padding: EdgeInsets.only(
        left: AppDimensions.screenPadding,
        right: AppDimensions.screenPadding,
        top: AppDimensions.lg,
        bottom:
            MediaQuery.of(context).viewInsets.bottom + AppDimensions.xl,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusFull),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.lg),

              Text(
                _isEdit ? 'Edit Item' : 'Add Item',
                style: AppTypography.headingLarge,
              ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.3),

              const SizedBox(height: AppDimensions.xl),

              // ── Image picker ────────────────────────────────────────
              _ImagePickerWidget(
                pickedFile: _pickedImage,
                existingUrl: _existingImageUrl,
                onTap: _pickImage,
                onRemove: () => setState(() {
                  _pickedImage = null;
                  _existingImageUrl = null;
                }),
              ).animate(delay: 40.ms).fadeIn().slideY(begin: 0.2),

              const SizedBox(height: AppDimensions.lg),

              // ── Name ────────────────────────────────────────────────
              AppTextField(
                controller: _nameCtrl,
                label: 'Item Name',
                hint: 'e.g. Milk Cartons',
                prefixIcon: Icons.inventory_2_outlined,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    AppValidators.required(v, label: 'Item name'),
              ).animate(delay: 80.ms).fadeIn().slideY(begin: 0.2),

              const SizedBox(height: AppDimensions.md),

              // ── Weights ─────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _unitWeightCtrl,
                      label: 'Unit Weight (g)',
                      hint: '100',
                      prefixIcon: Icons.scale_outlined,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      textInputAction: TextInputAction.next,
                      validator: AppValidators.positiveNumber,
                    ).animate(delay: 120.ms).fadeIn().slideY(begin: 0.2),
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Expanded(
                    child: AppTextField(
                      controller: _tareWeightCtrl,
                      label: 'Tare Weight (g)',
                      hint: '0',
                      prefixIcon: Icons.balance_outlined,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      textInputAction: TextInputAction.next,
                      validator: AppValidators.positiveNumber,
                    ).animate(delay: 160.ms).fadeIn().slideY(begin: 0.2),
                  ),
                ],
              ),

              const SizedBox(height: AppDimensions.md),

              // ── Threshold + Slot ────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _thresholdCtrl,
                      label: 'Min Threshold',
                      hint: '2',
                      prefixIcon: Icons.warning_amber_outlined,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      validator: AppValidators.positiveInt,
                    ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2),
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Expanded(
                    child: AppTextField(
                      controller: _slotCtrl,
                      label: 'Slot # (optional)',
                      hint: '1',
                      prefixIcon: Icons.grid_view_rounded,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(existingItem),
                    ).animate(delay: 240.ms).fadeIn().slideY(begin: 0.2),
                  ),
                ],
              ),

              if (state.error != null) ...[
                const SizedBox(height: AppDimensions.md),
                Container(
                  padding: const EdgeInsets.all(AppDimensions.md),
                  decoration: BoxDecoration(
                    color: AppColors.error.withAlpha(20),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMd),
                    border:
                        Border.all(color: AppColors.error.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppColors.error, size: 18),
                      const SizedBox(width: AppDimensions.sm),
                      Expanded(
                        child: Text(
                          state.error!,
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppDimensions.xl),

              PrimaryButton(
                label: _isEdit ? 'Save Changes' : 'Add Item',
                onPressed: state.isLoading
                    ? null
                    : () => _submit(existingItem),
                isLoading: state.isLoading,
              ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.2),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Image picker widget
// ─────────────────────────────────────────────────────────────────────────────

class _ImagePickerWidget extends StatelessWidget {
  const _ImagePickerWidget({
    required this.pickedFile,
    required this.existingUrl,
    required this.onTap,
    required this.onRemove,
  });

  final XFile? pickedFile;
  final String? existingUrl;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  bool get _hasImage => pickedFile != null || existingUrl != null;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ITEM PHOTO (OPTIONAL)',
          style: AppTypography.labelSmall.copyWith(letterSpacing: 1.4),
        ),
        const SizedBox(height: AppDimensions.sm),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(
                color: _hasImage
                    ? AppColors.primary.withAlpha(80)
                    : AppColors.border,
                width: _hasImage ? 1.5 : 1,
              ),
            ),
            child: _hasImage ? _Preview(
              pickedFile: pickedFile,
              existingUrl: existingUrl,
              onRemove: onRemove,
            ) : _Placeholder(),
          ),
        ),
      ],
    );
  }
}

class _Placeholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          child: const Icon(
            Icons.add_photo_alternate_outlined,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(height: AppDimensions.sm),
        Text('Tap to add a photo', style: AppTypography.bodySmall),
        Text(
          'Gallery or Camera',
          style: AppTypography.caption,
        ),
      ],
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({
    required this.pickedFile,
    required this.existingUrl,
    required this.onRemove,
  });
  final XFile? pickedFile;
  final String? existingUrl;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd - 1),
          child: pickedFile != null
              ? Image.file(
                  File(pickedFile!.path),
                  fit: BoxFit.cover,
                )
              : Image.network(
                  existingUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.textHint,
                    size: 40,
                  ),
                ),
        ),
        // Remove button
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(160),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
        // Edit overlay hint
        Positioned(
          bottom: 6,
          right: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(140),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.edit_rounded,
                    color: Colors.white, size: 12),
                const SizedBox(width: 4),
                Text(
                  'Change',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Image source picker sheet (reusable)
// ─────────────────────────────────────────────────────────────────────────────

class _ImageSourceSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.xl,
        AppDimensions.lg,
        AppDimensions.xl,
        AppDimensions.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusFull),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.lg),
          Text('Add Photo', style: AppTypography.headingSmall),
          const SizedBox(height: AppDimensions.lg),
          _SourceTile(
            icon: Icons.photo_library_outlined,
            label: 'Choose from Gallery',
            onTap: () =>
                Navigator.of(context).pop(ImageSource.gallery),
          ),
          const SizedBox(height: AppDimensions.sm),
          _SourceTile(
            icon: Icons.camera_alt_outlined,
            label: 'Take a Photo',
            onTap: () =>
                Navigator.of(context).pop(ImageSource.camera),
          ),
        ],
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.md,
          vertical: AppDimensions.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: AppDimensions.md),
            Text(label, style: AppTypography.labelLarge),
            const Spacer(),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textHint,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
