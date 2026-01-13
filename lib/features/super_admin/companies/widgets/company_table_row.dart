import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trax_admin_portal/controller/auth_controller/auth_controller.dart';
import 'package:trax_admin_portal/helper/app_padding.dart';
import 'package:trax_admin_portal/helper/app_spacing.dart';
import 'package:trax_admin_portal/models/company_summary.dart';
import 'package:trax_admin_portal/services/firestore_services/firestore_services.dart';
import 'package:trax_admin_portal/theme/app_colors.dart';
import 'package:trax_admin_portal/theme/styled_app_text.dart';
import 'package:trax_admin_portal/utils/enums/sizes.dart';
import 'package:trax_admin_portal/utils/navigation/app_routes.dart';
import 'package:trax_admin_portal/utils/navigation/routes.dart';

/// Table row widget for displaying company information in desktop view
class CompanyTableRow extends StatelessWidget {
  final CompanySummary company;
  final int index;
  final AuthController authController;
  final FirestoreServices firestoreServices;

  const CompanyTableRow({
    super.key,
    required this.company,
    required this.index,
    required this.authController,
    required this.firestoreServices,
  });

  @override
  Widget build(BuildContext context) {
    final isEven = index.isEven;
    
    return InkWell(
      onTap: () => _handleTap(context),
      child: Container(
        padding: AppPadding.symmetric(context,
            horizontalPadding: Sizes.lg, verticalPadding: Sizes.md),
        decoration: BoxDecoration(
          color: isEven ? Colors.white : AppColors.surfaceCard.withOpacity(0.5),
          border: Border(
            bottom: BorderSide(
              color: AppColors.borderSubtle.withOpacity(0.3),
            ),
          ),
        ),
        child: Row(
          children: [
            // Company Name
            _buildCompanyName(context),

            // Salesperson
            _buildSalesperson(context),

            // Total Events
            _buildEventCount(context),

            // Actions
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyName(BuildContext context) {
    return Expanded(
      flex: 3,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: AppText.styledBodyMedium(
                context,
                company.companyName.isNotEmpty
                    ? company.companyName[0].toUpperCase()
                    : '?',
                color: AppColors.primary,
                weight: FontWeight.w600,
              ),
            ),
          ),
          AppSpacing.horizontalSm(context),
          Expanded(
            child: AppText.styledBodyMedium(
              context,
              company.companyName,
              weight: FontWeight.w500,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesperson(BuildContext context) {
    return Expanded(
      flex: 2,
      child: company.salesPersonName != null
          ? Row(
              children: [
                Icon(
                  Icons.person,
                  size: 16,
                  color: AppColors.textMuted,
                ),
                AppSpacing.horizontalXs(context),
                Expanded(
                  child: AppText.styledBodySmall(
                    context,
                    company.salesPersonName!,
                    color: AppColors.secondary,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            )
          : AppText.styledBodySmall(
              context,
              'Not assigned',
              color: AppColors.textMuted,
              style: FontStyle.italic,
            ),
    );
  }

  Widget _buildEventCount(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm(context),
          vertical: AppSpacing.xxs(context),
        ),
        decoration: BoxDecoration(
          color: company.eventCount > 0
              ? AppColors.primary.withOpacity(0.1)
              : AppColors.textMuted.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: AppText.styledBodySmall(
          context,
          company.eventCount.toString(),
          textAlign: TextAlign.center,
          weight: FontWeight.w600,
          color: company.eventCount > 0
              ? AppColors.primary
              : AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return SizedBox(
      width: 80,
      child: IconButton(
        icon: const Icon(Icons.arrow_forward, size: 20),
        onPressed: () => _handleAction(context),
        tooltip: 'View Details',
      ),
    );
  }

  Future<void> _handleTap(BuildContext context) async {
    try {
      final org = await firestoreServices.getOrganisation(company.organisationId);
      authController.setSelectedOrganisation(org);
      if (context.mounted) {
        // Redirect based on user role
        if (authController.isSuperAdmin) {
          pushAndRemoveAllRoute(AppRoute.superAdminEvents, context);
        } else if (authController.isSalesPerson) {
          pushAndRemoveAllRoute(AppRoute.salesPersonEvents, context);
        }
      }
    } catch (e) {
      print('Error fetching organisation: $e');
    }
  }

  Future<void> _handleAction(BuildContext context) async {
    try {
      final org = await firestoreServices.getOrganisation(company.organisationId);
      authController.setSelectedOrganisation(org);
      if (context.mounted) {
        // Redirect based on user role
        if (authController.isSuperAdmin) {
          context.go('/super-admin-events');
        } else if (authController.isSalesPerson) {
          context.go('/sales-person-events');
        }
      }
    } catch (e) {
      print('Error fetching organisation: $e');
    }
  }
}
