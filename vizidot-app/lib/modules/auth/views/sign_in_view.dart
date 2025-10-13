import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../routes/app_pages.dart';
import '../controllers/auth_controller.dart';
import '../../../core/widgets/onboarding_app_bar.dart';

class SignInView extends GetView<AuthController> {
  const SignInView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      top: false,
      bottom: false,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: const OnboardingAppBar(imageAsset: 'assets/icons/onboarding-nav-banner.png', showBack: true),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // const OnboardingAppBar(imageAsset: 'assets/icons/onboarding-nav-banner.png', showBack: false),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // const SizedBox(height: 40),
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
                      const SizedBox(height: 40),
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
                            const SizedBox(height: 20),
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
                      const SizedBox(height: 40),
                      Center(child: Text('OR SIGN IN WITH', style: textTheme.labelSmall?.copyWith(color: colors.onSurface.withOpacity(1.0)))),
                      const SizedBox(height: 26),
                      _SocialRow(onGoogleTap: controller.googleSignIn),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ),
    );
  }
}

class _SocialRow extends StatelessWidget {
  final VoidCallback? onGoogleTap;
  const _SocialRow({this.onGoogleTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SocialButton(asset: 'assets/icons/facebook.png', onTap: () => Get.find<AuthController>().facebookSignIn()),
        const SizedBox(width: 16),
        _SocialButton(asset: 'assets/icons/apple.png', onTap: () => Get.find<AuthController>().appleSignIn()),
        const SizedBox(width: 16),
        _SocialButton(asset: 'assets/icons/google.png', onTap: onGoogleTap),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String asset;
  final VoidCallback? onTap;
  const _SocialButton({required this.asset, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final button = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.onSurface.withOpacity(1.0)),
      ),
      child: Center(child: Image.asset(asset, width: 15, height: 15, color: colors.onSurface)),
    );
    if (onTap == null) return button;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: button,
    );
  }
}


