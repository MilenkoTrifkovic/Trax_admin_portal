import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:trax_admin_portal/controller/common_controllers/event_list_controller.dart';
import 'package:trax_admin_portal/helper/app_spacing.dart';
import 'package:trax_admin_portal/helper/screen_size.dart';
import 'package:trax_admin_portal/layout/headers/widgets/header_back_button.dart';
import 'package:trax_admin_portal/utils/enums/event_status.dart';
import 'package:trax_admin_portal/utils/navigation/app_routes.dart';
import 'package:trax_admin_portal/utils/navigation/routes.dart';
import 'package:trax_admin_portal/controller/global_controllers/snackbar_message_controller.dart';
import 'package:trax_admin_portal/widgets/app_primary_button.dart';
import 'package:trax_admin_portal/widgets/app_secondary_button.dart';

class HostEventDetailsHeader extends StatelessWidget {
  HostEventDetailsHeader({super.key});
  final EventListController eventListController =
      Get.find<EventListController>();
  final SnackbarMessageController snackbarController =
      Get.find<SnackbarMessageController>();
  @override
  Widget build(BuildContext context) {
    bool idDesktop = ScreenSize.isDesktop(context);
    
    // Determine the back route and event details route based on current location
    final location = GoRouterState.of(context).uri.path;
    AppRoute backRoute;
    String? eventIdPlaceholder;
    bool isHostRoute = false; // Track if this is a host route
    
    if (location.startsWith('/super-admin-event-details/')) {
      backRoute = AppRoute.superAdminEvents;
      eventIdPlaceholder = AppRoute.superAdminEventDetails.placeholder;
      isHostRoute = false;
    } else if (location.startsWith('/sales-person-event-details/')) {
      backRoute = AppRoute.salesPersonEvents;
      eventIdPlaceholder = AppRoute.salesPersonEventDetails.placeholder;
      isHostRoute = false;
    } else {
      // Default to host routes
      backRoute = AppRoute.hostEvents;
      eventIdPlaceholder = AppRoute.eventDetails.placeholder;
      isHostRoute = true;
    }
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        HeaderBackButton(
            onTap: () => pushAndRemoveAllRoute(backRoute, context),
            text: 'Back to Events'),
        // AppText.styledHeadingLarge(context, 'Events'),
        Row(
          children: [
            // AppSearchInputField(
            //   hintText: 'Search events...',
            //   onChanged: (value) {
            //     eventListController.filterEvents(value);
            //   },
            // ),

            // Only show preview button for host routes
            if (isHostRoute) ...[
              AppSpacing.horizontalXs(context),
              AppSecondaryButton(
                text: idDesktop ? 'Preview Guest Page' : '',
                icon: Icons.remove_red_eye,
                onPressed: () {
                  // Get eventId from route using the dynamic placeholder
                  final eventId = eventIdPlaceholder != null
                      ? GoRouterState.of(context).pathParameters[eventIdPlaceholder]
                      : null;
                  
                  if (eventId != null) {
                    pushRoute(AppRoute.guestSidePreview, context, urlParam: eventId);
                  }
                },
              ),
            ],
            // AppSecondaryButton(text: 'text'),
            AppSpacing.horizontalXs(context),
            // AppSecondaryButton(
            //     text: idDesktop ? 'Edit Details' : '',
            //     icon: Icons.edit_note,
            //     onPressed: () {}),
            // Only show spacing and publish button if event is not already published
            Obx(() {
              final event = eventListController.selectedEvent.value;
              final isPublished = event?.status == EventStatus.published;
              
              // If event is published, don't show the spacing or button
              if (isPublished) {
                return const SizedBox.shrink();
              }
              
              // Show spacing and publish button if event is not published
              return Row(
                children: [
                  AppSpacing.horizontalXs(context),
                  AppPrimaryButton(
                      // icon: Icons.add,
                      text: idDesktop ? 'Publish Event' : 'Publish',
                      onPressed: () async {
                        // Handle publish event action
                        try {
                          await eventListController.publishEvent();
                          if (!context.mounted) return;
                          snackbarController.showSuccessMessage(
                            'Event published successfully!',
                          );
                        } catch (e) {
                          print('Error publishing event: $e');
                          if (!context.mounted) return;
                          snackbarController.showErrorMessage(
                            'Failed to publish event. Please try again.',
                          );
                        }
                      }),
                ],
              );
            }),
            // AppSpacing.horizontalXs(context),
            // PopupMenuButton(
            //   icon: Icon(
            //     Icons.more_vert,
            //     color: AppColors.black,
            //   ),
            //   color: AppColors.background(context),
            //   itemBuilder: (context) {
            //     return [
            //       PopupMenuItem(
            //         ///////////////////////////////////////////////ToDo
            //         child: Text('Edit Event'),
            //         onTap: () {},
            //         // onTap: () => hostController.toggleEditingEvent(true),
            //       ),
            //       PopupMenuItem(
            //         ///////////////////////////////////////////////ToDo
            //         child: Text('Delete Event'),
            //         onTap: () async {
            //           Dialogs.showConfirmationDialog(
            //             context,
            //             "Are you sure you want to delete this event? \nThis action cannot be undone.",
            //             () async {
            //               try {
            //                 await eventListController
            //                     .deleteEvent(); ///////////////////////////////////////////////////
            //                 if (!context.mounted) return;
            //   snackbarController.showSuccessMessage(
            //     'Event deleted successfully');
            //                 popRoute(context);
            //               } on Exception catch (e) {
            //                 print('Error deleting event: $e');
            //   snackbarController.showErrorMessage(
            //     'Event deletion failed. Try again');
            //               }
            //             },
            //           );
            //         },
            //       ),
            //     ];
            //   },
            // ),
          ],
        )
      ],
    );
  }
}
