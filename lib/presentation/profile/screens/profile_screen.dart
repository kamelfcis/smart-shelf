import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/validators.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../../widgets/app_bar_widget.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/app_button.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Profile update state + notifier
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileUpdateState {
  const _ProfileUpdateState({
    this.isLoading = false,
    this.error,
    this.success = false,
  });
  final bool isLoading;
  final String? error;
  final bool success;
}

class _ProfileUpdateNotifier extends StateNotifier<_ProfileUpdateState> {
  _ProfileUpdateNotifier(this._repo) : super(const _ProfileUpdateState());
  final AuthRepository _repo;

  Future<bool> updateName(String name) async {
    if (!mounted) return false;
    state = const _ProfileUpdateState(isLoading: true);
    try {
      await _repo.updateProfile(fullName: name);
      if (!mounted) return true;
      state = const _ProfileUpdateState(success: true);
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = _ProfileUpdateState(error: e.toString());
      return false;
    }
  }

  Future<bool> updatePassword(String password) async {
    if (!mounted) return false;
    state = const _ProfileUpdateState(isLoading: true);
    try {
      await _repo.updatePassword(newPassword: password);
      if (!mounted) return true;
      state = const _ProfileUpdateState(success: true);
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = _ProfileUpdateState(error: e.toString());
      return false;
    }
  }

  void reset() => state = const _ProfileUpdateState();
}

