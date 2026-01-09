import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trax_admin_portal/features/super_admin/sales_people_management/controllers/sales_people_management_controller.dart';
import 'package:trax_admin_portal/features/super_admin/sales_people_management/widgets/sales_person_form_dialog.dart';
import 'package:trax_admin_portal/models/sales_person_model.dart';
import 'package:trax_admin_portal/theme/app_colors.dart';

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
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage sales people and their assignments',
                      style: GoogleFonts.poppins(
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
                if (controller.isLoading.value && controller.salesPeople.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                
                if (controller.salesPeople.isEmpty) {
                  return _buildEmptyState(context);
                }
                
                return _buildSalesPeopleList(context);
              }),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Empty state when no sales people exist
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 24),
            Text(
              'No Sales People Yet',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start by adding your first sales person',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddSalesPersonDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Your First Sales Person'),
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
      ),
    );
  }
  
  /// Build the list of sales people
  Widget _buildSalesPeopleList(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
          // List Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: const Color(0xFFE5E7EB)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Name',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Email',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Location',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Status',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 80), // Space for actions
              ],
            ),
          ),
          
          // List Items
          Expanded(
            child: ListView.builder(
              itemCount: controller.salesPeople.length,
              itemBuilder: (context, index) {
                final salesPerson = controller.salesPeople[index];
                return _buildSalesPersonRow(context, salesPerson);
              },
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build a single sales person row
  Widget _buildSalesPersonRow(BuildContext context, SalesPersonModel salesPerson) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: const Color(0xFFE5E7EB).withOpacity(0.5)),
        ),
      ),
      child: Row(
        children: [
          // Name
          Expanded(
            flex: 2,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    salesPerson.name.isNotEmpty 
                        ? salesPerson.name[0].toUpperCase() 
                        : '?',
                    style: GoogleFonts.poppins(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    salesPerson.name,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF111827),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          
          // Email
          Expanded(
            flex: 2,
            child: Text(
              salesPerson.email,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF6B7280),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // Location
          Expanded(
            flex: 2,
            child: Text(
              _formatLocation(salesPerson),
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF6B7280),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // Status
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: salesPerson.isDisabled 
                    ? Colors.red.withOpacity(0.1)
                    : salesPerson.isActive
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                salesPerson.isDisabled 
                    ? 'Disabled' 
                    : salesPerson.isActive 
                        ? 'Active' 
                        : 'Inactive',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: salesPerson.isDisabled 
                      ? Colors.red.shade700
                      : salesPerson.isActive
                          ? Colors.green.shade700
                          : Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          
          // Actions
          SizedBox(
            width: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  color: AppColors.primary,
                  onPressed: () => _showEditSalesPersonDialog(context, salesPerson),
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: Colors.red.shade400,
                  onPressed: () {
                    _showDeleteConfirmation(context, salesPerson);
                  },
                  tooltip: 'Delete',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Format location string from address components
  String _formatLocation(SalesPersonModel salesPerson) {
    final parts = <String>[];
    if (salesPerson.city != null && salesPerson.city!.isNotEmpty) {
      parts.add(salesPerson.city!);
    }
    if (salesPerson.state != null && salesPerson.state!.isNotEmpty) {
      parts.add(salesPerson.state!);
    }
    if (salesPerson.country != null && salesPerson.country!.isNotEmpty) {
      parts.add(salesPerson.country!);
    }
    
    return parts.isNotEmpty ? parts.join(', ') : 'No location';
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
        return AlertDialog(
          title: Text(
            'Delete Sales Person',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Text(
            'Are you sure you want to delete ${salesPerson.name}? This action will mark them as disabled.',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: AppColors.textMuted),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await controller.deleteSalesPerson(salesPerson.docId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Delete',
                style: GoogleFonts.poppins(),
              ),
            ),
          ],
        );
      },
    );
  }
}
