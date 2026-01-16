import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:trax_admin_portal/controller/auth_controller/sign_in_controller.dart';
import 'package:trax_admin_portal/helper/app_padding.dart';
import 'package:trax_admin_portal/theme/app_colors.dart';
import 'package:trax_admin_portal/theme/constants.dart';
import 'package:trax_admin_portal/utils/enums/sizes.dart';

class SignInHeader extends StatelessWidget {
  final SignInController controller;

  const SignInHeader({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with Logo
        Padding(
          padding: AppPadding.only(
            context,
            paddingType: Sizes.lg,
            bottom: true,
          ),
          child: Image.asset(
            Constants.lightLogo,
            height: 32,
          ),
        ),

        // Admin & Sales Portal Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryAccent.withOpacity(0.1),
                AppColors.primaryAccent.withOpacity(0.05),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: AppColors.primaryAccent.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.admin_panel_settings_outlined,
                size: 16,
                color: AppColors.primaryAccent,
              ),
              const SizedBox(width: 6),
              Text(
                "Admin & Sales Portal",
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.primaryAccent,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
              ),
            ],
          ),
        ),

        // Title
        Obx(() => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                controller.isSignUpMode.value
                    ? "Create your account"
                    : "Sign in to Trax Events",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            )),

        // Subtitle
        Obx(() => Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Text(
                controller.isSignUpMode.value
                    ? "Start organizing amazing events today"
                    : "Welcome back! Please enter your details.",
                style: Theme.of(context).textTheme.bodySmall,
              ),
            )),
      ],
    );
  }
}
