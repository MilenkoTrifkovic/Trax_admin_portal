import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:trax_admin_portal/controller/auth_controller/auth_controller.dart';
import 'package:trax_admin_portal/features/super_admin/super_admin_events/widgets/super_admin_event_list_screen.dart';
import 'package:trax_admin_portal/features/super_admin/widgets/organisation_selector.dart';
import 'package:trax_admin_portal/view/common/event_list_screen.dart';

class SuperAdminPage extends StatelessWidget {
  const SuperAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    // Reactively watch organisationId to switch between selector and event list
    return Obx(() {
      final hasSelectedOrg = authController.organisationId.value != null;

      if (hasSelectedOrg) {
        // Show event list screen with a header to switch organizations
        return Column(
          children: [
            // Organization switcher header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.business, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    authController.organisation.value?.name ?? 'Organization',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      authController.clearSelectedOrganisation();
                    },
                    icon: const Icon(Icons.swap_horiz, size: 18),
                    label: const Text('Switch Organization'),
                  ),
                ],
              ),
            ),
            // Event list
            Expanded(
              child: SuperAdminEventListScreen(),
            ),
          ],
        );
      } else {
        // Show organization selector
        return const OrganisationSelector();
      }
    });
  }
}
