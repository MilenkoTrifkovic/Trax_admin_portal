import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../../models/password_reset_request.dart';
import '../../../../services/password_reset_service.dart';
import '../../../../controller/global_controllers/snackbar_message_controller.dart';
import '../../../../utils/navigation/routes.dart';
import '../../../../utils/navigation/app_routes.dart';

/// Controller for password reset page
class PasswordResetController extends GetxController {
  final PasswordResetService _passwordResetService = PasswordResetService();
  final SnackbarMessageController _snackbarController = Get.find<SnackbarMessageController>();

  // Form controllers
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // State
  final isLoading = false.obs;
  final isVerifying = true.obs;
  final email = ''.obs;
  final oobCode = ''.obs;
  final codeVerified = false.obs;

  // Password visibility
  final obscurePassword = true.obs;
  final obscureConfirmPassword = true.obs;

  @override
  void onClose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  /// Toggle password visibility
  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  /// Toggle confirm password visibility
  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword.value = !obscureConfirmPassword.value;
  }

  /// Initialize and verify the reset code from URL
  Future<void> initializeWithCode(String code) async {
    oobCode.value = code;
    await verifyCode();
  }

  /// Verify the password reset code
  Future<void> verifyCode() async {
    try {
      isVerifying.value = true;
      final verifiedEmail = await _passwordResetService.verifyResetCode(oobCode.value);
      email.value = verifiedEmail;
      codeVerified.value = true;
      print('✅ Password reset code verified for: $verifiedEmail');
    } catch (e) {
      print('❌ Error verifying code: $e');
      codeVerified.value = false;
      _snackbarController.showErrorMessage(
        'Invalid or expired reset link. Please request a new password reset.',
      );
    } finally {
      isVerifying.value = false;
    }
  }

  /// Validate passwords match
  String? validatePasswordsMatch(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Validate password strength
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    // Optional: Add more password requirements
    // if (!value.contains(RegExp(r'[A-Z]'))) {
    //   return 'Password must contain at least one uppercase letter';
    // }
    // if (!value.contains(RegExp(r'[0-9]'))) {
    //   return 'Password must contain at least one number';
    // }
    return null;
  }

  /// Submit password reset
  Future<void> submitPasswordReset(BuildContext context) async {
    if (isLoading.value) return;

    // Validate passwords
    final passwordError = validatePassword(passwordController.text);
    if (passwordError != null) {
      _snackbarController.showErrorMessage(passwordError);
      return;
    }

    final matchError = validatePasswordsMatch(confirmPasswordController.text);
    if (matchError != null) {
      _snackbarController.showErrorMessage(matchError);
      return;
    }

    try {
      isLoading.value = true;

      final request = PasswordResetRequest(
        oobCode: oobCode.value,
        newPassword: passwordController.text,
      );

      final response = await _passwordResetService.confirmPasswordReset(request);

      if (response.success) {
        _snackbarController.showSuccessMessage(
          'Password reset successful! Redirecting to login...',
        );
        
        // Wait a moment before redirecting
        await Future.delayed(const Duration(seconds: 2));
        
        // Navigate to login page using proper navigation method
        if (context.mounted) {
          pushAndRemoveAllRoute(AppRoute.welcome, context);
        }
      } else {
        _snackbarController.showErrorMessage(
          response.message ?? 'Failed to reset password',
        );
      }
    } catch (e) {
      print('❌ Error resetting password: $e');
      _snackbarController.showErrorMessage(
        'Failed to reset password. Please try again.',
      );
    } finally {
      isLoading.value = false;
    }
  }
}
