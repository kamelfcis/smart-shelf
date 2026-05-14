import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/validators.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/geometric_background.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_form_widgets.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await ref
        .read(signupProvider.notifier)
        .signUp(_emailCtrl.text, _passwordCtrl.text, _nameCtrl.text);

    if (!mounted) return;

    final signupState = ref.read(signupProvider);

    if (signupState.needsEmailConfirmation) {
      _showInboxDialog(_emailCtrl.text.trim());
      return;
    }
    if (ok) context.go(AppRoutes.dashboard);
  }

  void _showInboxDialog(String email) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _InboxConfirmationSheet(email: email),
    ).then((_) {
      if (mounted) context.go(AppRoutes.login);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signupProvider);

    // Listen for email-confirmation state change
    ref.listen<SignupState>(signupProvider, (_, next) {
      if (next.needsEmailConfirmation && mounted) {
        _showInboxDialog(_emailCtrl.text.trim());
      }
    });

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: GeometricBackground(
        accentColor: AppColors.secondary,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.screenPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppDimensions.lg),

                  // Back + Hero logo row
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusMd),
                            border:
                                Border.all(color: AppColors.border),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Hero(
                        tag: 'app-logo',
                        child: Container(
                          width: 42,
                          height: 42,
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
                          child: const Icon(
                            Icons.inventory_2_outlined,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms),

                  const SizedBox(height: AppDimensions.xl),

                  // ── Glass card ─────────────────────────────────────────────
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusXl),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.card.withAlpha(180),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusXl,
                          ),
                          border: Border.all(
                            color: AppColors.border.withAlpha(100),
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(AppDimensions.xl),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create account',
                                style: AppTypography.displaySmall,
                              )
                                  .animate(delay: 200.ms)
                                  .fadeIn()
                                  .slideX(begin: -0.2, end: 0),

                              const SizedBox(height: AppDimensions.xs),

                              Text(
                                'Start monitoring your shelves today',
                                style: AppTypography.bodyMedium,
                              )
                                  .animate(delay: 260.ms)
                                  .fadeIn()
                                  .slideX(begin: -0.2, end: 0),

                              const SizedBox(height: AppDimensions.lg),

                              // Error banner
                              if (state.error != null)
                                AuthErrorBanner(message: state.error!),

                              // Full name
                              AppTextField(
                                controller: _nameCtrl,
                                label: 'Full Name',
                                hint: 'John Doe',
                                prefixIcon: Icons.person_outline_rounded,
                                textInputAction: TextInputAction.next,
                                onSubmitted: (_) => FocusScope.of(context)
                                    .requestFocus(_emailFocus),
                                validator: (v) =>
                                    AppValidators.required(v, label: 'Full name'),
                              )
                                  .animate(delay: 330.ms)
                                  .fadeIn()
                                  .slideX(begin: 0.15, end: 0),

                              const SizedBox(height: AppDimensions.md),

                              // Email
                              AppTextField(
                                controller: _emailCtrl,
                                focusNode: _emailFocus,
                                label: 'Email',
                                hint: 'you@example.com',
                                prefixIcon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                onSubmitted: (_) => FocusScope.of(context)
                                    .requestFocus(_passwordFocus),
                                validator: AppValidators.email,
                              )
                                  .animate(delay: 400.ms)
                                  .fadeIn()
                                  .slideX(begin: 0.15, end: 0),

                              const SizedBox(height: AppDimensions.md),

                              // Password
                              PasswordField(
                                controller: _passwordCtrl,
                                focusNode: _passwordFocus,
                                textInputAction: TextInputAction.next,
                                onSubmitted: (_) => FocusScope.of(context)
                                    .requestFocus(_confirmFocus),
                                validator: AppValidators.password,
                              )
                                  .animate(delay: 460.ms)
                                  .fadeIn()
                                  .slideX(begin: 0.15, end: 0),

                              const SizedBox(height: AppDimensions.md),

                              // Confirm password
                              PasswordField(
                                controller: _confirmCtrl,
                                focusNode: _confirmFocus,
                                label: 'Confirm Password',
                                hint: 'Re-enter your password',
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _submit(),
                                validator: (v) => AppValidators.confirmPassword(
                                  v,
                                  _passwordCtrl.text,
                                ),
                              )
                                  .animate(delay: 520.ms)
                                  .fadeIn()
                                  .slideX(begin: 0.15, end: 0),

                              const SizedBox(height: AppDimensions.xl),

                              AuthGlowButton(
                                label: 'Create Account',
                                isLoading: state.isLoading,
                                onPressed: state.isLoading ? null : _submit,
                              ).animate(delay: 580.ms).fadeIn().slideY(
                                    begin: 0.3,
                                    end: 0,
                                    curve: Curves.easeOutCubic,
                                  ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                      .animate(delay: 150.ms)
                      .fadeIn(duration: 500.ms)
                      .scale(
                        begin: const Offset(0.95, 0.95),
                        duration: 500.ms,
                        curve: Curves.easeOutCubic,
                      ),

                  const SizedBox(height: AppDimensions.xl),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: AppTypography.bodyMedium,
                      ),
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Text(
                          'Sign In',
                          style: AppTypography.labelLarge
                              .copyWith(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ).animate(delay: 650.ms).fadeIn(),

                  const SizedBox(height: AppDimensions.xxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// "Check your inbox" bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _InboxConfirmationSheet extends StatelessWidget {
  const _InboxConfirmationSheet({required this.email});
  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.xl,
          AppDimensions.xl,
          AppDimensions.xl,
          AppDimensions.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated envelope icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGlow,
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.mark_email_read_outlined,
                color: Colors.white,
                size: 40,
              ),
            )
                .animate()
                .scale(
                  begin: const Offset(0.3, 0.3),
                  duration: 700.ms,
                  curve: Curves.elasticOut,
                )
                .fadeIn(duration: 400.ms)
                .shimmer(
                  delay: 700.ms,
                  duration: 1000.ms,
                  color: Colors.white.withAlpha(80),
                ),

            const SizedBox(height: AppDimensions.lg),

            Text(
              'Check your inbox!',
              style: AppTypography.headingLarge,
              textAlign: TextAlign.center,
            ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.3),

            const SizedBox(height: AppDimensions.sm),

            Text(
              'We sent a confirmation link to',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ).animate(delay: 400.ms).fadeIn(),

            const SizedBox(height: AppDimensions.xs),

            Text(
              email,
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ).animate(delay: 450.ms).fadeIn(),

            const SizedBox(height: AppDimensions.sm),

            Text(
              'Click the link in the email to activate your account, then sign in.',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ).animate(delay: 500.ms).fadeIn(),

            const SizedBox(height: AppDimensions.xl),

            PrimaryButton(
              label: 'Go to Sign In',
              onPressed: () => Navigator.of(context).pop(),
            ).animate(delay: 600.ms).fadeIn().slideY(begin: 0.2),
          ],
        ),
      ),
    );
  }
}
