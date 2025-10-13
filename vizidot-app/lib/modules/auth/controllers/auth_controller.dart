import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/auth_service.dart';
import '../../../routes/app_pages.dart';

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
    try {
      await Get.find<AuthService>().signInWithEmail(emailController.text.trim(), passwordController.text);
      Get.offAllNamed(AppRoutes.categories);
    } on Exception catch (e) {
      Get.snackbar('Sign in failed', _mapError(e));
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> sendReset() async {
    final bool isValid = formKeyForgot.currentState?.validate() ?? false;
    if (!isValid) return false;
    isSubmitting.value = true;
    try {
      await Get.find<AuthService>().sendPasswordReset(emailController.text.trim());
      return true;
    } on Exception catch (e) {
      Get.snackbar('Reset failed', _mapError(e));
      return false;
    } finally {
      isSubmitting.value = false;
    }
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
    try {
      await Get.find<AuthService>().signUpWithEmail(emailController.text.trim(), passwordController.text);
      Get.offAllNamed(AppRoutes.categories);
    } on Exception catch (e) {
      Get.snackbar('Sign up failed', _mapError(e));
    } finally {
      isSubmitting.value = false;
    }
  }

  String _mapError(Exception e) {
    final msg = e.toString();
    if (msg.contains('invalid-credential') || msg.contains('wrong-password')) return 'Invalid email or password';
    if (msg.contains('user-not-found')) return 'No account found for that email';
    if (msg.contains('email-already-in-use')) return 'Email already in use';
    if (msg.contains('weak-password')) return 'Choose a stronger password';
    if (msg.contains('network-request-failed')) return 'Network error. Please try again';
    return 'Something went wrong. Please try again';
  }

  Future<void> googleSignIn() async {
    isSubmitting.value = true;
    try {
      await Get.find<AuthService>().signInWithGoogle();
      Get.offAllNamed(AppRoutes.categories);
    } on Exception catch (e) {
      Get.snackbar('Google sign-in failed', _mapError(e));
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> appleSignIn() async {
    isSubmitting.value = true;
    try {
      await Get.find<AuthService>().signInWithApple();
      Get.offAllNamed(AppRoutes.categories);
    } on Exception catch (e) {
      Get.snackbar('Apple sign-in failed', _mapError(e));
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> facebookSignIn() async {
    isSubmitting.value = true;
    try {
      await Get.find<AuthService>().signInWithFacebook();
      Get.offAllNamed(AppRoutes.categories);
    } on Exception catch (e) {
      Get.snackbar('Facebook sign-in failed', _mapError(e));
    } finally {
      isSubmitting.value = false;
    }
  }
}


