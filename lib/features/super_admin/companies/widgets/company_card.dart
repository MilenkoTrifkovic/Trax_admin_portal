import 'package:flutter/material.dart';
import 'package:trax_admin_portal/controller/auth_controller/auth_controller.dart';
import 'package:trax_admin_portal/controller/global_controllers/payments_controller.dart';
import 'package:trax_admin_portal/helper/app_padding.dart';
import 'package:trax_admin_portal/helper/app_spacing.dart';
import 'package:trax_admin_portal/models/company_summary.dart';
import 'package:trax_admin_portal/services/firestore_services/firestore_services.dart';
import 'package:trax_admin_portal/theme/app_colors.dart';
import 'package:trax_admin_portal/theme/styled_app_text.dart';
import 'package:trax_admin_portal/utils/enums/sizes.dart';
import 'package:trax_admin_portal/utils/navigation/app_routes.dart';
import 'package:trax_admin_portal/utils/navigation/routes.dart';

/// Card widget for displaying company information in mobile view
class CompanyCard extends StatelessWidget {
  final CompanySummary company;
  final AuthController authController;
  final FirestoreServices firestoreServices;
  final PaymentsController paymentsController;

  const CompanyCard({
    super.key,
    required this.company,
    required this.authController,
    required this.firestoreServices,
    required this.paymentsController,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: AppSpacing.sm(context)),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _handleTap(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: AppPadding.all(context, paddingType: Sizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Company name with avatar
              _buildHeader(context),
              AppSpacing.verticalMd(context),
              const Divider(height: 1),
              AppSpacing.verticalSm(context),
              // Salesperson info
              _buildSalespersonInfo(context),
              AppSpacing.verticalXs(context),
              // Event count
              _buildEventCount(context),
              AppSpacing.verticalXs(context),
              // Purchased and Remaining events row
              _buildPurchasedAndRemainingRow(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: AppText.styledHeadingSmall(
              context,
              company.companyName.isNotEmpty
                  ? company.companyName[0].toUpperCase()
                  : '?',
              color: AppColors.primary,
              weight: FontWeight.w700,
            ),
          ),
        ),
        AppSpacing.horizontalSm(context),
        Expanded(
          child: AppText.styledBodyMedium(
            context,
            company.companyName,
            color: AppColors.primary,
            weight: FontWeight.w600,
          ),
        ),
        Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.textMuted,
        ),
      ],
    );
  }

  Widget _buildSalespersonInfo(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.person_outline,
          size: 18,
          color: AppColors.textMuted,
        ),
        AppSpacing.horizontalXs(context),
        Expanded(
          child: AppText.styledMetaSmall(
            context,
            'Salesperson',
            color: AppColors.textMuted,
            weight: FontWeight.w500,
          ),
        ),
        Expanded(
          flex: 2,
          child: AppText.styledBodySmall(
            context,
            company.salesPersonName ?? 'Not assigned',
            color: company.salesPersonName != null
                ? AppColors.secondary
                : AppColors.textMuted,
            style: company.salesPersonName != null
                ? FontStyle.normal
                : FontStyle.italic,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildEventCount(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.event,
          size: 18,
          color: AppColors.textMuted,
        ),
        AppSpacing.horizontalXs(context),
        Expanded(
          child: AppText.styledMetaSmall(
            context,
            'Total Events',
            color: AppColors.textMuted,
            weight: FontWeight.w500,
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.sm(context),
            vertical: AppSpacing.xxxs(context),
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
            color: company.eventCount > 0
                ? AppColors.primary
                : AppColors.textMuted,
            weight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPurchasedAndRemainingRow(BuildContext context) {
    final purchasedEvents = paymentsController
        .getTotalEventsForOrganisation(company.organisationId);
    final usedEvents = company.eventCount;
    final remainingEvents = purchasedEvents - usedEvents;

    // Determine remaining color
    Color remainingBgColor;
    Color remainingTextColor;
    if (remainingEvents > 10) {
      remainingBgColor = AppColors.success.withOpacity(0.1);
      remainingTextColor = AppColors.success;
    } else if (remainingEvents > 0) {
      remainingBgColor = Colors.orange.withOpacity(0.1);
      remainingTextColor = Colors.orange;
    } else if (remainingEvents == 0) {
      remainingBgColor = AppColors.textMuted.withOpacity(0.1);
      remainingTextColor = AppColors.textMuted;
    } else {
      remainingBgColor = AppColors.inputError.withOpacity(0.1);
      remainingTextColor = AppColors.inputError;
    }

    return Row(
      children: [
        // Purchased Events
        Expanded(
          child: Row(
            children: [
              Icon(
                Icons.shopping_cart_outlined,
                size: 18,
                color: AppColors.textMuted,
              ),
              AppSpacing.horizontalXs(context),
              Expanded(
                child: AppText.styledMetaSmall(
                  context,
                  'Purchased',
                  color: AppColors.textMuted,
                  weight: FontWeight.w500,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm(context),
                  vertical: AppSpacing.xxxs(context),
                ),
                decoration: BoxDecoration(
                  color: purchasedEvents > 0
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.textMuted.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AppText.styledBodySmall(
                  context,
                  purchasedEvents.toString(),
                  color: purchasedEvents > 0
                      ? AppColors.success
                      : AppColors.textMuted,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        AppSpacing.horizontalMd(context),
        // Remaining Events
        Expanded(
          child: Row(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 18,
                color: AppColors.textMuted,
              ),
              AppSpacing.horizontalXs(context),
              Expanded(
                child: AppText.styledMetaSmall(
                  context,
                  'Remaining',
                  color: AppColors.textMuted,
                  weight: FontWeight.w500,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm(context),
                  vertical: AppSpacing.xxxs(context),
                ),
                decoration: BoxDecoration(
                  color: remainingBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AppText.styledBodySmall(
                  context,
                  remainingEvents.toString(),
                  color: remainingTextColor,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleTap(BuildContext context) async {
    try {
      final org =
          await firestoreServices.getOrganisation(company.organisationId);
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
}
