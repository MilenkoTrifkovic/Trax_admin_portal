import 'package:flutter/material.dart';
import 'package:trax_admin_portal/features/super_admin/sales_people_management/controllers/sales_people_management_controller.dart';
import 'package:trax_admin_portal/helper/screen_size.dart';
import 'package:trax_admin_portal/models/user_model.dart';
import 'package:trax_admin_portal/theme/app_colors.dart';
import 'package:trax_admin_portal/theme/app_font_weight.dart';
import 'sales_person_list_item.dart';

/// List widget displaying all sales people
class SalesPeopleList extends StatelessWidget {
  final List<UserModel> salesPeople;
  final Function(BuildContext, UserModel) onEdit;
  final Function(BuildContext, UserModel) onDelete;
  final Function(BuildContext, UserModel)? onResendEmail;
  final SalesPeopleManagementController controller;
  
  const SalesPeopleList({
    super.key,
    required this.salesPeople,
    required this.onEdit,
    required this.onDelete,
    this.onResendEmail,
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
              itemCount: salesPeople.length,
              itemBuilder: (context, index) {
                final salesPerson = salesPeople[index];
                return SalesPersonListItem(
                  salesPerson: salesPerson,
                  controller: controller,
                  onEdit: () => onEdit(context, salesPerson),
                  onDelete: () => onDelete(context, salesPerson),
                  onResendEmail: onResendEmail != null 
                      ? () => onResendEmail!(context, salesPerson)
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
            'Ref Code',
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
            'Reference Code',
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
            'Location',
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
}
