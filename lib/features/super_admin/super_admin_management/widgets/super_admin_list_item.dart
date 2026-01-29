import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trax_admin_portal/features/super_admin/super_admin_management/controllers/super_admin_management_controller.dart';
import 'package:trax_admin_portal/helper/screen_size.dart';
import 'package:trax_admin_portal/models/super_admin_model.dart';
import 'package:trax_admin_portal/theme/app_colors.dart';
import 'package:trax_admin_portal/theme/app_font_weight.dart';
import 'package:trax_admin_portal/theme/styled_app_text.dart';
import 'package:trax_admin_portal/widgets/app_secondary_button.dart';

/// Single list item representing a super admin
class SuperAdminListItem extends StatelessWidget {
  final SuperAdminModel superAdmin;
  final SuperAdminManagementController controller;
  final VoidCallback onEdit;
  final VoidCallback onDisable;
  final VoidCallback onDelete;
  final VoidCallback? onResendEmail;
  final VoidCallback? onResetPassword;

  const SuperAdminListItem({
    super.key,
    required this.superAdmin,
    required this.controller,
    required this.onEdit,
    required this.onDisable,
    required this.onDelete,
    this.onResendEmail,
    this.onResetPassword,
  });

  @override
  Widget build(BuildContext context) {
    final isPhone = ScreenSize.isPhone(context);
    final isTablet = ScreenSize.isTablet(context);

    return Container(
      padding: EdgeInsets.all(isPhone ? 12 : 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.borderSubtle.withOpacity(0.5)),
        ),
      ),
      child: isPhone
          ? _buildMobileLayout(context)
          : isTablet
              ? _buildTabletLayout(context)
              : _buildDesktopLayout(context),
    );
  }

  /// Mobile layout - card style with stacked information
  Widget _buildMobileLayout(BuildContext context) {
    final isCurrentUser = controller.isCurrentUser(superAdmin);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top row: Avatar, Name, Status
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Icon(
                Icons.admin_panel_settings,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.styledBodyMedium(
                    context,
                    superAdmin.name,
                    weight: AppFontWeight.semiBold,
                    color: AppColors.primary,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // Email with copy button
                  Row(
                    children: [
                      Expanded(
                        child: AppText.styledBodySmall(
                          context,
                          superAdmin.email,
                          color: AppColors.secondary,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(
                              ClipboardData(text: superAdmin.email));
                          controller.copyEmail(superAdmin.email);
                        },
                        child: Icon(
                          Icons.copy,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildStatusBadge(),
          ],
        ),

        if (superAdmin.phoneNumber != null) ...[
          const SizedBox(height: 8),
          _buildInfoChip(Icons.phone_outlined, superAdmin.phoneNumber!),
        ],

        const SizedBox(height: 12),

        // Actions row
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildActionButton(
              onEdit,
              Icons.edit_outlined,
              'Edit',
              AppColors.primary,
            ),
            // Hide disable button for current user
            if (!isCurrentUser)
              _buildActionButton(
                onDisable,
                superAdmin.isDisabled
                    ? Icons.check_circle_outline
                    : Icons.block,
                superAdmin.isDisabled ? 'Enable' : 'Disable',
                superAdmin.isDisabled
                    ? Colors.green.shade400
                    : Colors.orange.shade400,
              ),
            // Hide delete button for current user
            if (!isCurrentUser)
              _buildActionButton(
                onDelete,
                Icons.delete_outline,
                'Delete',
                Colors.red.shade400,
              ),
            // Hide resend email button for current user and disabled admins
            if (onResendEmail != null &&
                !isCurrentUser &&
                !superAdmin.isDisabled)
              _buildActionButton(
                onResendEmail!,
                Icons.email_outlined,
                'Resend',
                AppColors.secondary,
              ),
            // Hide reset password button for disabled admins
            if (onResetPassword != null && !superAdmin.isDisabled)
              _buildActionButton(
                onResetPassword!,
                Icons.lock_reset,
                'Reset Pwd',
                Colors.purple.shade400,
              ),
          ],
        ),
      ],
    );
  }

  /// Build action button for mobile
  Widget _buildActionButton(
    VoidCallback onPressed,
    IconData icon,
    String label,
    Color color,
  ) {
    return AppSecondaryButton(
      onPressed: onPressed,
      icon: icon,
      text: label,
      textColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      height: 36,
    );
  }

  /// Tablet layout - simplified row with key info
  Widget _buildTabletLayout(BuildContext context) {
    return Row(
      children: [
        // Avatar and Name
        Expanded(
          flex: 2,
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Icon(
                  Icons.admin_panel_settings,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.styledBodyMedium(
                      context,
                      superAdmin.name,
                      weight: AppFontWeight.medium,
                      color: AppColors.primary,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    AppText.styledBodySmall(
                      context,
                      superAdmin.email,
                      color: AppColors.secondary,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Phone
        Expanded(
          flex: 1,
          child: AppText.styledBodySmall(
            context,
            superAdmin.phoneNumber ?? '-',
            color: AppColors.secondary,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Status
        Expanded(
          flex: 1,
          child: _buildStatusBadge(),
        ),

        // Actions
        SizedBox(
          width: 80,
          child: _buildActionsMenu(context),
        ),
      ],
    );
  }

  /// Desktop layout - full row with all information
  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // Name
        Expanded(
          flex: 2,
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Icon(
                  Icons.admin_panel_settings,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppText.styledBodyMedium(
                  context,
                  superAdmin.name,
                  weight: AppFontWeight.medium,
                  color: AppColors.primary,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        // Email with copy button
        Expanded(
          flex: 2,
          child: Row(
            children: [
              Expanded(
                child: AppText.styledBodySmall(
                  context,
                  superAdmin.email,
                  color: AppColors.secondary,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: superAdmin.email));
                  controller.copyEmail(superAdmin.email);
                },
                icon: Icon(
                  Icons.copy,
                  size: 16,
                  color: AppColors.textMuted,
                ),
                tooltip: 'Copy email',
              ),
            ],
          ),
        ),

        // Phone
        Expanded(
          flex: 1,
          child: AppText.styledBodySmall(
            context,
            superAdmin.phoneNumber ?? '-',
            color: AppColors.secondary,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Status
        Expanded(
          flex: 1,
          child: _buildStatusBadge(),
        ),

        // Actions
        SizedBox(
          width: 120,
          child: _buildActionsMenu(context),
        ),
      ],
    );
  }

  /// Build status badge
  Widget _buildStatusBadge() {
    String status;
    Color bgColor;
    Color borderColor;
    Color textColor;

    if (superAdmin.isDeleted) {
      status = 'Deleted';
      bgColor = Colors.grey.shade100;
      borderColor = Colors.grey.shade300;
      textColor = Colors.grey.shade700;
    } else if (superAdmin.isDisabled) {
      status = 'Disabled';
      bgColor = Colors.orange.shade50;
      borderColor = Colors.orange.shade200;
      textColor = Colors.orange.shade700;
    } else {
      status = 'Active';
      bgColor = Colors.green.shade50;
      borderColor = Colors.green.shade200;
      textColor = Colors.green.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: AppText.styledMetaSmall(
        null,
        status,
        weight: AppFontWeight.medium,
        color: textColor,
      ),
    );
  }

  /// Build info chip for mobile layout
  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Expanded(
            child: AppText.styledBodySmall(
              null,
              text,
              color: AppColors.secondary,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Build actions menu (three dots)
  Widget _buildActionsMenu(BuildContext context) {
    final isCurrentUser = controller.isCurrentUser(superAdmin);

    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEdit();
            break;
          case 'disable':
            onDisable();
            break;
          case 'delete':
            onDelete();
            break;
          case 'resend':
            onResendEmail?.call();
            break;
          case 'reset_password':
            onResetPassword?.call();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: 12),
              const Text('Edit'),
            ],
          ),
        ),
        // Hide resend email for current user and disabled admins
        if (onResendEmail != null && !isCurrentUser && !superAdmin.isDisabled)
          PopupMenuItem(
            value: 'resend',
            child: Row(
              children: [
                Icon(Icons.email_outlined,
                    size: 18, color: AppColors.secondary),
                const SizedBox(width: 12),
                const Text('Resend Email'),
              ],
            ),
          ),
        // Hide reset password for disabled admins
        if (onResetPassword != null && !superAdmin.isDisabled)
          PopupMenuItem(
            value: 'reset_password',
            child: Row(
              children: [
                Icon(Icons.lock_reset, size: 18, color: Colors.purple.shade400),
                const SizedBox(width: 12),
                const Text('Reset Password'),
              ],
            ),
          ),
        // Hide disable for current user
        if (!isCurrentUser)
          PopupMenuItem(
            value: 'disable',
            child: Row(
              children: [
                Icon(
                  superAdmin.isDisabled
                      ? Icons.check_circle_outline
                      : Icons.block,
                  size: 18,
                  color: superAdmin.isDisabled
                      ? Colors.green.shade400
                      : Colors.orange.shade400,
                ),
                const SizedBox(width: 12),
                Text(superAdmin.isDisabled ? 'Enable' : 'Disable'),
              ],
            ),
          ),
        // Hide delete for current user
        if (!isCurrentUser)
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline,
                    size: 18, color: Colors.red.shade400),
                const SizedBox(width: 12),
                const Text('Delete'),
              ],
            ),
          ),
      ],
      icon: Icon(Icons.more_vert, color: AppColors.textMuted),
    );
  }
}
