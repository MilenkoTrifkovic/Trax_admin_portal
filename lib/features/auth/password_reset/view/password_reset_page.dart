import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/password_reset_controller.dart';
import '../../../../theme/app_colors.dart';

/// Password Reset Page - handles custom password reset UI
class PasswordResetPage extends StatelessWidget {
  final String oobCode;
  
  const PasswordResetPage({super.key, required this.oobCode});

  @override
  Widget build(BuildContext context) {
    // Check if oobCode is empty
    if (oobCode.isEmpty) {
      return _buildErrorScaffold(
        'Invalid Reset Link',
        'The password reset link is invalid or missing required parameters.',
      );
    }

    return GetBuilder<PasswordResetController>(
      init: PasswordResetController(),
      builder: (controller) {
        // Initialize with code on first build
        if (controller.oobCode.isEmpty) {
          controller.initializeWithCode(oobCode);
        }

        return Scaffold(
          backgroundColor: AppColors.surfaceCard,
          body: Obx(() {
            if (controller.isVerifying.value) {
              return _buildLoadingView();
            }

            if (!controller.codeVerified.value) {
              return _buildErrorScaffold(
                'Invalid or Expired Link',
                'This password reset link is invalid or has expired. Please request a new password reset.',
              );
            }

            return _buildResetForm(controller);
          }),
        );
      },
    );
  }

  /// Build loading view while verifying code
  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 24),
          Text(
            'Verifying reset link...',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  /// Build error scaffold for invalid/expired links
  Widget _buildErrorScaffold(String title, String message) {
    return Scaffold(
      backgroundColor: AppColors.surfaceCard,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(32),
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => Get.offAllNamed('/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: const Text('Go to Login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build the password reset form
  Widget _buildResetForm(PasswordResetController controller) {
    final formKey = GlobalKey<FormState>();

    return Builder(
      builder: (BuildContext context) => Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(32),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Icon(
                        Icons.lock_reset,
                        size: 64,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Reset Your Password',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Obx(() => Text(
                            'Setting new password for ${controller.email.value}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textMuted,
                            ),
                          )),
                      const SizedBox(height: 32),

                      // New Password Field
                      Obx(() => TextFormField(
                            controller: controller.passwordController,
                            obscureText: controller.obscurePassword.value,
                            decoration: InputDecoration(
                              labelText: 'New Password',
                              hintText: 'Enter your new password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  controller.obscurePassword.value
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: controller.togglePasswordVisibility,
                              ),
                              border: const OutlineInputBorder(),
                            ),
                            validator: controller.validatePassword,
                          )),
                      const SizedBox(height: 16),

                      // Confirm Password Field
                      Obx(() => TextFormField(
                            controller: controller.confirmPasswordController,
                            obscureText: controller.obscureConfirmPassword.value,
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              hintText: 'Re-enter your new password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  controller.obscureConfirmPassword.value
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed:
                                    controller.toggleConfirmPasswordVisibility,
                              ),
                              border: const OutlineInputBorder(),
                            ),
                            validator: controller.validatePasswordsMatch,
                          )),
                      const SizedBox(height: 8),

                      // Password requirements hint
                      Text(
                        '• Password must be at least 8 characters',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Submit Button
                      Obx(() => ElevatedButton(
                            onPressed: controller.isLoading.value
                                ? null
                                : () {
                                    if (formKey.currentState!.validate()) {
                                      controller.submitPasswordReset(context);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: controller.isLoading.value
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Reset Password',
                                    style: TextStyle(fontSize: 16),
                                  ),
                          )),
                      const SizedBox(height: 16),

                      // Back to login link
                      TextButton(
                        onPressed: () => Get.offAllNamed('/login'),
                        child: const Text('Back to Login'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
