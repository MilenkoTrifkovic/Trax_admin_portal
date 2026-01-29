import 'package:flutter/material.dart';
import 'package:trax_admin_portal/helper/app_spacing.dart';
import 'package:trax_admin_portal/theme/app_colors.dart';
import 'package:trax_admin_portal/theme/styled_app_text.dart';
import 'package:trax_admin_portal/widgets/app_primary_button.dart';

/// Empty state widget shown when no super admins exist
class SuperAdminEmptyState extends StatelessWidget {
  final VoidCallback onAddPressed;

  const SuperAdminEmptyState({
    super.key,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.admin_panel_settings_outlined,
              size: 64,
              color: AppColors.textMuted,
            ),
            AppSpacing.verticalLg(context),
            AppText.styledHeadingSmall(
              context,
              'No Super Admins Yet',
              color: AppColors.primary,
            ),
            AppSpacing.verticalXs(context),
            AppText.styledBodyMedium(
              context,
              'Start by adding your first super admin',
              color: AppColors.textMuted,
              textAlign: TextAlign.center,
            ),
            AppSpacing.verticalLg(context),
            AppPrimaryButton(
              onPressed: onAddPressed,
              icon: Icons.add,
              text: 'Add Your First Super Admin',
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
