import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/onboarding_app_bar.dart';
import '../controllers/auth_controller.dart';

class SignUpView extends GetView<AuthController> {
  const SignUpView({super.key});

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
          // padding: const EdgeInsets.only(bottom: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 0),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Sign up', style: textTheme.headlineLarge),
                    const SizedBox(width: 10),
                    Text('/  sign in', style: textTheme.titleLarge?.copyWith(color: colors.onBackground.withOpacity(0.6))),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('Fill the form to create an account', style: textTheme.bodyLarge),
              ),
              const SizedBox(height: 40),
              Form(
                key: controller.formKeySignUp,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(children: [
                    AppTextField(
                      controller: controller.fullNameController,
                      label: 'Full name',
                      hint: 'write a full name...',
                      keyboardType: TextInputType.name,
                      validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 16),
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
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 24),
              Obx(() => SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: FilledButton(
                        onPressed: controller.isSubmitting.value ? null : controller.signUp,
                        child: controller.isSubmitting.value
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Sign up'),
                      ),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}


