import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/widgets/app_text_field.dart';
import '../controllers/auth_controller.dart';

class NewPasswordView extends GetView<AuthController> {
  const NewPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset('assets/icons/onboarding-nav-banner.png', height: 140, width: double.infinity, fit: BoxFit.cover),
            ),
            const SizedBox(height: 16),
            Text('New password', style: textTheme.headlineLarge),
            const SizedBox(height: 8),
            Text('Tap a new password to get access', style: textTheme.bodyLarge),
            const SizedBox(height: 20),
            Form(
              key: controller.formKeyNewPassword,
              child: Column(children: [
                AppTextField(
                  controller: controller.newPasswordController,
                  label: 'New password',
                  hint: 'Type new password',
                  isPassword: true,
                  validator: controller.validatePassword,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: controller.confirmPasswordController,
                  label: 'Confirm password',
                  hint: 'Passwords must match',
                  isPassword: true,
                  validator: controller.validatePassword,
                  textInputAction: TextInputAction.done,
                ),
              ]),
            ),
            const SizedBox(height: 24),
            Obx(() => SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: controller.isSubmitting.value ? null : controller.setNewPassword,
                    child: controller.isSubmitting.value
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Recover'),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}


