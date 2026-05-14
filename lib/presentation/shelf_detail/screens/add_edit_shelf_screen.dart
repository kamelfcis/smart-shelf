import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/validators.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../dashboard/providers/dashboard_provider.dart';

class AddEditShelfScreen extends ConsumerStatefulWidget {
  const AddEditShelfScreen({super.key, this.shelfId});
  final String? shelfId;

  @override
  ConsumerState<AddEditShelfScreen> createState() =>
      _AddEditShelfScreenState();
}

class _AddEditShelfScreenState extends ConsumerState<AddEditShelfScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _sensorCtrl = TextEditingController();

  bool get _isEdit => widget.shelfId != null;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _sensorCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final notifier = ref.read(shelfFormProvider.notifier);
    final ok = await notifier.createShelf(
      name: _nameCtrl.text.trim(),
      location: _locationCtrl.text.trim().isEmpty
          ? null
          : _locationCtrl.text.trim(),
      sensorId: _sensorCtrl.text.trim().isEmpty
          ? null
          : _sensorCtrl.text.trim(),
    );
    if (ok && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shelfFormProvider);

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
        bottom: MediaQuery.of(context).viewInsets.bottom +
            AppDimensions.xl,
      ),
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
              _isEdit ? 'Edit Shelf' : 'Add New Shelf',
              style: AppTypography.headingLarge,
            )
                .animate()
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.3),

            const SizedBox(height: AppDimensions.xl),

            AppTextField(
              controller: _nameCtrl,
              label: 'Shelf Name',
              hint: 'e.g. Kitchen Pantry',
              prefixIcon: Icons.shelves,
              textInputAction: TextInputAction.next,
              validator: (v) => AppValidators.required(v, label: 'Shelf name'),
            ).animate(delay: 80.ms).fadeIn().slideY(begin: 0.2),

            const SizedBox(height: AppDimensions.md),

            AppTextField(
              controller: _locationCtrl,
              label: 'Location (optional)',
              hint: 'e.g. Aisle 3, Row B',
              prefixIcon: Icons.location_on_outlined,
              textInputAction: TextInputAction.next,
            ).animate(delay: 140.ms).fadeIn().slideY(begin: 0.2),

            const SizedBox(height: AppDimensions.md),

            AppTextField(
              controller: _sensorCtrl,
              label: 'Sensor ID (optional)',
              hint: 'e.g. shelf-A1-esp8266',
              prefixIcon: Icons.memory_rounded,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2),

            const SizedBox(height: AppDimensions.xl),

            PrimaryButton(
              label: _isEdit ? 'Save Changes' : 'Add Shelf',
              onPressed: state.isLoading ? null : _submit,
              isLoading: state.isLoading,
            ).animate(delay: 260.ms).fadeIn().slideY(begin: 0.2),
          ],
        ),
      ),
    );
  }
}
