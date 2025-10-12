import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/widgets/app_text_field.dart';
import '../controllers/auth_controller.dart';
import '../../../core/widgets/overlay_back_button.dart';

class NewPasswordView extends GetView<AuthController> {
  const NewPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final double top = MediaQuery.of(context).padding.top;
    final double bottom = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 16 + bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 112,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: EdgeInsets.only(top: top),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
                        child: Image.asset('assets/icons/onboarding-nav-banner.png', fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  Positioned(
                    top: top + ((112 - top - 44) / 2),
                    left: 16,
                    child: const OverlayBackButton(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('New password', style: textTheme.headlineLarge),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Tap a new password to get access', style: textTheme.bodyLarge),
            ),
            const SizedBox(height: 20),
            Form(
              key: controller.formKeyNewPassword,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
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
            ),
            const SizedBox(height: 24),
            Obx(() => SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: FilledButton(
                      onPressed: controller.isSubmitting.value ? null : controller.setNewPassword,
                      child: controller.isSubmitting.value
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Recover'),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}


