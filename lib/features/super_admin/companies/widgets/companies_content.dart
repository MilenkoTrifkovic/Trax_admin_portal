import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:trax_admin_portal/controller/auth_controller/auth_controller.dart';
import 'package:trax_admin_portal/features/super_admin/companies/controllers/companies_controller.dart';
import 'package:trax_admin_portal/features/super_admin/companies/widgets/company_card.dart';
import 'package:trax_admin_portal/features/super_admin/companies/widgets/company_table_row.dart';
import 'package:trax_admin_portal/helper/app_padding.dart';
import 'package:trax_admin_portal/services/firestore_services/firestore_services.dart';
import 'package:trax_admin_portal/theme/app_colors.dart';
import 'package:trax_admin_portal/theme/styled_app_text.dart';
import 'package:trax_admin_portal/utils/enums/sizes.dart';

/// Content area widget displaying companies as either a table or card list
class CompaniesContent extends StatelessWidget {
  final CompaniesController controller;
  final bool isPhone;
  final AuthController authController;
  final FirestoreServices firestoreServices;

  const CompaniesContent({
    super.key,
    required this.controller,
    required this.isPhone,
    required this.authController,
    required this.firestoreServices,
  });

  @override
  Widget build(BuildContext context) {
    return isPhone 
        ? _buildCardList(context) 
        : _buildDataTable(context);
  }

  Widget _buildCardList(BuildContext context) {
    return Obx(() {
      return ListView.builder(
        itemCount: controller.filteredCompanies.length,
        itemBuilder: (context, index) {
          final company = controller.filteredCompanies[index];
          return CompanyCard(
            company: company,
            authController: authController,
            firestoreServices: firestoreServices,
          );
        },
      );
    });
  }

  Widget _buildDataTable(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table Header
          _buildTableHeader(context),

          // Table Rows
          Expanded(
            child: Obx(() {
              return ListView.builder(
                itemCount: controller.filteredCompanies.length,
                itemBuilder: (context, index) {
                  final company = controller.filteredCompanies[index];
                  return CompanyTableRow(
                    company: company,
                    index: index,
                    authController: authController,
                    firestoreServices: firestoreServices,
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(BuildContext context) {
    return Container(
      padding: AppPadding.symmetric(context,
          horizontalPadding: Sizes.lg, verticalPadding: Sizes.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _buildSortableHeader(
              context,
              'Company Name',
              'name',
            ),
          ),
          Expanded(
            flex: 2,
            child: _buildSortableHeader(
              context,
              'Salesperson',
              'salesperson',
            ),
          ),
          Expanded(
            child: _buildSortableHeader(
              context,
              'Total Events',
              'events',
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 80), // Space for actions
        ],
      ),
    );
  }

  Widget _buildSortableHeader(
    BuildContext context,
    String label,
    String column, {
    TextAlign textAlign = TextAlign.start,
  }) {
    return Obx(() {
      final isActive = controller.sortColumn.value == column;
      final isAscending = controller.sortAscending.value;

      return InkWell(
        onTap: () => controller.toggleSort(column),
        child: Row(
          mainAxisAlignment: textAlign == TextAlign.center
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            AppText.styledLabelMedium(
              context,
              label,
              color: isActive ? AppColors.primaryAccent : AppColors.primary,
              weight: FontWeight.w600,
            ),
            const SizedBox(width: 4),
            Icon(
              isActive
                  ? (isAscending ? Icons.arrow_upward : Icons.arrow_downward)
                  : Icons.unfold_more,
              size: 16,
              color: isActive ? AppColors.primaryAccent : AppColors.textMuted,
            ),
          ],
        ),
      );
    });
  }
}
