import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:trax_admin_portal/controller/common_controllers/event_list_controller.dart';
import 'package:trax_admin_portal/features/super_admin/companies/widgets/company_info_header.dart';
import 'package:trax_admin_portal/features/super_admin/super_admin_events/controllers/super_admin_event_list_controller.dart';
import 'package:trax_admin_portal/features/super_admin/super_admin_events/widgets/super_admin_list_of_events.dart';
import 'package:trax_admin_portal/helper/app_padding.dart';
import 'package:trax_admin_portal/helper/app_spacing.dart';
import 'package:trax_admin_portal/theme/app_colors.dart';
import 'package:trax_admin_portal/utils/enums/sizes.dart';
import 'package:trax_admin_portal/view/common/widgets/event_filter_section.dart';

/// A screen that displays a list of events for the super admin user.
///
/// This screen includes:
/// - Company information header (when an organisation is selected)
/// - A search field for filtering events
/// - A sort button for organizing events
/// - A scrollable list of event cards
class SuperAdminEventListScreen extends StatelessWidget {
  SuperAdminEventListScreen({super.key});
  
  final SuperAdminEventListController controller = Get.put(SuperAdminEventListController());
  final EventListController eventListController = Get.find<EventListController>();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Company Info Header
          Obx(() {
            final summary = controller.companySummary.value;
            if (summary != null) {
              return Padding(
                padding: AppPadding.all(context, paddingType: Sizes.sm),
                child: CompanyInfoHeader(
                  companySummary: summary,
                  controller: controller,
                  onBackPressed: () {
                    controller.clearSelectedOrganisation();
                  },
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          AppSpacing.verticalXs(context),

          // Event list container
          Obx(() => Container(
              decoration: BoxDecoration(
                color: eventListController.events.isNotEmpty
                    ? AppColors.white
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: AppPadding.all(context, paddingType: Sizes.sm),
                child: Column(
                  children: [
                    // Show header and filters if there are any events in the system
                    if (eventListController.events.isNotEmpty) ...[
                      // EventListHeader(),
                      AppSpacing.verticalXs(context),
                      EventFilterSection(),
                      AppSpacing.verticalXs(context),
                    ],
                    const SuperAdminListOfEvents(),
                  ],
                ),
              ))),
        ],
      ),
    );
  }
}