final _profileUpdateProvider =
    StateNotifierProvider.autoDispose<_ProfileUpdateNotifier, _ProfileUpdateState>(
  (ref) => _ProfileUpdateNotifier(ref.read(authRepositoryProvider)),
);

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _uploading = false;

  Future<void> _pickAndUploadAvatar() async {
    final storage = ref.read(storageRepositoryProvider);
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;

    // Let user choose source
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ImageSourceSheet(),
    );
    if (source == null || !mounted) return;

    final file = source == ImageSource.gallery
        ? await storage.pickFromGallery()
        : await storage.pickFromCamera();
    if (file == null || !mounted) return;

    setState(() => _uploading = true);
    try {
      final url = await storage.uploadAvatar(userId, file);
      await storage.saveAvatarUrl(userId, url);
      ref.invalidate(avatarUrlProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode != ThemeMode.light;
    final avatarUrl = ref.watch(avatarUrlProvider).valueOrNull;

    final name = user?.userMetadata?['full_name']?.toString() ?? 'User';
    final email = user?.email ?? '';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              SmartShelfAppBar(
                title: 'Profile',
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Edit profile',
                    onPressed: () =>
                        _showEditSheet(context, ref, name, email),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.screenPadding,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: AppDimensions.xl),

                      // ── Avatar ────────────────────────────────────────
                      Center(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: _uploading ? null : _pickAndUploadAvatar,
                              child: Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Container(
                                    width: 96,
                                    height: 96,
                                    decoration: BoxDecoration(
                                      gradient: avatarUrl == null
                                          ? AppColors.primaryGradient
                                          : null,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primaryGlow,
                                          blurRadius: 28,
                                          spreadRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: _uploading
                                          ? Container(
                                              color: AppColors.primary
                                                  .withAlpha(180),
                                              child:
                                                  const Center(
                                                child: SizedBox(
                                                  width: 28,
                                                  height: 28,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2.5,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : avatarUrl != null
                                              ? Image.network(
                                                  avatarUrl,
                                                  fit: BoxFit.cover,
                                                  width: 96,
                                                  height: 96,
                                                  errorBuilder: (_, __, ___) =>
                                                      _InitialsAvatar(
                                                          initials: initials),
                                                )
                                              : _InitialsAvatar(
                                                  initials: initials),
                                    ),
                                  ),
                                  // Camera badge
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.background,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_rounded,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                                .animate(key: const ValueKey('avatar'))
                                .scale(
                                  begin: const Offset(0.5, 0.5),
                                  duration: 500.ms,
                                  curve: Curves.elasticOut,
                                )
                                .fadeIn(duration: 400.ms),

                            const SizedBox(height: AppDimensions.md),

                            Text(name, style: AppTypography.headingLarge)
                                .animate(
                                    key: const ValueKey('profile-name'),
                                    delay: 150.ms)
                                .fadeIn()
                                .slideY(begin: 0.3),

                            Text(email, style: AppTypography.bodyMedium)
                                .animate(
                                    key: const ValueKey('profile-email'),
                                    delay: 220.ms)
                                .fadeIn()
                                .slideY(begin: 0.3),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppDimensions.xxl),

                      // ── Appearance ────────────────────────────────────
                      _SettingsSection(
                        title: 'Appearance',
                        children: [
                          _SettingsTile(
                            icon: isDark
                                ? Icons.dark_mode_outlined
                                : Icons.light_mode_outlined,
                            label: 'Dark Mode',
                            trailing: Switch(
                              value: isDark,
                              onChanged: (v) => ref
                                  .read(themeModeProvider.notifier)
                                  .setMode(
                                    v ? ThemeMode.dark : ThemeMode.light,
                                  ),
                              activeThumbColor: AppColors.primary,
                              activeTrackColor: AppColors.primaryGlow,
                            ),
                          ),
                        ],
                      )
                          .animate(
                              key: const ValueKey('section-appearance'),
                              delay: 300.ms)
                          .fadeIn()
                          .slideY(begin: 0.2),

                      const SizedBox(height: AppDimensions.md),

                      // ── Account ───────────────────────────────────────
                      _SettingsSection(
                        title: 'Account',
                        children: [
                          _TappableTile(
                            icon: Icons.person_outline_rounded,
                            label: 'Full Name',
                            value: name,
                            onTap: () =>
                                _showEditSheet(context, ref, name, email),
                          ),
                          _SettingsTile(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            trailing: Text(
                              email,
                              style: AppTypography.bodySmall,
                            ),
                          ),
                          _TappableTile(
                            icon: Icons.lock_outline_rounded,
                            label: 'Change Password',
                            value: '••••••••',
                            onTap: () => _showPasswordSheet(context, ref),
                          ),
                        ],
                      )
                          .animate(
                              key: const ValueKey('section-account'),
                              delay: 380.ms)
                          .fadeIn()
                          .slideY(begin: 0.2),

                      const SizedBox(height: AppDimensions.xl),

                      // ── Sign out ──────────────────────────────────────
                      GhostButton(
                        label: 'Sign Out',
                        color: AppColors.error,
                        icon: Icons.logout_rounded,
                        onPressed: () async {
                          await ref
                              .read(authRepositoryProvider)
                              .signOut();
                          if (context.mounted) {
                            context.go(AppRoutes.login);
                          }
                        },
                      )
                          .animate(
                              key: const ValueKey('btn-signout'),
                              delay: 460.ms)
                          .fadeIn()
                          .slideY(begin: 0.2),

                      const SizedBox(height: AppDimensions.xxl),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditSheet(
    BuildContext context,
    WidgetRef ref,
    String currentName,
    String email,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Material(
        color: Colors.transparent,
        child: ProviderScope(
          parent: ProviderScope.containerOf(context),
          child: _EditNameSheet(currentName: currentName, email: email),
        ),
      ),
    );
  }

  void _showPasswordSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Material(
        color: Colors.transparent,
        child: ProviderScope(
          parent: ProviderScope.containerOf(context),
          child: const _ChangePasswordSheet(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small helpers
// ─────────────────────────────────────────────────────────────────────────────

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.initials});
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: AppTypography.displayMedium.copyWith(
            color: Colors.white,
            fontSize: 38,
          ),
        ),
      ),
    );
  }
}

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
          Text('Change Photo', style: AppTypography.headingSmall),
          const SizedBox(height: AppDimensions.lg),
          _SourceTile(
            icon: Icons.photo_library_outlined,
            label: 'Choose from Gallery',
            onTap: () => Navigator.of(context).pop(ImageSource.gallery),
          ),
          const SizedBox(height: AppDimensions.sm),
          _SourceTile(
            icon: Icons.camera_alt_outlined,
            label: 'Take a Photo',
            onTap: () => Navigator.of(context).pop(ImageSource.camera),
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

// ─────────────────────────────────────────────────────────────────────────────
// Edit name bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _EditNameSheet extends ConsumerStatefulWidget {
  const _EditNameSheet({
    required this.currentName,
    required this.email,
  });
  final String currentName;
  final String email;

  @override
  ConsumerState<_EditNameSheet> createState() => _EditNameSheetState();
}

class _EditNameSheetState extends ConsumerState<_EditNameSheet> {
  late final TextEditingController _nameCtrl;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await ref
        .read(_profileUpdateProvider.notifier)
        .updateName(_nameCtrl.text);
    if (ok && mounted) {
      ref.invalidate(currentUserProvider);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_profileUpdateProvider);

