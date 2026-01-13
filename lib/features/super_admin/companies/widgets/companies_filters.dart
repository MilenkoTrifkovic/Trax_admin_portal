import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:trax_admin_portal/features/super_admin/companies/controllers/companies_controller.dart';
import 'package:trax_admin_portal/helper/app_padding.dart';
import 'package:trax_admin_portal/helper/app_spacing.dart';
import 'package:trax_admin_portal/utils/enums/sizes.dart';
import 'package:trax_admin_portal/widgets/app_search_input_field.dart';

/// Filter widget for Companies page with search and salesperson filter
class CompaniesFilters extends StatefulWidget {
  final CompaniesController controller;
  final bool isPhone;

  const CompaniesFilters({
    super.key,
    required this.controller,
    required this.isPhone,
  });

  @override
  State<CompaniesFilters> createState() => _CompaniesFiltersState();
}

class _CompaniesFiltersState extends State<CompaniesFilters> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    _searchController.clear();
    widget.controller.clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: widget.isPhone 
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
      child: widget.isPhone 
          ? _buildMobileFilters(context)
          : _buildDesktopFilters(context),
    );
  }

  Widget _buildMobileFilters(BuildContext context) {
    return Column(
      children: [
        // Search field
        AppSearchInputField(
          controller: _searchController,
          hintText: 'Search by company name...',
          onChanged: widget.controller.updateSearchQuery,
        ),
        AppSpacing.verticalSm(context),
        // Salesperson filter
        _buildSalespersonDropdown(context),
        // Clear filters button
        _buildClearFiltersButton(context),
      ],
    );
  }

  Widget _buildDesktopFilters(BuildContext context) {
    return Row(
      children: [
        // Search field
        Expanded(
          flex: 2,
          child: AppSearchInputField(
            controller: _searchController,
            hintText: 'Search by company name...',
            onChanged: widget.controller.updateSearchQuery,
          ),
        ),

        AppSpacing.horizontalMd(context),

        // Salesperson filter
        Expanded(
          child: _buildSalespersonDropdown(context),
        ),

        AppSpacing.horizontalMd(context),

        // Clear filters button
        _buildClearFiltersButton(context),
      ],
    );
  }

  Widget _buildSalespersonDropdown(BuildContext context) {
    return Obx(() {
      final salesPeople = widget.controller.getUniqueSalesPeople();
      return DropdownButtonFormField<String>(
        value: widget.controller.selectedSalesPersonFilter.value,
        decoration: InputDecoration(
          labelText: 'Filter by Salesperson',
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.person_outline),
          suffixIcon: widget.controller.selectedSalesPersonFilter.value != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () =>
                      widget.controller.updateSalesPersonFilter(null),
                )
              : null,
        ),
        items: [
          const DropdownMenuItem(
            value: null,
            child: Text('All Salespeople'),
          ),
          ...salesPeople.map((sp) => DropdownMenuItem(
                value: sp['id'],
                child: Text(sp['name']!),
              )),
        ],
        onChanged: widget.controller.updateSalesPersonFilter,
      );
    });
  }

  Widget _buildClearFiltersButton(BuildContext context) {
    return Obx(() {
      final hasFilters = widget.controller.searchQuery.value.isNotEmpty ||
          widget.controller.selectedSalesPersonFilter.value != null;
      
      if (!hasFilters) {
        return const SizedBox.shrink();
      }

      if (widget.isPhone) {
        return Padding(
          padding: EdgeInsets.only(top: AppSpacing.sm(context)),
          child: SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear Filters'),
            ),
          ),
        );
      }

      return TextButton.icon(
        onPressed: _clearFilters,
        icon: const Icon(Icons.clear_all),
        label: const Text('Clear Filters'),
      );
    });
  }
}
