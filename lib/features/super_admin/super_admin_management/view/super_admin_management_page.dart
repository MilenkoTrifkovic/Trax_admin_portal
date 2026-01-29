import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:trax_admin_portal/features/super_admin/super_admin_management/controllers/super_admin_management_controller.dart';
import 'package:trax_admin_portal/features/super_admin/super_admin_management/widgets/delete_super_admin_dialog.dart';
import 'package:trax_admin_portal/features/super_admin/super_admin_management/widgets/disable_super_admin_dialog.dart';
import 'package:trax_admin_portal/features/super_admin/super_admin_management/widgets/super_admin_empty_state.dart';
import 'package:trax_admin_portal/features/super_admin/super_admin_management/widgets/super_admin_form_dialog.dart';
import 'package:trax_admin_portal/features/super_admin/super_admin_management/widgets/super_admin_list.dart';
import 'package:trax_admin_portal/helper/app_spacing.dart';
import 'package:trax_admin_portal/helper/screen_size.dart';
import 'package:trax_admin_portal/models/super_admin_model.dart';
import 'package:trax_admin_portal/theme/app_colors.dart';
import 'package:trax_admin_portal/theme/styled_app_text.dart';
import 'package:trax_admin_portal/widgets/app_primary_button.dart';
import 'package:trax_admin_portal/widgets/dialogs/dialogs.dart';

/// Main page for managing super admins in the super admin panel
class SuperAdminManagementPage extends StatelessWidget {
  SuperAdminManagementPage({super.key});

  final SuperAdminManagementController controller =
      Get.put(SuperAdminManagementController());

  @override
  Widget build(BuildContext context) {
    final isPhone = ScreenSize.isPhone(context);
    final isTablet = ScreenSize.isTablet(context);
    final pagePadding = isPhone ? 16.0 : (isTablet ? 20.0 : 24.0);

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header - responsive layout
            _buildHeader(context, isPhone),

            SizedBox(height: isPhone ? 20 : 32),

            // Content Area
            Expanded(
              child: Obx(() {
                if (controller.isLoading && controller.superAdmins.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (controller.superAdmins.isEmpty) {
                  return SuperAdminEmptyState(
                    onAddPressed: () => _showAddSuperAdminDialog(context),
                  );
                }

                return SuperAdminList(
                  superAdmins: controller.superAdmins,
                  controller: controller,
                  onEdit: _showEditSuperAdminDialog,
                  onDisable: _showDisableConfirmation,
                  onDelete: _showDeleteConfirmation,
                  onResendEmail: _showResendEmailConfirmation,
                  onResetPassword: _showResetPasswordConfirmation,
                );
              }),
            ),
          ],
        ),
      ),
      // FAB for mobile
      floatingActionButton: isPhone
          ? FloatingActionButton(
              onPressed: () => _showAddSuperAdminDialog(context),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  /// Build responsive header
  Widget _buildHeader(BuildContext context, bool isPhone) {
    if (isPhone) {
      // Mobile: Stack layout
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.styledHeadingMedium(
            context,
            'Super Admins',
            color: AppColors.primary,
          ),
          const SizedBox(height: 4),
          AppText.styledBodySmall(
            context,
            'Manage super admin accounts',
            color: AppColors.textMuted,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }

    // Tablet/Desktop: Row layout
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.styledHeadingLarge(
                context,
                'Super Admin Management',
                color: AppColors.primary,
              ),
              AppSpacing.verticalXs(context),
              AppText.styledBodyMedium(
                context,
                'Manage super admin accounts and their access',
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Add Super Admin Button
        AppPrimaryButton(
          onPressed: () => _showAddSuperAdminDialog(context),
          icon: Icons.add,
          text: 'Add Super Admin',
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
        ),
      ],
    );
  }

  /// Show add super admin dialog
  void _showAddSuperAdminDialog(BuildContext context) {
    print('Opening add super admin dialog...');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SuperAdminFormDialog(
          onSubmit: (superAdmin) async {
            print('Form submitted with: ${superAdmin.name}');
            await controller.addSuperAdmin(superAdmin);
          },
        );
      },
    );
  }

  /// Show edit super admin dialog
  void _showEditSuperAdminDialog(
      BuildContext context, SuperAdminModel superAdmin) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SuperAdminFormDialog(
          superAdmin: superAdmin,
          onSubmit: (updatedSuperAdmin) async {
            await controller.updateSuperAdmin(updatedSuperAdmin);
          },
        );
      },
    );
  }

  /// Show disable confirmation dialog (prevents login but keeps visible)
  void _showDisableConfirmation(
      BuildContext context, SuperAdminModel superAdmin) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return DisableSuperAdminDialog(
          superAdmin: superAdmin,
          onConfirm: () async {
            if (superAdmin.isDisabled) {
              await controller.enableSuperAdmin(superAdmin.email);
            } else {
              await controller.disableSuperAdmin(superAdmin.email);
            }
          },
        );
      },
    );
  }

  /// Show delete confirmation dialog (soft delete - removes from list)
  void _showDeleteConfirmation(
      BuildContext context, SuperAdminModel superAdmin) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return DeleteSuperAdminDialog(
          superAdmin: superAdmin,
          onConfirm: () async {
            await controller.deleteSuperAdmin(superAdmin.email);
          },
        );
      },
    );
  }

  /// Show resend email confirmation dialog
  void _showResendEmailConfirmation(
      BuildContext context, SuperAdminModel superAdmin) {
    Dialogs.showConfirmationDialog(
      context,
      'Send a password setup email to ${superAdmin.name} (${superAdmin.email})?',
      () async {
        await controller.resendPasswordSetupEmail(superAdmin);
      },
      title: 'Resend Password Setup Email',
    );
  }

  /// Show reset password confirmation dialog
  void _showResetPasswordConfirmation(
      BuildContext context, SuperAdminModel superAdmin) {
    Dialogs.showConfirmationDialog(
      context,
      'Send a password reset email to ${superAdmin.name} (${superAdmin.email})? They will receive a link to reset their password.',
      () async {
        await controller.resetPassword(superAdmin.email);
      },
      title: 'Reset Password',
    );
  }
}
