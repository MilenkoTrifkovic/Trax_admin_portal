import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:trax_admin_portal/controller/auth_controller/sign_in_controller.dart';
import 'package:trax_admin_portal/helper/validation_helper.dart';
import 'package:trax_admin_portal/theme/app_colors.dart';

class SignInForm extends StatelessWidget {
  final SignInController controller;
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final VoidCallback onSubmit;
  final VoidCallback onForgotPassword;

  const SignInForm({
    super.key,
    required this.controller,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.onSubmit,
    required this.onForgotPassword,
  });

  ButtonStyle _oauthBtnStyle(BuildContext context, {bool primary = false}) {
    return OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: BorderSide(color: AppColors.primary.withOpacity(0.35)),
      backgroundColor: primary ? AppColors.primary : Colors.transparent,
      foregroundColor: primary ? Colors.white : AppColors.primary,
      textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          // Email Field
          TextFormField(
            controller: emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'Enter your email',
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: ValidationHelper.validateEmail,
          ),

          const SizedBox(height: 16),

          // -----------------------
          // OAuth buttons (Sign in / Sign up)
          // -----------------------
          Obx(() {
            final isSignUp = controller.isSignUpMode.value;
            final isBusy = controller.isLoading.value;

            return Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: _oauthBtnStyle(context, primary: true),
                    onPressed: isBusy ? null : controller.signInWithGoogle,
                    child: Text(
                      isSignUp ? 'Sign up with Google' : 'Sign in with Google',
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: _oauthBtnStyle(context),
                    onPressed: isBusy ? null : controller.signInWithMicrosoft,
                    child: Text(
                      isSignUp
                          ? 'Sign up with Microsoft'
                          : 'Sign in with Microsoft',
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: _oauthBtnStyle(context),
                    onPressed: isBusy ? null : controller.signInWithApple,
                    child: Text(
                      isSignUp ? 'Sign up with Apple' : 'Sign in with Apple',
                    ),
                  ),
                ),
              ],
            );
          }),

          const SizedBox(height: 18),

          // Divider: OR
          Row(
            children: [
              Expanded(
                child: Divider(color: Colors.grey.withOpacity(0.25)),
              ),
              const SizedBox(width: 10),
              Text(
                'or',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Divider(color: Colors.grey.withOpacity(0.25)),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Password Field
          Obx(() => TextFormField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.isPasswordVisible.value
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: controller.togglePasswordVisibility,
                  ),
                ),
                obscureText: !controller.isPasswordVisible.value,
                textInputAction: controller.isSignUpMode.value
                    ? TextInputAction.next
                    : TextInputAction.done,
                validator: ValidationHelper.validatePassword,
                onFieldSubmitted: (_) {
                  if (!controller.isSignUpMode.value) {
                    onSubmit();
                  }
                },
              )),

          // Confirm Password Field (only show in sign up mode)
          Obx(() {
            if (!controller.isSignUpMode.value) return const SizedBox.shrink();

            return Column(
              children: [
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    hintText: 'Confirm your password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        controller.isConfirmPasswordVisible.value
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: controller.toggleConfirmPasswordVisibility,
                    ),
                  ),
                  obscureText: !controller.isConfirmPasswordVisible.value,
                  textInputAction: TextInputAction.done,
                  validator: (value) =>
                      ValidationHelper.validateConfirmPassword(
                    value,
                    passwordController.text,
                  ),
                  onFieldSubmitted: (_) => onSubmit(),
                ),
              ],
            );
          }),

          const SizedBox(height: 24),

          // Sign In/Up Button (email/password)
          Obx(() => SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: controller.isLoading.value ? null : onSubmit,
                  child: controller.isLoading.value
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          controller.isSignUpMode.value
                              ? 'Create account'
                              : 'Sign in',
                        ),
                ),
              )),

          // Forgot Password (only show in sign in mode)
          Obx(() {
            if (controller.isSignUpMode.value) return const SizedBox.shrink();

            return Column(
              children: [
                const SizedBox(height: 16),
                TextButton(
                  onPressed: onForgotPassword,
                  child: Text(
                    'Forgot your password?',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ],
            );
          }),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
