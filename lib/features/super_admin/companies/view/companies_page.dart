import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:trax_admin_portal/controller/auth_controller/auth_controller.dart';
import 'package:trax_admin_portal/features/super_admin/companies/controllers/companies_controller.dart';
import 'package:trax_admin_portal/features/super_admin/companies/widgets/companies_content.dart';
import 'package:trax_admin_portal/features/super_admin/companies/widgets/companies_empty_state.dart';
import 'package:trax_admin_portal/features/super_admin/companies/widgets/companies_filters.dart';
import 'package:trax_admin_portal/features/super_admin/companies/widgets/companies_header.dart';
import 'package:trax_admin_portal/helper/app_padding.dart';
import 'package:trax_admin_portal/helper/app_spacing.dart';
import 'package:trax_admin_portal/helper/screen_size.dart';
import 'package:trax_admin_portal/services/firestore_services/firestore_services.dart';
import 'package:trax_admin_portal/theme/app_colors.dart';
import 'package:trax_admin_portal/utils/enums/sizes.dart';

/// Main page displaying companies in a data table format
class CompaniesPage extends StatefulWidget {
  const CompaniesPage({super.key});

  @override
  State<CompaniesPage> createState() => _CompaniesPageState();
}

class _CompaniesPageState extends State<CompaniesPage> {
  late final CompaniesController controller;
  late final AuthController authController;
  late final FirestoreServices firestoreServices;

  @override
  void initState() {
    super.initState();
    controller = Get.put(CompaniesController());
    authController = Get.find<AuthController>();
    firestoreServices = FirestoreServices();
  }

  @override
  void dispose() {
    Get.delete<CompaniesController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = ScreenSize.isPhone(context);

    return Scaffold(
      backgroundColor: AppColors.surfaceCard,
      body: Padding(
        padding: AppPadding.all(context, paddingType: Sizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            CompaniesHeader(
              controller: controller,
              isPhone: isPhone,
            ),

            AppSpacing.verticalMd(context),

            // Search and Filters
            CompaniesFilters(
              controller: controller,
              isPhone: isPhone,
            ),

            AppSpacing.verticalMd(context),

            // Data Table or Card List
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value &&
                    controller.allCompanies.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (controller.filteredCompanies.isEmpty) {
                  return const CompaniesEmptyState();
                }

                return CompaniesContent(
                  controller: controller,
                  isPhone: isPhone,
                  authController: authController,
                  firestoreServices: firestoreServices,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
