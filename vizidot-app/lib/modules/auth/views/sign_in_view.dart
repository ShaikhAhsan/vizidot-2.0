import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../routes/app_pages.dart';
import '../controllers/auth_controller.dart';
import '../../../core/widgets/overlay_back_button.dart';

class SignInView extends GetView<AuthController> {
  const SignInView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      resizeToAvoidBottomInset: true,

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Banner(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Sign in', style: textTheme.headlineLarge),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () => Get.toNamed(AppRoutes.signUp),
                          child: Text('/  sign up', style: textTheme.titleLarge?.copyWith(color: colors.onBackground.withOpacity(0.6))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Fill the form to sign in into account', style: textTheme.bodyLarge),
                    const SizedBox(height: 20),
                    Form(
                      key: controller.formKeySignIn,
                      child: Column(
                        children: [
                          AppTextField(
                            controller: controller.emailController,
                            label: 'Email',
                            hint: 'Enter your email address',
                            keyboardType: TextInputType.emailAddress,
                            validator: controller.validateEmail,
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: controller.passwordController,
                            label: 'Password',
                            hint: 'Enter your password',
                            isPassword: true,
                            validator: controller.validatePassword,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => controller.signIn(),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Obx(() => Switch(
                                value: controller.rememberMe.value,
                                onChanged: (v) => controller.rememberMe.value = v,
                              )),
                              const SizedBox(width: 8),
                              Text('REMEMBER', style: textTheme.labelLarge),
                              const Spacer(),
                              TextButton(
                                onPressed: () => Get.toNamed(AppRoutes.forgotPassword),
                                child: const Text('Forgot password?'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Obx(() => SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: controller.isSubmitting.value ? null : controller.signIn,
                                  child: controller.isSubmitting.value
                                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                      : const Text('Sign in'),
                                ),
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),
                    Center(child: Text('OR SIGN IN WITH', style: textTheme.labelLarge?.copyWith(color: colors.onSurface.withOpacity(0.6)))),
                    const SizedBox(height: 18),
                    const _SocialRow(),
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner();

  @override
  Widget build(BuildContext context) {
    final double top = MediaQuery.of(context).padding.top;
    return SizedBox(
      height: 112,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(top: top),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
                child: Image.asset('assets/icons/onboarding-nav-banner.png', width: double.infinity, height: double.infinity, fit: BoxFit.cover),
              ),
            ),
          ),
          Positioned(
            top: top + ((112 - top) / 2),
            left: 16,
            child: const OverlayBackButton(),
          ),
        ],
      ),
    );
  }
}

class _SocialRow extends StatelessWidget {
  const _SocialRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        _SocialButton(asset: 'assets/icons/facebook.png'),
        SizedBox(width: 16),
        _SocialButton(asset: 'assets/icons/instagram.png'),
        SizedBox(width: 16),
        _SocialButton(asset: 'assets/icons/google.png'),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String asset;
  const _SocialButton({required this.asset});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.onSurface.withOpacity(0.4)),
      ),
      child: Center(child: Image.asset(asset, width: 28, height: 28, color: colors.onSurface)),
    );
  }
}


