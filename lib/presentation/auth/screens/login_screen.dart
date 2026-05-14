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
import '../../widgets/app_text_field.dart';
import '../../widgets/geometric_background.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_form_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await ref
        .read(loginProvider.notifier)
        .login(_emailCtrl.text, _passwordCtrl.text);
    if (ok && mounted) context.go(AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: GeometricBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: size.height -
                    MediaQuery.of(context).padding.top,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.screenPadding,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: AppDimensions.xxl),

                    // ── Hero Logo ──────────────────────────────────────────
                    Hero(
                      tag: 'app-logo',
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusLg),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryGlow,
                              blurRadius: 24,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    )
                        .animate()
                        .scale(
                          begin: const Offset(0.5, 0.5),
                          duration: 700.ms,
                          curve: Curves.elasticOut,
                        )
                        .fadeIn(duration: 400.ms),

                    const SizedBox(height: AppDimensions.md),

                    Text(
                      'Smart Shelf',
                      style: AppTypography.headingLarge.copyWith(
                        foreground: Paint()
                          ..shader = AppColors.primaryGradient.createShader(
                            const Rect.fromLTWH(0, 0, 200, 40),
                          ),
                      ),
                    )
                        .animate(delay: 200.ms)
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: 0.3, end: 0),

                    const SizedBox(height: AppDimensions.xxl),

                    // ── Glass card ─────────────────────────────────────────
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
                                  'Welcome back',
                                  style: AppTypography.displaySmall,
                                )
                                    .animate(delay: 300.ms)
                                    .fadeIn()
                                    .slideX(begin: -0.2, end: 0),

                                const SizedBox(height: AppDimensions.xs),

                                Text(
                                  'Sign in to monitor your shelves',
                                  style: AppTypography.bodyMedium,
                                )
                                    .animate(delay: 380.ms)
                                    .fadeIn()
                                    .slideX(begin: -0.2, end: 0),

                                const SizedBox(height: AppDimensions.lg),

                                // Error banner
                                if (state.error != null)
                                  AuthErrorBanner(message: state.error!),

                                // Email
                                AppTextField(
                                  controller: _emailCtrl,
                                  label: 'Email',
                                  hint: 'you@example.com',
                                  prefixIcon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  onSubmitted: (_) => FocusScope.of(context)
                                      .requestFocus(_passwordFocus),
                                  validator: AppValidators.email,
                                )
                                    .animate(delay: 450.ms)
                                    .fadeIn()
                                    .slideX(begin: 0.15, end: 0),

                                const SizedBox(height: AppDimensions.md),

                                // Password
                                PasswordField(
                                  controller: _passwordCtrl,
                                  focusNode: _passwordFocus,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => _submit(),
                                  validator: AppValidators.password,
                                )
                                    .animate(delay: 520.ms)
                                    .fadeIn()
                                    .slideX(begin: 0.15, end: 0),

                                // Forgot password
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {},
                                    child: Text(
                                      'Forgot password?',
                                      style: AppTypography.labelMedium
                                          .copyWith(
                                              color: AppColors.primary),
                                    ),
                                  ),
                                ).animate(delay: 570.ms).fadeIn(),

                                const SizedBox(height: AppDimensions.sm),

                                AuthGlowButton(
                                  label: 'Sign In',
                                  isLoading: state.isLoading,
                                  onPressed:
                                      state.isLoading ? null : _submit,
                                ).animate(delay: 620.ms).fadeIn().slideY(
                                      begin: 0.3,
                                      end: 0,
                                      curve: Curves.easeOutCubic,
                                    ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ).animate(delay: 250.ms).fadeIn(duration: 500.ms).scale(
                          begin: const Offset(0.95, 0.95),
                          duration: 500.ms,
                          curve: Curves.easeOutCubic,
                        ),

                    const SizedBox(height: AppDimensions.xl),

                    // Sign up link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: AppTypography.bodyMedium,
                        ),
                        GestureDetector(
                          onTap: () => context.push(AppRoutes.signup),
                          child: Text(
                            'Sign Up',
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ).animate(delay: 700.ms).fadeIn(),

                    const SizedBox(height: AppDimensions.xxl),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
