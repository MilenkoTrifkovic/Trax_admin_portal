import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trax_admin_portal/models/sales_person_model.dart';
import 'package:trax_admin_portal/theme/app_colors.dart';
import 'sales_person_list_item.dart';

/// List widget displaying all sales people
class SalesPeopleList extends StatelessWidget {
  final List<SalesPersonModel> salesPeople;
  final Function(BuildContext, SalesPersonModel) onEdit;
  final Function(BuildContext, SalesPersonModel) onDelete;
  
  const SalesPeopleList({
    super.key,
    required this.salesPeople,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
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
          _buildListHeader(),
          
          // List Items
          Expanded(
            child: ListView.builder(
              itemCount: salesPeople.length,
              itemBuilder: (context, index) {
                final salesPerson = salesPeople[index];
                return SalesPersonListItem(
                  salesPerson: salesPerson,
                  onEdit: () => onEdit(context, salesPerson),
                  onDelete: () => onDelete(context, salesPerson),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build the list header with column titles
  Widget _buildListHeader() {
    return Container(
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
    );
  }
}
