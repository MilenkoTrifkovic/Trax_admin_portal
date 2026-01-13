import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:trax_admin_portal/features/super_admin/companies/widgets/company_header.dart';
import 'package:trax_admin_portal/features/super_admin/companies/widgets/info_card.dart';
import 'package:trax_admin_portal/features/super_admin/companies/widgets/salesperson_card.dart';
import 'package:trax_admin_portal/features/super_admin/global_controllers/sales_people_global_controller.dart';
import 'package:trax_admin_portal/features/super_admin/super_admin_events/controllers/super_admin_event_list_controller.dart';
import 'package:trax_admin_portal/helper/app_padding.dart';
import 'package:trax_admin_portal/helper/app_spacing.dart';
import 'package:trax_admin_portal/helper/screen_size.dart';
import 'package:trax_admin_portal/models/company_summary.dart';
import 'package:trax_admin_portal/theme/app_colors.dart';
import 'package:trax_admin_portal/utils/enums/sizes.dart';

/// Widget displaying company information header with event count and salesperson
/// 
/// Can be used in two ways:
/// 1. With controller: Pass SuperAdminEventListController and callbacks are automatic
/// 2. Without controller: Pass manual callbacks for assign/remove operations
class CompanyInfoHeader extends StatefulWidget {
  final CompanySummary companySummary;
  final VoidCallback? onBackPressed;
  final Future<void> Function(String organisationId, String salesPersonId)? onAssignSalesPerson;
  final Future<void> Function(String organisationId)? onRemoveSalesPerson;
  final SuperAdminEventListController? controller;

  const CompanyInfoHeader({
    super.key,
    required this.companySummary,
    this.onBackPressed,
    this.onAssignSalesPerson,
    this.onRemoveSalesPerson,
    this.controller,
  });

  @override
  State<CompanyInfoHeader> createState() => _CompanyInfoHeaderState();
}

class _CompanyInfoHeaderState extends State<CompanyInfoHeader> {
  @override
  Widget build(BuildContext context) {
    final salesPeopleController = Get.find<SalesPeopleGlobalController>();
    final isPhone = ScreenSize.isPhone(context);

    return Container(
      padding: isPhone
          ? AppPadding.all(context, paddingType: Sizes.md)
          : AppPadding.all(context, paddingType: Sizes.lg),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          if (widget.onBackPressed != null)
            Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.md(context)),
              child: TextButton.icon(
                onPressed: widget.onBackPressed,
                icon: Icon(Icons.arrow_back, size: isPhone ? 16 : 18),
                label: Text(
                  isPhone ? 'Back' : 'Back to Companies',
                  style: TextStyle(fontSize: isPhone ? 14 : 16),
                ),
              ),
            ),

          // Company header
          CompanyHeader(companyName: widget.companySummary.companyName),

          AppSpacing.verticalMd(context),
          const Divider(),
          AppSpacing.verticalLg(context),

          // Info cards - make both cards match height
          isPhone
              ? _buildMobileInfoCards(context, salesPeopleController)
              : _buildDesktopInfoCards(context, salesPeopleController),
        ],
      ),
    );
  }

  Widget _buildMobileInfoCards(
      BuildContext context, SalesPeopleGlobalController salesPeopleController) {
    return Column(
      children: [
        // Total Events Card
        InfoCard(
          icon: Icons.event,
          label: 'Total Events',
          value: widget.companySummary.eventCount.toString(),
          color: AppColors.primary,
        ),
        AppSpacing.verticalMd(context),
        // Salesperson Card
        SalespersonCard(
          companySummary: widget.companySummary,
          salesPeopleController: salesPeopleController,
          controller: widget.controller,
        ),
      ],
    );
  }

  Widget _buildDesktopInfoCards(
      BuildContext context, SalesPeopleGlobalController salesPeopleController) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Total Events Card
          Expanded(
            child: SizedBox.expand(
              child: InfoCard(
                icon: Icons.event,
                label: 'Total Events',
                value: widget.companySummary.eventCount.toString(),
                color: AppColors.primary,
              ),
            ),
          ),
          AppSpacing.horizontalMd(context),
          // Salesperson Card
          Expanded(
            child: SizedBox.expand(
              child: SalespersonCard(
                companySummary: widget.companySummary,
                salesPeopleController: salesPeopleController,
                controller: widget.controller,
              ),
            ),
          ),
        ],
      ),
    );
  }


}
