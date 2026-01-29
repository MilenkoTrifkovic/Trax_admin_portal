import 'package:flutter/material.dart';
import 'package:trax_admin_portal/features/super_admin/super_admin_management/controllers/super_admin_management_controller.dart';
import 'package:trax_admin_portal/helper/screen_size.dart';
import 'package:trax_admin_portal/models/super_admin_model.dart';
import 'package:trax_admin_portal/theme/app_colors.dart';
import 'package:trax_admin_portal/theme/app_font_weight.dart';
import 'super_admin_list_item.dart';

/// List widget displaying all super admins
class SuperAdminList extends StatelessWidget {
  final List<SuperAdminModel> superAdmins;
  final Function(BuildContext, SuperAdminModel) onEdit;
  final Function(BuildContext, SuperAdminModel) onDisable;
  final Function(BuildContext, SuperAdminModel) onDelete;
  final Function(BuildContext, SuperAdminModel)? onResendEmail;
  final Function(BuildContext, SuperAdminModel)? onResetPassword;
  final SuperAdminManagementController controller;

  const SuperAdminList({
    super.key,
    required this.superAdmins,
    required this.onEdit,
    required this.onDisable,
    required this.onDelete,
    this.onResendEmail,
    this.onResetPassword,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isPhone = ScreenSize.isPhone(context);
    final isTablet = ScreenSize.isTablet(context);

    return Container(
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
        children: [
          // List Header - hidden on phone, simplified on tablet
          if (!isPhone) _buildListHeader(context, isTablet),

          // List Items
          Expanded(
            child: ListView.builder(
              itemCount: superAdmins.length,
              itemBuilder: (context, index) {
                final superAdmin = superAdmins[index];
                return SuperAdminListItem(
                  superAdmin: superAdmin,
                  controller: controller,
                  onEdit: () => onEdit(context, superAdmin),
                  onDisable: () => onDisable(context, superAdmin),
                  onDelete: () => onDelete(context, superAdmin),
                  onResendEmail: onResendEmail != null
                      ? () => onResendEmail!(context, superAdmin)
                      : null,
                  onResetPassword: onResetPassword != null
                      ? () => onResetPassword!(context, superAdmin)
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build the list header with column titles
  Widget _buildListHeader(BuildContext context, bool isTablet) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      child: isTablet ? _buildTabletHeader() : _buildDesktopHeader(),
    );
  }

  /// Tablet header - simplified columns
  Widget _buildTabletHeader() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            'Name / Email',
            style: TextStyle(
              fontSize: 12,
              fontWeight: AppFontWeight.semiBold,
              color: AppColors.textMuted,
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            'Phone',
            style: TextStyle(
              fontSize: 12,
              fontWeight: AppFontWeight.semiBold,
              color: AppColors.textMuted,
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            'Status',
            style: TextStyle(
              fontSize: 12,
              fontWeight: AppFontWeight.semiBold,
              color: AppColors.textMuted,
            ),
          ),
        ),
        const SizedBox(width: 80), // Space for actions
      ],
    );
  }

  /// Desktop header - all columns
  Widget _buildDesktopHeader() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            'Name',
            style: TextStyle(
              fontSize: 12,
              fontWeight: AppFontWeight.semiBold,
              color: AppColors.textMuted,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'Email',
            style: TextStyle(
              fontSize: 12,
              fontWeight: AppFontWeight.semiBold,
              color: AppColors.textMuted,
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            'Phone',
            style: TextStyle(
              fontSize: 12,
              fontWeight: AppFontWeight.semiBold,
              color: AppColors.textMuted,
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            'Status',
            style: TextStyle(
              fontSize: 12,
              fontWeight: AppFontWeight.semiBold,
              color: AppColors.textMuted,
            ),
          ),
        ),
        const SizedBox(width: 120), // Space for actions
      ],
    );
  }
}
