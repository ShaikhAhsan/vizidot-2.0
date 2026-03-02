import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../core/utils/auth_service.dart';
import '../widgets/custom_text_field.dart';

class ChangePasswordView extends StatefulWidget {
  const ChangePasswordView({super.key});

  @override
  State<ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<ChangePasswordView> {
  late TextEditingController _oldPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _oldPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    final oldPass = _oldPasswordController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (oldPass.isEmpty) {
      Get.snackbar('Error', 'Please enter your current password.', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (newPass.isEmpty) {
      Get.snackbar('Error', 'Please enter a new password.', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (newPass.length < 6) {
      Get.snackbar('Error', 'New password must be at least 6 characters.', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (newPass != confirmPass) {
      Get.snackbar('Error', 'New password and confirm password do not match.', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final auth = Get.find<AuthService>();
      await auth.changePassword(currentPassword: oldPass, newPassword: newPass);
      if (!mounted) return;
      Fluttertoast.showToast(
        msg: 'Password updated successfully',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      Get.back();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message = 'Could not update password.';
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          message = 'Current password is incorrect.';
          break;
        case 'weak-password':
          message = 'New password is too weak. Use at least 6 characters.';
          break;
        case 'no-user':
        case 'no-email':
          message = e.message ?? message;
          break;
        case 'requires-recent-login':
          message = 'Please sign out and sign in again, then try changing your password.';
          break;
      }
      Get.snackbar('Error', message, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      if (!mounted) return;
      Get.snackbar('Error', 'Something went wrong. Please try again.', snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return CupertinoPageScaffold(
      child: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          // Navigation Bar with Large Title - matching home screen
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Change password'),
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              onPressed: () => Get.back(),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  CupertinoIcons.arrow_left,
                  color: colors.onSurface,
                  size: 18,
                ),
              ),
            ),
            backgroundColor: Colors.transparent,
            border: null,
            automaticallyImplyTitle: false,
            automaticallyImplyLeading: false,
          ),
          SliverSafeArea(
            top: false,
            sliver: SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 12),
                  // Subtitle
                  Text(
                    'TAP A NEW PASSWORD TO GET ACCESS',
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      letterSpacing: 0.5,
                      color: colors.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Old Password Field
                  CustomTextField(
                    label: 'Old password',
                    hint: 'Type an old password',
                    controller: _oldPasswordController,
                    isPassword: true,
                    keyboardType: TextInputType.visiblePassword,
                  ),
                  const SizedBox(height: 16),
                  // New Password Field
                  CustomTextField(
                    label: 'New password',
                    hint: 'Type a new password',
                    controller: _newPasswordController,
                    isPassword: true,
                    keyboardType: TextInputType.visiblePassword,
                  ),
                  const SizedBox(height: 16),
                  // Confirm Password Field
                  CustomTextField(
                    label: 'Confirm password',
                    hint: 'Repeat a new password',
                    controller: _confirmPasswordController,
                    isPassword: true,
                    keyboardType: TextInputType.visiblePassword,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 40),
                  // Update Password Button
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      color: colors.onSurface,
                      onPressed: _isLoading ? null : _updatePassword,
                      child: _isLoading
                          ? const CupertinoActivityIndicator(color: Colors.white)
                          : const Text(
                              'Update password',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

