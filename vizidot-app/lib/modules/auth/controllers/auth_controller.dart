import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/auth_service.dart';

class AuthController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final fullNameController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final rememberMe = false.obs;
  final isSubmitting = false.obs;

  final formKeySignIn = GlobalKey<FormState>();
  final formKeySignUp = GlobalKey<FormState>();
  final formKeyForgot = GlobalKey<FormState>();
  final formKeyNewPassword = GlobalKey<FormState>();

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    fullNameController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(value)) return 'Enter a valid email';
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Minimum 6 characters';
    return null;
  }

  Future<void> signIn() async {
    if (!(formKeySignIn.currentState?.validate() ?? false)) return;
    isSubmitting.value = true;
    await Future.delayed(const Duration(milliseconds: 700));
    isSubmitting.value = false;
    await Get.find<AuthService>().signIn();
    Get.offAllNamed('/');
  }

  Future<void> sendReset() async {
    if (!(formKeyForgot.currentState?.validate() ?? false)) return;
    isSubmitting.value = true;
    await Future.delayed(const Duration(milliseconds: 700));
    isSubmitting.value = false;
  }

  Future<void> setNewPassword() async {
    if (!(formKeyNewPassword.currentState?.validate() ?? false)) return;
    if (newPasswordController.text != confirmPasswordController.text) {
      Get.snackbar('Error', 'Passwords do not match');
      return;
    }
    isSubmitting.value = true;
    await Future.delayed(const Duration(milliseconds: 700));
    isSubmitting.value = false;
    Get.back();
  }

  Future<void> signUp() async {
    if (!(formKeySignUp.currentState?.validate() ?? false)) return;
    isSubmitting.value = true;
    await Future.delayed(const Duration(milliseconds: 700));
    isSubmitting.value = false;
    await Get.find<AuthService>().signIn();
    Get.offAllNamed('/');
  }
}


