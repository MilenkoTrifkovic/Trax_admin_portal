import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:trax_admin_portal/features/super_admin/sales_people_management/controllers/sales_people_management_controller.dart';
import 'package:trax_admin_portal/features/super_admin/sales_people_management/widgets/delete_sales_person_dialog.dart';
import 'package:trax_admin_portal/features/super_admin/sales_people_management/widgets/sales_people_empty_state.dart';
import 'package:trax_admin_portal/features/super_admin/sales_people_management/widgets/sales_people_list.dart';
import 'package:trax_admin_portal/features/super_admin/sales_people_management/widgets/sales_person_form_dialog.dart';
import 'package:trax_admin_portal/helper/app_spacing.dart';
import 'package:trax_admin_portal/models/sales_person_model.dart';
import 'package:trax_admin_portal/theme/app_colors.dart';
import 'package:trax_admin_portal/theme/app_font_weight.dart';
import 'package:trax_admin_portal/widgets/dialogs/dialogs.dart';

/// Main page for managing sales people in the super admin panel
class SalesPeopleManagementPage extends StatelessWidget {
  SalesPeopleManagementPage({super.key});
  
  final SalesPeopleManagementController controller = Get.put(SalesPeopleManagementController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sales People Management',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: AppFontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    AppSpacing.verticalXs(context),
                    Text(
                      'Manage sales people and their assignments',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                // Add Sales Person Button
                ElevatedButton.icon(
                  onPressed: () => _showAddSalesPersonDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Sales Person'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Content Area
            Expanded(
              child: Obx(() {
                if (controller.isLoading && controller.salesPeople.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                
                if (controller.salesPeople.isEmpty) {
                  return SalesPeopleEmptyState(
                    onAddPressed: () => _showAddSalesPersonDialog(context),
                  );
                }
                
                return SalesPeopleList(
                  salesPeople: controller.salesPeople,
                  controller: controller,
                  onEdit: _showEditSalesPersonDialog,
                  onDelete: _showDeleteConfirmation,
                  onResendEmail: _showResendEmailConfirmation,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Show add sales person dialog
  void _showAddSalesPersonDialog(BuildContext context) {
    print('Opening add sales person dialog...');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SalesPersonFormDialog(
          onSubmit: (salesPerson) async {
            print('Form submitted with: ${salesPerson.name}');
            await controller.addSalesPerson(salesPerson);
          },
        );
      },
    );
  }
  
  /// Show edit sales person dialog
  void _showEditSalesPersonDialog(BuildContext context, SalesPersonModel salesPerson) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SalesPersonFormDialog(
          salesPerson: salesPerson,
          onSubmit: (updatedSalesPerson) async {
            await controller.updateSalesPerson(updatedSalesPerson);
          },
        );
      },
    );
  }
  
  /// Show delete confirmation dialog
  void _showDeleteConfirmation(BuildContext context, SalesPersonModel salesPerson) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return DeleteSalesPersonDialog(
          salesPerson: salesPerson,
          onConfirm: () async {
            await controller.deleteSalesPerson(salesPerson.docId);
          },
        );
      },
    );
  }
  
  /// Show resend email confirmation dialog
  void _showResendEmailConfirmation(BuildContext context, SalesPersonModel salesPerson) {
    Dialogs.showConfirmationDialog(
      context,
      'Send a password setup email to ${salesPerson.name} (${salesPerson.email})?',
      () async {
        await controller.resendPasswordSetupEmail(salesPerson);
      },
      title: 'Resend Password Setup Email',
    );
  }
}
