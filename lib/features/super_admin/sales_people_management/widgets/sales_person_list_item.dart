import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trax_admin_portal/models/sales_person_model.dart';
import 'package:trax_admin_portal/theme/app_colors.dart';

/// Single list item representing a sales person
class SalesPersonListItem extends StatelessWidget {
  final SalesPersonModel salesPerson;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  
  const SalesPersonListItem({
    super.key,
    required this.salesPerson,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
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
            child: _buildStatusBadge(),
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
                  onPressed: onEdit,
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: Colors.red.shade400,
                  onPressed: onDelete,
                  tooltip: 'Delete',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build the status badge
  Widget _buildStatusBadge() {
    return Container(
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
}
