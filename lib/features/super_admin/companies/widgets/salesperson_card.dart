import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:trax_admin_portal/features/super_admin/global_controllers/sales_people_global_controller.dart';
import 'package:trax_admin_portal/features/super_admin/super_admin_events/controllers/super_admin_event_list_controller.dart';
import 'package:trax_admin_portal/helper/app_padding.dart';
import 'package:trax_admin_portal/helper/app_spacing.dart';
import 'package:trax_admin_portal/helper/screen_size.dart';
import 'package:trax_admin_portal/models/company_summary.dart';
import 'package:trax_admin_portal/theme/app_colors.dart';
import 'package:trax_admin_portal/theme/styled_app_text.dart';
import 'package:trax_admin_portal/utils/enums/sizes.dart';
import 'package:trax_admin_portal/widgets/app_dropdown_menu.dart';

/// Widget displaying salesperson information with edit capabilities
class SalespersonCard extends StatelessWidget {
  final CompanySummary companySummary;
  final SalesPeopleGlobalController salesPeopleController;
  final SuperAdminEventListController? controller;

  const SalespersonCard({
    super.key,
    required this.companySummary,
    required this.salesPeopleController,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isPhone = ScreenSize.isPhone(context);
    final hasSalesperson = companySummary.salesPersonName != null;

    // If there's no controller, render static content
    if (controller == null) {
      return _buildCardContent(
        context: context,
        isPhone: isPhone,
        hasSalesperson: hasSalesperson,
        isLoading: false,
        isEditing: false,
        selectedSalesPersonId: null,
      );
    }

    // If there's a controller, wrap reactive parts in Obx
    return Obx(() {
      final isLoading = controller!.isAssigningSalesPerson.value;
      final isEditing = controller!.isEditingSalesPerson.value;
      final selectedSalesPersonId = controller!.selectedSalesPersonId.value;

      return _buildCardContent(
        context: context,
        isPhone: isPhone,
        hasSalesperson: hasSalesperson,
        isLoading: isLoading,
        isEditing: isEditing,
        selectedSalesPersonId: selectedSalesPersonId,
      );
    });
  }

  Widget _buildCardContent({
    required BuildContext context,
    required bool isPhone,
    required bool hasSalesperson,
    required bool isLoading,
    required bool isEditing,
    required String? selectedSalesPersonId,
  }) {
    // Check if editing is allowed (only for super admins)
    final canEdit = controller?.canEditSalesPerson ?? false;

    return Container(
      padding: isPhone
          ? AppPadding.all(context, paddingType: Sizes.md)
          : AppPadding.all(context, paddingType: Sizes.lg),
      decoration: BoxDecoration(
        color: hasSalesperson
            ? AppColors.success.withOpacity(0.05)
            : AppColors.textMuted.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasSalesperson
              ? AppColors.success.withOpacity(0.2)
              : AppColors.textMuted.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isPhone ? 10 : 12),
                decoration: BoxDecoration(
                  color: hasSalesperson
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.textMuted.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  hasSalesperson ? Icons.person : Icons.person_outline,
                  color: hasSalesperson ? AppColors.success : AppColors.textMuted,
                  size: isPhone ? 20 : 24,
                ),
              ),
              SizedBox(width: AppSpacing.sm(context)),
              Expanded(
                child: AppText.styledMetaSmall(
                  context,
                  'Salesperson',
                  color: AppColors.textMuted,
                  weight: FontWeight.w500,
                ),
              ),
              // Edit/Change button - only show if user has edit permission
              if (!isEditing && !isLoading && controller != null && canEdit)
                IconButton(
                  icon: Icon(
                    hasSalesperson ? Icons.edit : Icons.add,
                    size: 18,
                  ),
                  tooltip: hasSalesperson ? 'Change Salesperson' : 'Assign Salesperson',
                  onPressed: () {
                    controller?.startEditingSalesPerson(
                      companySummary.salesPersonId,
                    );
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              if (isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          
          const SizedBox(height: 12),

          // Content area - either display mode or edit mode
          if (isEditing) ...[
            // Edit mode - dropdown
            Obx(() {
              final salesPeople = salesPeopleController.activeSalesPeople;
              
              // Build dropdown items
              final List<DropdownMenuItem<String>> items = [
                const DropdownMenuItem(
                  value: 'none',
                  child: Text('-- Remove Assignment --'),
                ),
                ...salesPeople.map((sp) {
                  return DropdownMenuItem(
                    value: sp.userId,
                    child: Text(sp.name),
                  );
                }),
              ];

              return Column(
                children: [
                  AppDropdownMenu<String>(
                    label: 'Select Salesperson',
                    value: selectedSalesPersonId,
                    items: items,
                    onChanged: (value) {
                      controller?.updateSelectedSalesPerson(value);
                    },
                    hintText: 'Choose a salesperson',
                    width: double.infinity,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: isLoading 
                            ? null 
                            : () => controller?.cancelEditingSalesPerson(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () => controller?.handleSalesPersonChange(
                                  companySummary.organisationId,
                                  selectedSalesPersonId,
                                ),
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              );
            }),
          ] else ...[
            // Display mode - show current salesperson or "Not assigned"
            if (hasSalesperson) ...[
              AppText.styledBodyMedium(
                context,
                companySummary.salesPersonName!,
                color: AppColors.primary,
                overflow: TextOverflow.ellipsis,
              ),
              if (companySummary.salesPersonEmail != null) ...[
                AppSpacing.verticalXxxs(context),
                AppText.styledMetaSmall(
                  context,
                  companySummary.salesPersonEmail!,
                  color: AppColors.textMuted,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ] else ...[
              Text(
                'Not assigned',
                style: TextStyle(
                  fontSize: isPhone ? 14 : 16,
                  color: AppColors.textMuted,
                  fontStyle: FontStyle.italic,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ],
      ),
    );
  }
}
