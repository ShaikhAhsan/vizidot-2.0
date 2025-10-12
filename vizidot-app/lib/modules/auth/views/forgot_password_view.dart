import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/widgets/app_text_field.dart';
import '../controllers/auth_controller.dart';
import '../../../core/widgets/overlay_back_button.dart';

class ForgotPasswordView extends GetView<AuthController> {
  const ForgotPasswordView({super.key});

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
              child: Text('Forgot password', style: textTheme.headlineLarge),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Tap the email address associated with your account', style: textTheme.bodyLarge),
            ),
            const SizedBox(height: 20),
            Form(
              key: controller.formKeyForgot,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AppTextField(
                  controller: controller.emailController,
                  label: 'Email',
                  hint: 'Enter your email address',
                  keyboardType: TextInputType.emailAddress,
                  validator: controller.validateEmail,
                  textInputAction: TextInputAction.done,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Obx(() => SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: FilledButton(
                    onPressed: controller.isSubmitting.value
                        ? null
                        : () async {
                            await controller.sendReset();
                            if (!controller.isSubmitting.value) _showCheckMailboxDialog(context);
                          },
                      child: controller.isSubmitting.value
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Send instructions'),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  void _showCheckMailboxDialog(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              CircleAvatar(
                radius: 28,
                backgroundColor: colors.primary.withOpacity(0.12),
                child: Icon(Icons.mail_outline, color: colors.primary, size: 28),
              ),
              const SizedBox(height: 16),
              Text('Check your mailbox', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('We sent the instructions to recover your account', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Check the letter')),
              )
            ],
          ),
        ),
      ),
    );
  }
}


