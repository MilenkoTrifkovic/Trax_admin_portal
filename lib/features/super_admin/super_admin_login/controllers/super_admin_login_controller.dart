import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:trax_admin_portal/controller/auth_controller/auth_controller.dart';
import 'package:trax_admin_portal/controller/global_controllers/snackbar_message_controller.dart';
import 'package:trax_admin_portal/services/auth_services.dart';
import 'package:trax_admin_portal/utils/navigation/app_routes.dart';
import 'package:trax_admin_portal/utils/navigation/routes.dart';

/// Controller for super admin login functionality
/// Handles authentication logic specific to super admin users
class SuperAdminLoginController extends GetxController {
  // Services
  final AuthServices _authServices = AuthServices();
  final _authController = Get.find<AuthController>();
  final _snackbarController = Get.find<SnackbarMessageController>();

  // Observable state
  final isLoading = false.obs;
  final isPasswordVisible = false.obs;

  // Form validation flag
  final isFormValid = false.obs;

  /// Toggle password visibility
  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  /// Handles the login button action
  /// Validates credentials and navigates to super admin area
  Future<void> handleLogin({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      isLoading.value = true;

      // Sign in with Firebase Auth
      final userCredential = await _authServices.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final currentUser = userCredential.user;
      if (currentUser == null) {
        _snackbarController.showErrorMessage('Login failed. Please try again.');
        return;
      }

      // Load user profile to get role and organization
      await _authController.loadUserProfile();

      // Check if user is verified
      if (!currentUser.emailVerified) {
        _snackbarController.showErrorMessage(
          'Please verify your email address before logging in.',
        );
        await _authServices.sendEmailVerification();
        if (context.mounted) {
          pushAndRemoveAllRoute(AppRoute.emailVerification, context);
        }
        return;
      }

      // Check if user is super admin
      if (!_authController.isSuperAdmin) {
        _snackbarController.showErrorMessage(
          'Access denied. This login is for super admins only.',
        );
        await _authController.logout();
        return;
      }

      // Success - navigate to super admin area
      _snackbarController.showSuccessMessage(
        'Welcome, Super Admin!',
      );

      if (context.mounted) {
        pushAndRemoveAllRoute(AppRoute.superAdminEvents, context);
      }
    } catch (e) {
      String errorMessage = 'An error occurred during login.';
      
      if (e.toString().contains('user-not-found')) {
        errorMessage = 'No account found with this email.';
      } else if (e.toString().contains('wrong-password')) {
        errorMessage = 'Incorrect password.';
      } else if (e.toString().contains('invalid-email')) {
        errorMessage = 'Invalid email address.';
      } else if (e.toString().contains('too-many-requests')) {
        errorMessage = 'Too many failed attempts. Please try again later.';
      }
      
      _snackbarController.showErrorMessage(errorMessage);
      print('❌ Super admin login error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Validates the form fields
  void validateForm(String email, String password) {
    final emailValid = email.trim().isNotEmpty && 
                      email.contains('@') && 
                      email.contains('.');
    final passwordValid = password.trim().isNotEmpty;
    
    isFormValid.value = emailValid && passwordValid;
  }

  @override
  void onClose() {
    // Clean up resources
    super.onClose();
  }
}
