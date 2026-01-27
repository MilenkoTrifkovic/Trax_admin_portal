import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:trax_admin_portal/controller/global_controllers/payments_controller.dart';
import 'package:trax_admin_portal/features/super_admin/companies/widgets/assign_free_credits_dialog.dart';
import 'package:trax_admin_portal/features/super_admin/companies/widgets/company_header.dart';
import 'package:trax_admin_portal/features/super_admin/companies/widgets/events_stats_card.dart';
import 'package:trax_admin_portal/features/super_admin/companies/widgets/salesperson_card.dart';
import 'package:trax_admin_portal/features/super_admin/companies/widgets/transaction_history/transaction_history_widget.dart';
import 'package:trax_admin_portal/features/super_admin/global_controllers/sales_people_global_controller.dart';
import 'package:trax_admin_portal/features/super_admin/super_admin_events/controllers/super_admin_event_list_controller.dart';
import 'package:trax_admin_portal/helper/app_padding.dart';
import 'package:trax_admin_portal/helper/app_spacing.dart';
import 'package:trax_admin_portal/helper/screen_size.dart';
import 'package:trax_admin_portal/models/company_summary.dart';
import 'package:trax_admin_portal/utils/enums/sizes.dart';

/// Widget displaying company information header with event count and salesperson
///
/// Can be used in two ways:
/// 1. With controller: Pass SuperAdminEventListController and callbacks are automatic
/// 2. Without controller: Pass manual callbacks for assign/remove operations
class CompanyInfoHeader extends StatefulWidget {
  final CompanySummary companySummary;
  final VoidCallback? onBackPressed;
  final Future<void> Function(String organisationId, String salesPersonId)?
      onAssignSalesPerson;
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
  bool _isTransactionHistoryExpanded = false;

  void _showAssignFreeCreditsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AssignFreeCreditsDialog(
        companyName: widget.companySummary.companyName,
        organisationId: widget.companySummary.organisationId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final salesPeopleController = Get.find<SalesPeopleGlobalController>();
    final paymentsController = Get.find<PaymentsController>();
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
      child: Obx(() {
        // Get payment data for this organisation (reactive)
        final transactions = paymentsController.getPaymentsForOrganisation(
          widget.companySummary.organisationId,
        );
        final purchasedEvents = paymentsController.getPurchasedEventsForOrganisation(
          widget.companySummary.organisationId,
        );
        final giftedEvents = paymentsController.getGiftedEventsForOrganisation(
          widget.companySummary.organisationId,
        );
        final totalPaidEvents = purchasedEvents + giftedEvents;
        final totalEvents = widget.companySummary.eventCount;
        final remainingEvents = totalPaidEvents - totalEvents;

        return Column(
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

            // Info cards - Events stats and Salesperson (stacked vertically on all screen sizes)
            _buildInfoCards(
              context,
              salesPeopleController,
              totalPaidEvents,
              purchasedEvents,
              giftedEvents,
              remainingEvents,
            ),

            AppSpacing.verticalLg(context),
            // Transaction History
            TransactionHistoryWidget(
              transactions: transactions,
              isExpanded: _isTransactionHistoryExpanded,
              onToggleExpand: () {
                setState(() {
                  _isTransactionHistoryExpanded = !_isTransactionHistoryExpanded;
                });
              },
              onGiveFreeEvents: () => _showAssignFreeCreditsDialog(context),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildInfoCards(
    BuildContext context,
    SalesPeopleGlobalController salesPeopleController,
    int totalEvents,
    int purchasedEvents,
    int giftedEvents,
    int remainingEvents,
  ) {
    return Column(
      children: [
        // Events Stats Card
        EventsStatsCard(
          totalEvents: totalEvents,
          purchasedEvents: purchasedEvents,
          giftedEvents: giftedEvents,
          remainingEvents: remainingEvents,
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
}
