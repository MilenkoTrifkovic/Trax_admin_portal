import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:trax_admin_portal/controller/auth_controller/auth_controller.dart';
import 'package:trax_admin_portal/features/super_admin/controllers/organisation_list_controller.dart';
import 'package:trax_admin_portal/models/organisation.dart';
import 'package:trax_admin_portal/theme/app_colors.dart';
import 'package:trax_admin_portal/utils/enums/sort_type.dart';
import 'package:trax_admin_portal/widgets/app_search_input_field.dart';

/// Widget that displays all organizations for super admin to select from
class OrganisationSelector extends StatelessWidget {
  OrganisationSelector({super.key});
  
  final OrganisationListController controller = Get.put(OrganisationListController());

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Icon(
              Icons.business_rounded,
              size: 64,
              color: AppColors.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Select Organization',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Choose an organization to view and manage its events',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textMuted,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Search and Sort Section
            Obx(() {
              final orgs = authController.organisations;
              
              if (orgs.isEmpty) {
                return const SizedBox.shrink();
              }
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    // Search Field
                    Expanded(
                      child: AppSearchInputField(
                        hintText: 'Search organizations...',
                        onChanged: controller.filterOrganisations,
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Sort Button
                    PopupMenuButton<SortType>(
                      icon: const Icon(Icons.sort),
                      tooltip: 'Sort organizations',
                      onSelected: (sortType) {
                        controller.sortOrganisations(sortType);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: SortType.nameAZ,
                          child: Row(
                            children: [
                              Icon(Icons.sort_by_alpha),
                              SizedBox(width: 8),
                              Text('Name (A-Z)'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: SortType.nameZA,
                          child: Row(
                            children: [
                              Icon(Icons.sort_by_alpha),
                              SizedBox(width: 8),
                              Text('Name (Z-A)'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),

            // Organizations List
            Expanded(
              child: Obx(() {
                final orgs = controller.filteredOrganisations;

                if (authController.organisations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 48,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No organizations found',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppColors.textMuted,
                              ),
                        ),
                      ],
                    ),
                  );
                }

                if (orgs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No organizations match your search',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppColors.textMuted,
                              ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: orgs.length,
                  itemBuilder: (context, index) {
                    final org = orgs[index];
                    return _OrganisationCard(
                      organisation: org,
                      onTap: () {
                        authController.setSelectedOrganisation(org);
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrganisationCard extends StatelessWidget {
  final Organisation organisation;
  final VoidCallback onTap;

  const _OrganisationCard({
    required this.organisation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Organization Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.business,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // Organization Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      organisation.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${organisation.organisationId ?? "N/A"}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                  ],
                ),
              ),

              // Arrow Icon
              Icon(
                Icons.arrow_forward_ios,
                color: AppColors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