    return _SheetShell(
      title: 'Edit Profile',
      icon: Icons.person_outline_rounded,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar preview
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGlow,
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _nameCtrl.text.isNotEmpty
                        ? _nameCtrl.text[0].toUpperCase()
                        : 'U',
                    style: AppTypography.headingLarge.copyWith(
                      color: Colors.white,
                      fontSize: 28,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppDimensions.xl),

            Text('FULL NAME', style: AppTypography.labelSmall.copyWith(letterSpacing: 1.5)),
            const SizedBox(height: AppDimensions.sm),
            TextFormField(
              controller: _nameCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
              onFieldSubmitted: (_) => _save(),
              decoration: InputDecoration(
                hintText: 'Your full name',
                prefixIcon: const Icon(Icons.person_outline_rounded),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
              validator: (v) => AppValidators.required(v, label: 'Full name'),
            ),

            const SizedBox(height: AppDimensions.sm),

            Text('EMAIL', style: AppTypography.labelSmall.copyWith(letterSpacing: 1.5)),
            const SizedBox(height: AppDimensions.sm),
            TextFormField(
              initialValue: widget.email,
              readOnly: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.email_outlined),
                filled: true,
                fillColor: AppColors.card.withAlpha(80),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                helperText: 'Email cannot be changed',
                helperStyle: AppTypography.caption,
              ),
            ),

            if (state.error != null) ...[
              const SizedBox(height: AppDimensions.md),
              _ErrorBanner(message: state.error!),
            ],

            const SizedBox(height: AppDimensions.xl),

            _SaveButton(
              label: 'Save Changes',
              isLoading: state.isLoading,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Change password bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _ChangePasswordSheet extends ConsumerStatefulWidget {
  const _ChangePasswordSheet();

  @override
  ConsumerState<_ChangePasswordSheet> createState() =>
      _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _pwCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  void dispose() {
    _pwCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await ref
        .read(_profileUpdateProvider.notifier)
        .updatePassword(_pwCtrl.text);
    if (ok && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_profileUpdateProvider);

    return _SheetShell(
      title: 'Change Password',
      icon: Icons.lock_outline_rounded,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _pwCtrl,
              obscureText: _obscure1,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'New Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(_obscure1
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscure1 = !_obscure1),
                ),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
              validator: AppValidators.password,
            ),

            const SizedBox(height: AppDimensions.md),

            TextFormField(
              controller: _confirmCtrl,
              obscureText: _obscure2,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _save(),
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(_obscure2
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscure2 = !_obscure2),
                ),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
              validator: (v) =>
                  AppValidators.confirmPassword(v, _pwCtrl.text),
            ),

            if (state.error != null) ...[
              const SizedBox(height: AppDimensions.md),
              _ErrorBanner(message: state.error!),
            ],

            const SizedBox(height: AppDimensions.xl),

            _SaveButton(
              label: 'Update Password',
              isLoading: state.isLoading,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared sheet shell
// ─────────────────────────────────────────────────────────────────────────────

class _SheetShell extends StatelessWidget {
  const _SheetShell({
    required this.title,
    required this.icon,
    required this.child,
  });
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
          border: Border.all(color: AppColors.border),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.xl,
            AppDimensions.lg,
            AppDimensions.xl,
            AppDimensions.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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

              // Title row
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMd),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryGlow,
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Text(title, style: AppTypography.headingMedium),
                ],
              ),
              const SizedBox(height: AppDimensions.xl),

              child,
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppDimensions.buttonHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGlow,
              blurRadius: 16,
              spreadRadius: 0,
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  label,
                  style: AppTypography.buttonLarge.copyWith(
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.error.withAlpha(20),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.error.withAlpha(80)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 18),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Settings section + tiles
// ─────────────────────────────────────────────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppDimensions.xs,
            bottom: AppDimensions.sm,
          ),
          child: Text(
            title.toUpperCase(),
            style: AppTypography.labelSmall.copyWith(letterSpacing: 1.5),
          ),
        ),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: children
                .asMap()
                .entries
                .map(
                  (e) => Column(
                    children: [
                      e.value,
                      if (e.key < children.length - 1)
                        const Divider(
                          height: 1,
                          color: AppColors.border,
                          indent: AppDimensions.md,
                        ),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.trailing,
  });
  final IconData icon;
  final String label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: AppDimensions.iconMd),
      title: Text(label, style: AppTypography.labelLarge),
      trailing: trailing,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.cardPadding,
        vertical: AppDimensions.xs,
      ),
    );
  }
}

/// Tappable tile that shows an arrow + current value, for editable fields.
class _TappableTile extends StatelessWidget {
  const _TappableTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.textSecondary, size: AppDimensions.iconMd),
      title: Text(label, style: AppTypography.labelLarge),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: AppTypography.bodySmall),
          const SizedBox(width: AppDimensions.xs),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textHint,
            size: 18,
          ),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.cardPadding,
        vertical: AppDimensions.xs,
      ),
    );
  }
}

