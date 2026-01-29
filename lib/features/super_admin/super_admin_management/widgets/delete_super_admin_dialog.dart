import 'package:flutter/material.dart';
import 'package:trax_admin_portal/models/super_admin_model.dart';
import 'package:trax_admin_portal/theme/app_colors.dart';
import 'package:trax_admin_portal/theme/app_font_weight.dart';
import 'package:trax_admin_portal/theme/styled_app_text.dart';
import 'package:trax_admin_portal/widgets/app_primary_button.dart';
import 'package:trax_admin_portal/widgets/app_secondary_button.dart';
import 'package:trax_admin_portal/widgets/dialogs/app_dialog.dart';

/// Confirmation dialog for deleting a super admin
/// This performs a soft delete in Firestore (sets isDeleted flag for record keeping)
/// and completely removes the user from Firebase Authentication
class DeleteSuperAdminDialog extends StatelessWidget {
  final SuperAdminModel superAdmin;
  final VoidCallback onConfirm;

  const DeleteSuperAdminDialog({
    super.key,
    required this.superAdmin,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: AppDialog(
        header: _buildHeader(context),
        content: _buildContent(context),
        footer: _buildFooter(context),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
            Icons.delete_outline,
            color: Colors.red.shade400,
            size: 24,
          ),
          const SizedBox(width: 12),
          AppText.styledHeadingSmall(
            context,
            'Delete Super Admin',
            weight: AppFontWeight.semiBold,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: AppText.styledBodyMedium(
        context,
        'Are you sure you want to delete ${superAdmin.name}? This action will remove them from the system.',
        color: AppColors.secondary,
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
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
            text: 'Delete',
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            backgroundColor: Colors.red,
          ),
        ],
      ),
    );
  }
}
