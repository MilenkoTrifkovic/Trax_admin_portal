import 'package:flutter/material.dart';
import 'package:trax_admin_portal/models/super_admin_model.dart';
import 'package:trax_admin_portal/theme/app_colors.dart';
import 'package:trax_admin_portal/theme/app_font_weight.dart';
import 'package:trax_admin_portal/theme/styled_app_text.dart';
import 'package:trax_admin_portal/widgets/app_primary_button.dart';
import 'package:trax_admin_portal/widgets/app_secondary_button.dart';
import 'package:trax_admin_portal/widgets/dialogs/app_dialog.dart';

/// Confirmation dialog for disabling/enabling a super admin
class DisableSuperAdminDialog extends StatelessWidget {
  final SuperAdminModel superAdmin;
  final VoidCallback onConfirm;

  const DisableSuperAdminDialog({
    super.key,
    required this.superAdmin,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrentlyDisabled = superAdmin.isDisabled;

    return Material(
      type: MaterialType.transparency,
      child: AppDialog(
        header: _buildHeader(context, isCurrentlyDisabled),
        content: _buildContent(context, isCurrentlyDisabled),
        footer: _buildFooter(context, isCurrentlyDisabled),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isCurrentlyDisabled) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: const Color(0xFFE5E7EB)),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCurrentlyDisabled ? Icons.check_circle_outline : Icons.block,
            color: isCurrentlyDisabled
                ? Colors.green.shade400
                : Colors.orange.shade400,
            size: 24,
          ),
          const SizedBox(width: 12),
          AppText.styledHeadingSmall(
            context,
            isCurrentlyDisabled ? 'Enable Super Admin' : 'Disable Super Admin',
            weight: AppFontWeight.semiBold,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isCurrentlyDisabled) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: AppText.styledBodyMedium(
        context,
        isCurrentlyDisabled
            ? 'Are you sure you want to enable ${superAdmin.name}? They will be able to log in again.'
            : 'Are you sure you want to disable ${superAdmin.name}? They will not be able to log in but will remain visible in the system.',
        color: AppColors.secondary,
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isCurrentlyDisabled) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: const Color(0xFFE5E7EB)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AppSecondaryButton(
            text: 'Cancel',
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 12),
          AppPrimaryButton(
            text: isCurrentlyDisabled ? 'Enable' : 'Disable',
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            backgroundColor: isCurrentlyDisabled
                ? Colors.green.shade400
                : Colors.orange.shade400,
          ),
        ],
      ),
    );
  }
}
