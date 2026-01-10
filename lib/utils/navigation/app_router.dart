import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:trax_admin_portal/controller/auth_controller/auth_controller.dart';
import 'package:trax_admin_portal/controller/common_controllers/event_controller.dart';
import 'package:trax_admin_portal/controller/common_controllers/event_list_controller.dart';
import 'package:trax_admin_portal/controller/global_controllers/events_controller.dart';
import 'package:trax_admin_portal/controller/global_controllers/guest_controllers/guest_session_controller.dart';
import 'package:trax_admin_portal/controller/global_controllers/organisation_controller.dart';
import 'package:trax_admin_portal/controller/global_controllers/users_and_roles_controller.dart';
import 'package:trax_admin_portal/controller/global_controllers/venues_controller.dart';
import 'package:trax_admin_portal/controller/menus_list_controller.dart';
import 'package:trax_admin_portal/controller/menus_screen_controller.dart';
import 'package:trax_admin_portal/features/common/calendar_page/view/calendar_page.dart';
import 'package:trax_admin_portal/features/guest/rsvp_response/controller/rsvp_response_controller.dart';
import 'package:trax_admin_portal/features/guest/rsvp_response/view/compaignons_info_page.dart';
import 'package:trax_admin_portal/features/guest/rsvp_response/view/guest_count_page.dart';
import 'package:trax_admin_portal/features/settings/view/settings_page.dart';
import 'package:trax_admin_portal/helper/fetch_event.dart';
import 'package:trax_admin_portal/layout/header_resolver.dart';
import 'package:trax_admin_portal/models/event.dart';
import 'package:trax_admin_portal/utils/navigation/app_routes.dart';
import 'package:trax_admin_portal/utils/navigation/custom_error_page.dart';
import 'package:trax_admin_portal/utils/navigation/routes.dart';
import 'package:trax_admin_portal/view/admin/event_details/admin_event_details.dart';
import 'package:trax_admin_portal/view/admin/event_details/demographicResponsePage_refactored.dart';
import 'package:trax_admin_portal/view/admin/event_details/menuResponsePage_refactored.dart';
import 'package:trax_admin_portal/view/admin/event_details/thank_you_page.dart';
import 'package:trax_admin_portal/features/guest/rsvp_response/view/rsvp_response_page.dart';
import 'package:trax_admin_portal/view/admin/questions/host_questions_sets_screen.dart';
import 'package:trax_admin_portal/view/admin/venues_and_menus/menus_details_view.dart';
import 'package:trax_admin_portal/view/admin/venues_and_menus/menus_view.dart';
import 'package:trax_admin_portal/features/admin/admin_user_management/view/admin_user_list_page.dart';
import 'package:trax_admin_portal/view/authentication/login/email_verification_view.dart';
import 'package:trax_admin_portal/view/guest/guest_event_details.dart';
import 'package:trax_admin_portal/view/guest/respond/respond_screen.dart';
import 'package:trax_admin_portal/view/admin/create_event/create_edit_event_view.dart';
import 'package:trax_admin_portal/view/admin/event_details/widgets_old/guests_section/set_guests._view.dart';
import 'package:trax_admin_portal/view/admin/event_details/widgets_old/menu_section/set_menus_view.dart';
import 'package:trax_admin_portal/view/admin/event_details/widgets_old/questions_section/set_questions_view.dart';
import 'package:trax_admin_portal/view/admin/venues_and_menus/venues_view.dart';
import 'package:trax_admin_portal/view/admin/questions/host_questions_screen.dart';
import 'package:trax_admin_portal/view/common/event_list_screen.dart';
import 'package:trax_admin_portal/view/admin/event_details/widgets_old/responses_section.dart/responses_view.dart';
import 'package:trax_admin_portal/view/admin/organisation_info_popup/organisation_info_popup_view.dart';
import 'package:trax_admin_portal/view/admin/widgets/navigation_rail_wrapper.dart';
import 'package:trax_admin_portal/view/authentication/login/welcome_view.dart';
import 'package:trax_admin_portal/widgets/content_wrapper.dart';
import 'package:trax_admin_portal/widgets/event_loader.dart';
import 'package:trax_admin_portal/layout/guest_layout/guest_page_wrapper.dart';
import 'package:trax_admin_portal/view/admin/event_details/event_demographic_analyzer_page.dart';
import 'package:trax_admin_portal/view/admin/event_details/event_menu_analyzer_page.dart';
import 'package:trax_admin_portal/features/admin/admin_guest_side_preview/view/guest_side_preview_page.dart';
import 'package:trax_admin_portal/features/guest/guest_login/view/guest_login_page.dart';
import 'package:trax_admin_portal/features/guest/guest_responses_preview_edit/view/guest_responses_preview_page.dart';
import 'package:trax_admin_portal/features/guest/guest_responses_preview_edit/view/guest_demographics_edit_page.dart';
import 'package:trax_admin_portal/features/guest/guest_responses_preview_edit/view/guest_menu_selection_edit_page.dart';
import 'package:trax_admin_portal/features/guest/guest_feed_page/view/guest_feed_page.dart';
import 'package:trax_admin_portal/view/guest/widgets/guest_navigation_rail_wrapper.dart';
import 'package:trax_admin_portal/features/super_admin/super_admin_events/view/super_admin_page.dart';
import 'package:trax_admin_portal/features/super_admin/widgets/admin_navigation_rail_wrapper.dart';
import 'package:trax_admin_portal/features/super_admin/sales_people_management/view/sales_people_management_page.dart';
import 'package:trax_admin_portal/features/super_admin/dashboard/view/dashboard_page.dart';

/// Router setup for the Traxx application.
/// Currently implementing basic navigation structure with go_router.
///

/// Key for the host section's nested navigation
final GlobalKey<NavigatorState> hostNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> guestNavigationKey =
    GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> guestAuthNavigatorKey =
    GlobalKey<NavigatorState>();

///
/// Structure:
/// - Public routes (welcome, about, contact)
/// - Host section with nested navigation
GoRouter buildRouter() {
  final eventController = Get.find<EventController>();
  final authController = Get.find<AuthController>();
  return GoRouter(
    debugLogDiagnostics: true,
    initialLocation: AppRoute.welcome.path,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoute.welcome.path,
        builder: (context, state) {
          final User? currentUser = FirebaseAuth.instance.currentUser;

          if (currentUser != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              print(
                  'Router: User already signed in, checking role for redirection');

              // Check user role and redirect accordingly
              if (authController.isSuperAdmin) {
                print('Router: Redirecting super admin to dashboard');
                pushAndRemoveAllRoute(AppRoute.superAdminDashboard, context);
              } else if (authController.isSalesPerson) {
                print('Router: Redirecting sales person to dashboard');
                pushAndRemoveAllRoute(AppRoute.salesPersonDashboard, context);
              } else if (authController.isRegularHost) {
                print('Router: Redirecting regular host to host events');
                pushAndRemoveAllRoute(AppRoute.hostEvents, context);
              } else {
                print('Router: User has no organization, staying on welcome');
                // User authenticated but no org - they need to set up or might be guest
                // Stay on welcome page or could redirect to org setup
              }
            });
          }

          return const WelcomeView();
        },
      ),

      GoRoute(
        redirect: (context, state) {
          // Wait for auth controller to finish loading
          if (authController.isLoading.value) {
            print('Email Verification: Still loading user profile, waiting...');
            return null; // Stay on current route while loading
          }

          if (authController.isAuthenticatedAndVerified) {
            // User is verified, redirect based on role
            if (authController.isSuperAdmin) {
              print('Email Verification: Redirecting super admin to events');
              return AppRoute.superAdminEvents.path;
            } else if (authController.isSalesPerson) {
              print('Email Verification: Redirecting sales person to dashboard');
              return AppRoute.salesPersonDashboard.path;
            } else if (authController.isRegularHost) {
              print(
                  'Email Verification: Redirecting regular host to host events');
              return AppRoute.hostEvents.path;
            } else {
              print(
                  'Email Verification: User has no org, redirecting to org form');
              return AppRoute.hostOrganisationInfoForm.path;
            }
          }
          return null;
        },
        path: AppRoute.emailVerification.path,
        builder: (context, state) => EmailVerificationView(),
      ),
      GoRoute(
        redirect: (context, state) {
          // Wait for auth controller to finish loading
          if (authController.isLoading.value) {
            print('Org Form: Still loading user profile, waiting...');
            return null; // Stay on current route while loading
          }

          if (!authController.isAuthenticated) {
            return AppRoute.welcome.path;
          }
          if (!authController.isAuthenticatedAndVerified) {
            // Must verify email first
            return AppRoute.emailVerification.path;
          }
          // Super admin doesn't need organization form
          if (authController.isSuperAdmin) {
            print('Org Form: Super admin detected, redirecting to events');
            return AppRoute.superAdminEvents.path;
          }
          if (authController.companyInfoExists) {
            // Org already exists → go straight to host events
            return AppRoute.hostEvents.path;
          }
          // Otherwise show the organisation form
          return null;
        },
        path: AppRoute.hostOrganisationInfoForm.path,
        builder: (context, state) => const OrganisationInfoPopupView(),
      ),

      // GUEST AUTHENTICATED SHELL ROUTE
      // Handles guest authentication and session management
      // All guest routes that require authentication go here
      ShellRoute(
        navigatorKey: guestAuthNavigatorKey,
        redirect: (context, state) {
          final guestSession = Get.find<GuestSessionController>();

          // If on login page and already authenticated, redirect to responses preview
          if (state.matchedLocation == AppRoute.guestLogin.path) {
            if (guestSession.isAuthenticated) {
              print(
                  '✅ Guest already authenticated, redirecting to responses preview');
              return AppRoute.guestResponsesPreview.path;
            }
            // Not authenticated, allow access to login page
            return null;
          }

          // For all other guest routes, check if authenticated
          if (!guestSession.isAuthenticated) {
            print('🔒 Guest not authenticated, redirecting to login');
            return AppRoute.guestLogin.path;
          }

          print('✅ Guest authenticated, allowing access');
          return null; // Allow access to protected route
        },
        builder: (context, state, child) {
          // If on login page, don't show navigation rail
          if (state.matchedLocation == AppRoute.guestLogin.path) {
            print('ONLY CHILD RETURNED');
            return child;
          }

          // For authenticated routes, show navigation rail and content wrapper
          return GuestNavigationRailWrapper(
            child: ContentWrapper(
              child: child,
            ),
          );
        },
        routes: [
          // Public guest login route
          GoRoute(
            path: AppRoute.guestLogin.path,
            builder: (context, state) => const GuestLoginPage(),
          ),

          // Guest responses preview page (authenticated)
          GoRoute(
            path: AppRoute.guestResponsesPreview.path,
            builder: (context, state) => const GuestResponsesPreviewPage(),
          ),

          // Guest demographics edit page (authenticated)
          GoRoute(
            path: AppRoute.guestDemographicsEdit.path,
            builder: (context, state) => const GuestDemographicsEditPage(),
          ),

          // Guest menu selection edit page (authenticated)
          GoRoute(
            path: AppRoute.guestMenuSelectionEdit.path,
            builder: (context, state) => const GuestMenuSelectionEditPage(),
          ),

          // Guest feed page (authenticated)
          GoRoute(
            path: AppRoute.guestFeed.path,
            builder: (context, state) {
              final guestSession = Get.find<GuestSessionController>();
              final eventId = guestSession.event.value?.eventId ?? '';
              final eventName = guestSession.event.value?.name;

              return GuestFeedPage(
                eventId: eventId,
                eventName: eventName,
              );
            },
          ),

          // TODO: Add more authenticated guest routes here
          // Example:
          // GoRoute(
          //   path: AppRoute.guestDashboard.path,
          //   builder: (context, state) => const GuestDashboardPage(),
          // ),
        ],
      ),

      // GUEST RESPONSE SHELL ROUTE
      // Public routes for guests responding to invitations (RSVP → Demographics → Menu → Thank You)
      ShellRoute(
        builder: (context, state, child) {
          final invitationId = state.uri.queryParameters['invitationId'] ?? '';
          final token = state.uri.queryParameters['token'] ?? '';

          // Initialize RsvpResponseController at shell level
          // Use Get.put with tag - it returns existing if already created
          final controller = Get.put(
            RsvpResponseController(),
            tag: invitationId,
          );

          // Only initialize ONCE (check if invitationId is already set)
          if (controller.invitationId == null ||
              controller.invitationId!.isEmpty) {
            controller.invitationId = invitationId;
            controller.token = token;

            // Load invitation status
            controller.checkExistingResponse();
          }

          // Wrapper fetches event cover image from invitation and displays it reactively
          return GuestPageWrapper(
            invitationId: invitationId,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: AppRoute.guestResponse.path,
            builder: (context, state) {
              final invitationId =
                  state.uri.queryParameters['invitationId'] ?? '';
              final token = state.uri.queryParameters['token'] ?? '';
              final eventName = state.uri.queryParameters['eventName'];
              return RsvpResponsePage(
                invitationId: invitationId,
                token: token,
                eventName: eventName,
              );
            },
          ),
          GoRoute(
            path: AppRoute.guestCompanionsInfo.path,
            builder: (context, state) {
              final invitationId =
                  state.uri.queryParameters['invitationId'] ?? '';
              final token = state.uri.queryParameters['token'] ?? '';
              final eventName = state.uri.queryParameters['eventName'];
              return CompaignonsInfoPage(
                invitationId: invitationId,
                token: token,
                eventName: eventName,
              );
            },
          ),
          GoRoute(
            path: AppRoute.guestCompanions.path,
            builder: (context, state) {
              final invitationId =
                  state.uri.queryParameters['invitationId'] ?? '';
              final token = state.uri.queryParameters['token'] ?? '';
              final eventName = state.uri.queryParameters['eventName'];
              return GuestCountPage(
                invitationId: invitationId,
                token: token,
                eventName: eventName,
              );
            },
          ),
          GoRoute(
            path: AppRoute.demographics.path,
            builder: (context, state) {
              final invitationId =
                  state.uri.queryParameters['invitationId'] ?? '';
              final token = state.uri.queryParameters['token'] ?? '';

              // Parse companion index if provided
              final companionIndexStr =
                  state.uri.queryParameters['companionIndex'];
              final int? companionIndex = companionIndexStr != null
                  ? int.tryParse(companionIndexStr)
                  : null;

              // Get companion name if provided
              final companionName = state.uri.queryParameters['companionName'];

              return DemographicResponsePage(
                invitationId: invitationId,
                token: token,
                embedded: false,
                showInvitationInput: false,
                companionIndex: companionIndex,
                companionName: companionName,
              );
            },
          ),
          // GoRoute(
          //   path: AppRoute.menuSelection.path,
          //   builder: (context, state) {
          //     final invitationId = state.uri.queryParameters['invitationId'] ?? '';
          //     return GuestMenuSelectionPage(invitationId: invitationId);
          //   },
          // ),
          GoRoute(
            path: AppRoute.thankYou.path,
            builder: (context, state) {
              final invitationId =
                  state.uri.queryParameters['invitationId'] ?? '';
              return ThankYouPage(invitationId: invitationId);
            },
          ),
          GoRoute(
            path: AppRoute.menuSelection.path,
            builder: (context, state) {
              final invitationId =
                  state.uri.queryParameters['invitationId'] ?? '';

              // Parse companion index if provided
              final companionIndexStr =
                  state.uri.queryParameters['companionIndex'];
              final int? companionIndex = companionIndexStr != null
                  ? int.tryParse(companionIndexStr)
                  : null;

              // Get companion name if provided
              final companionName = state.uri.queryParameters['companionName'];

              return GuestMenuSelectionPage(
                invitationId: invitationId,
                companionIndex: companionIndex,
                companionName: companionName,
              );
            },
          ),
        ],
      ),

      // SUPER ADMIN SHELL ROUTE
      ShellRoute(
        redirect: (context, state) {
          // Wait for auth controller to finish loading
          if (authController.isLoading.value) {
            print('Super Admin: Still loading user profile, waiting...');
            return null; // Stay on current route while loading
          }

          // Check authentication
          if (!authController.isAuthenticated) {
            print('Super Admin: Redirecting to welcome - not authenticated');
            return AppRoute.welcome.path;
          }

          // Check email verification
          if (!authController.isAuthenticatedAndVerified) {
            print('Super Admin: Redirecting to email verification');
            return AppRoute.emailVerification.path;
          }

          // Check if user is super admin
          if (!authController.isSuperAdmin) {
            print('Super Admin: User is not super admin');

            // Check if user has valid organization access
            if (authController.isRegularHost) {
              print('Super Admin: Redirecting regular host to host area');
              return AppRoute.hostEvents.path;
            } else {
              // User has no organization - they shouldn't be here at all
              // This is a security measure for accounts without proper setup
              print('Super Admin: User has no organization, logging out');
              authController.logout();
              return AppRoute.welcome.path;
            }
          }

          print('✅ Super Admin: Access granted');
          return null;
        },
        builder: (context, state, child) {
          final authController = Get.find<AuthController>();

          return Obx(() {
            try {
              // Show loading while auth is loading
              if (authController.isLoading.value) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              // Initialize controllers needed for event details
              // Only initialize VenuesController if not already registered
              if (!Get.isRegistered<VenuesController>()) {
                Get.put(VenuesController());
              }

              // Initialize OrganisationController if organisation is selected
              // This runs reactively when organisationId changes
              if (authController.organisationId.value != null) {
                if (!Get.isRegistered<OrganisationController>()) {
                  print(
                      '🔧 Initializing OrganisationController for super admin with org: ${authController.organisationId.value}');
                  Get.put(OrganisationController(
                      authController.organisationId.value!));
                }
              }

              // Initialize other required controllers
              if (!Get.isRegistered<MenusListController>()) {
                Get.put(MenusListController());
              }
              if (!Get.isRegistered<MenusScreenController>()) {
                Get.put(MenusScreenController());
              }
              if (!Get.isRegistered<EventsController>()) {
                Get.put(EventsController());
              }

              return AdminNavigationRailWrapper(
                dashboardRoute: AppRoute.superAdminDashboard,
                eventsRoute: AppRoute.superAdminEvents,
                child: ContentWrapper(
                  child: child,
                ),
              );
            } catch (e) {
              print('Error in super admin builder: $e');
              return Scaffold(
                body: Center(
                  child: Text('Error loading super admin panel: $e'),
                ),
              );
            }
          });
        },
        routes: [
          GoRoute(
            path: AppRoute.superAdminDashboard.path,
            builder: (context, state) => DashboardPage(),
          ),
          GoRoute(
            path: AppRoute.superAdminEvents.path,
            builder: (context, state) => const SuperAdminPage(),
          ),
          GoRoute(
            path: AppRoute.superAdminEventDetails.path,
            builder: (context, state) {
              final eventId = state
                  .pathParameters[AppRoute.superAdminEventDetails.placeholder]!;
              return AdminEventDetails(
                eventId: eventId,
              );
            },
          ),
          GoRoute(
            path: AppRoute.superAdminSalesPeople.path,
            builder: (context, state) => SalesPeopleManagementPage(),
          ),
          // Add more super admin routes here as needed
        ],
      ),

      // SALES PERSON SHELL ROUTE
      ShellRoute(
        redirect: (context, state) {
          // Wait for auth controller to finish loading
          if (authController.isLoading.value) {
            print('Sales Person: Still loading user profile, waiting...');
            return null; // Stay on current route while loading
          }

          // Check authentication
          if (!authController.isAuthenticated) {
            print('Sales Person: Redirecting to welcome - not authenticated');
            return AppRoute.welcome.path;
          }

          // Check email verification
          if (!authController.isAuthenticatedAndVerified) {
            print('Sales Person: Redirecting to email verification');
            return AppRoute.emailVerification.path;
          }

          // Check if user is sales person
          if (!authController.isSalesPerson) {
            print('Sales Person: User is not a sales person');

            // Check if user has other valid access
            if (authController.isSuperAdmin) {
              print('Sales Person: Redirecting super admin to super admin area');
              return AppRoute.superAdminEvents.path;
            } else if (authController.isRegularHost) {
              print('Sales Person: Redirecting regular host to host area');
              return AppRoute.hostEvents.path;
            } else {
              // User has no valid access - shouldn't be here
              print('Sales Person: User has no valid role, logging out');
              authController.logout();
              return AppRoute.welcome.path;
            }
          }

          print('✅ Sales Person: Access granted');
          return null;
        },
        builder: (context, state, child) {
          final authController = Get.find<AuthController>();

          return Obx(() {
            try {
              // Show loading while auth is loading
              if (authController.isLoading.value) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              // Initialize controllers needed for sales person
              // Only initialize VenuesController if not already registered
              if (!Get.isRegistered<VenuesController>()) {
                Get.put(VenuesController());
              }

              // Initialize OrganisationController if organisation is selected
              // This runs reactively when organisationId changes
              if (authController.organisationId.value != null) {
                if (!Get.isRegistered<OrganisationController>()) {
                  print(
                      '🔧 Initializing OrganisationController for sales person with org: ${authController.organisationId.value}');
                  Get.put(OrganisationController(
                      authController.organisationId.value!));
                }
              }

              // Initialize other required controllers
              if (!Get.isRegistered<MenusListController>()) {
                Get.put(MenusListController());
              }
              if (!Get.isRegistered<MenusScreenController>()) {
                Get.put(MenusScreenController());
              }
              if (!Get.isRegistered<EventsController>()) {
                Get.put(EventsController());
              }

              return AdminNavigationRailWrapper(
                hideSalesPeople: true, // Hide Sales People section for sales person
                dashboardRoute: AppRoute.salesPersonDashboard,
                eventsRoute: AppRoute.salesPersonEvents,
                child: ContentWrapper(
                  child: child,
                ),
              );
            } catch (e) {
              print('Error in sales person builder: $e');
              return Scaffold(
                body: Center(
                  child: Text('Error loading sales person portal: $e'),
                ),
              );
            }
          });
        },
        routes: [
          GoRoute(
            path: AppRoute.salesPersonDashboard.path,
            builder: (context, state) => DashboardPage(),
          ),
          GoRoute(
            path: AppRoute.salesPersonEvents.path,
            builder: (context, state) => const SuperAdminPage(),
          ),
          GoRoute(
            path: AppRoute.salesPersonEventDetails.path,
            builder: (context, state) {
              final eventId = state
                  .pathParameters[AppRoute.salesPersonEventDetails.placeholder]!;
              return AdminEventDetails(
                eventId: eventId,
              );
            },
          ),
        ],
      ),

      //HOST SHELL ROUTE
      ShellRoute(
        redirect: (context, state) {
          // Wait for auth controller to finish loading
          if (authController.isLoading.value) {
            print('Host Shell: Still loading user profile, waiting...');
            return null; // Stay on current route while loading
          }

          if (!authController.isAuthenticated) {
            print('Host Shell: Redirecting to welcome - not authenticated');
            return AppRoute.welcome.path;
          }

          if (!authController.isAuthenticatedAndVerified) {
            print('Host Shell: Redirecting to email verification');
            return AppRoute.emailVerification.path;
          }

          // Super admin should use super admin routes, not host routes
          if (authController.isSuperAdmin) {
            print(
                'Host Shell: Super admin detected, redirecting to super admin events');
            return AppRoute.superAdminEvents.path;
          }

          if (!authController.companyInfoExists) {
            print('Host Shell: Redirecting to organisation info form');
            return AppRoute.hostOrganisationInfoForm.path;
          }

          print('Host Shell: Access granted');
          return null;
        },
        navigatorKey: hostNavigatorKey,
        builder: (context, state, child) {
          // Check if user is authenticated
          final User? currentUser = FirebaseAuth.instance.currentUser;
          // if (currentUser == null || !currentUser.emailVerified) {
          if (currentUser == null) {
            // If user is not authenticated, redirect to welcome
            WidgetsBinding.instance.addPostFrameCallback((_) {
              pushAndRemoveAllRoute(AppRoute.welcome, context);
              // pushAndRemoveAllRoute(AppRoute.emailVerification, context);
            });
            return Center(child: CircularProgressIndicator());
          }

          final eventListController = Get.find<EventListController>();
          final authController = Get.find<AuthController>();
          Get.put(VenuesController());
          Get.put(MenusListController());
          Get.put(MenusScreenController());
          Get.put(EventsController());
          Get.put(OrganisationController(authController.organisationId.value!));
          Get.put(UsersAndRolesController());

          return Obx(() {
            try {
              if (eventListController.isLoading.value ||
                  authController.isLoading.value) {
                return Center(child: CircularProgressIndicator());
              }
              final location = state.matchedLocation;

              // Treat these paths as Google Forms–style question pages
              final isQuestionsPage = location
                      .startsWith(AppRoute.hostQuestionSets.path) ||
                  location.startsWith(AppRoute.hostQuestions.path) ||
                  location.startsWith(AppRoute.hostQuestionSetQuestions.path);

              const Color gfBackground = Color(0xFFF4F0FB);

              return NavigationRailWrapper(
                child: ContentWrapper(
                  contentColor: isQuestionsPage
                      ? gfBackground // Color(0xFFF4F0FB)
                      : const Color.fromARGB(255, 247, 247, 247),
                  header: getPageHeader(state, context: context),
                  child: child,
                ),
              );
            } catch (e) {
              print('Exception in host shell route builder: $e');
              return Center(child: Text('Error: $e'));
              // Error Handling or redirection
            }
          });
        },
        routes: [
          GoRoute(
            path: AppRoute.hostEvents.path,
            builder: (context, state) => EventListScreen(),
          ),
          GoRoute(
            path: AppRoute.calendarView.path,
            builder: (context, state) => const CalendarPage(),
          ),
          GoRoute(
            path: AppRoute.hostMenus.path,
            builder: (context, state) => MenusView(),
          ),
          GoRoute(
            path: AppRoute.hostMenuDetails.path,
            builder: (context, state) {
              final menuId =
                  state.pathParameters[AppRoute.hostMenuDetails.placeholder]!;
              return MenuSetDetailsView(menuId: menuId);
            },
          ),
          GoRoute(
            path: AppRoute.hostVenues.path,
            builder: (context, state) => const VenuesView(),
          ),
          GoRoute(
            path: AppRoute.hostVenueDetails.path,
            builder: (context, state) {
              final venueId =
                  state.pathParameters[AppRoute.hostVenueDetails.placeholder]!;
              return VenuesView();
            },
          ),
          GoRoute(
            path: AppRoute.hostRoleSelection.path,
            builder: (context, state) {
              return AdminUserListPage();
            },
          ),
          GoRoute(
            path: AppRoute.hostQuestionSets.path,
            builder: (context, state) => const QuestionSetsScreen(),
          ),
          GoRoute(
            path: AppRoute.hostQuestions.path,
            builder: (context, state) {
              final setId = state.uri.queryParameters['setId'] ?? '';
              final setTitle = state.uri.queryParameters['setTitle'] ?? '';
              final setDescription =
                  state.uri.queryParameters['setDescription'] ?? '';

              if (setId.isEmpty) {
                return const QuestionSetsScreen();
              }

              return HostQuestionsScreen(
                questionSetId: setId,
              );
            },
          ),
          GoRoute(
            path: AppRoute.hostQuestionSetQuestions.path,
            builder: (context, state) {
              final setId = state.pathParameters[
                  AppRoute.hostQuestionSetQuestions.placeholder]!;
              final setTitle = state.uri.queryParameters['setTitle'] ?? '';
              final setDescription =
                  state.uri.queryParameters['setDescription'] ?? '';
              return HostQuestionsScreen(
                questionSetId: setId,
              );
            },
          ),

          GoRoute(
            path: AppRoute.hostCreateEvent.path,
            builder: (context, state) => CreateEditEventView(),
          ),
          GoRoute(
            path: AppRoute.eventDetails.path,
            builder: (context, state) {
              final eventId =
                  state.pathParameters[AppRoute.eventDetails.placeholder]!;
              return AdminEventDetails(
                eventId: eventId,
              );
            },
          ),
          GoRoute(
            path: AppRoute.hostSettings.path,
            builder: (context, state) => SettingsPage(),
          ),
          GoRoute(
            path: AppRoute.eventQuestions.path,
            builder: (context, state) => SetQuestionsView(),
          ),
          GoRoute(
            path: AppRoute.eventMenus.path,
            builder: (context, state) {
              final Event? selectedEvent = eventController.selectedEvent.value;
              final eventId =
                  state.pathParameters[AppRoute.eventDetails.placeholder]!;
              if (selectedEvent != null) {
                return SetMenusView();
              }

              return FutureBuilder<Event>(
                future: EventFetcher.fetchEvent(eventId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  eventController.setSelectedEvent(snapshot.data!);

                  return SetMenusView();
                },
              );
            },
          ),
          GoRoute(
            path: AppRoute.eventDemographicAnalyzer.path,
            builder: (context, state) {
              final eventId = state.pathParameters[
                  AppRoute.eventDemographicAnalyzer.placeholder]!;
              return EventDemographicAnalyzerPage(eventId: eventId);
            },
          ),
          GoRoute(
            path: AppRoute.eventMenuAnalyzer.path,
            builder: (context, state) {
              final eventId =
                  state.pathParameters[AppRoute.eventMenuAnalyzer.placeholder]!;
              return EventMenuAnalyzerPage(eventId: eventId);
            },
          ),
          GoRoute(
            path: AppRoute.guestSidePreview.path,
            builder: (context, state) {
              final eventId =
                  state.pathParameters[AppRoute.guestSidePreview.placeholder]!;
              return GuestSidePreviewPage(eventId: eventId);
            },
          ),

          GoRoute(
            path: AppRoute.eventGuests.path,
            builder: (context, state) => SetGuestsView(),
          ),
          GoRoute(
            path: AppRoute.eventResponses.path,
            builder: (context, state) {
              String eventId =
                  state.pathParameters[AppRoute.eventResponses.placeholder]!;
              return EventLoader(
                eventController: eventController,
                eventId: eventId,
                builder: (context, event) => ResponsesView(),
              );
            },
          ),
          // GoRoute(
          //   path: AppRoute.hostDemographics.path,
          //   builder: (context, state) {
          //     final invitationId =
          //         state.uri.queryParameters['invitationId'] ?? '';
          //     return DemographicResponsePage(
          //       invitationId: invitationId,
          //       showInvitationInput: true,
          //       embedded: true, // ✅ NEW
          //     );
          //   },
          // ),
        ],
      ),
      // Guest Shell Route
      ShellRoute(
        navigatorKey: guestNavigationKey,
        builder: (context, state, child) {
          final eventListController = Get.find<EventListController>();
          final authController = Get.find<AuthController>();
          return Obx(() {
            try {
              if (eventListController.isLoading.value ||
                  authController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final location = state.matchedLocation;

              // Treat these paths as Google Forms–style question pages
              final isQuestionsPage = location
                      .startsWith(AppRoute.hostQuestionSets.path) ||
                  location.startsWith(AppRoute.hostQuestions.path) ||
                  location.startsWith(AppRoute.hostQuestionSetQuestions.path);

              const Color gfBackground = Color(0xFFF4F0FB);

              if (isQuestionsPage) {
                // ✅ QUESTION PAGES:
                // Header is drawn OUTSIDE ContentWrapper so it spans full width.
                return NavigationRailWrapper(
                  child: Column(
                    children: [
                      // full-width header
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 40,
                          right: 40,
                          top: 24,
                          bottom: 8,
                        ),
                        child: getPageHeader(state, context: context),
                      ),
                      // content area with lavender background + limited-width body
                      Expanded(
                        child: ContentWrapper(
                          contentColor: gfBackground,
                          // no header here – body only
                          child: child,
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                // ✅ ALL OTHER PAGES – behave exactly as before
                return NavigationRailWrapper(
                  child: ContentWrapper(
                    contentColor: const Color.fromARGB(255, 247, 247, 247),
                    header: getPageHeader(state, context: context),
                    child: child,
                  ),
                );
              }
            } catch (e) {
              return Container(); //Temporary
            }
          });
        },
        routes: [
          GoRoute(
            path: AppRoute.guestEvents.path,
            builder: (context, state) => EventListScreen(),
          ),
          GoRoute(
            path: AppRoute.guestEventDetails.path,
            builder: (context, state) {
              final Event? event = eventController.selectedEvent.value;
              if (event != null) {
                return GuestEventDetails();
              }

              final eventId =
                  state.pathParameters[AppRoute.guestEventDetails.placeholder]!;
              return FutureBuilder<Event>(
                future: EventFetcher.fetchEvent(eventId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  eventController.setSelectedEvent(snapshot.data!);

                  return GuestEventDetails();
                },
              );
            },
          ),
          GoRoute(
            path: AppRoute.guestEventRespond.path,
            builder: (context, state) {
              final eventId =
                  state.pathParameters[AppRoute.eventDetails.placeholder]!;
              final Event? selectedEvent = eventController.selectedEvent.value;
              if (selectedEvent != null) {
                return RespondScreen(event: selectedEvent);
              }
              // final Event? event;
              // if (state.extra != null && state.extra is Event) {
              //   event = state.extra as Event;
              // } else {
              //   event = null;
              // }
              // final eventId =
              //     state.pathParameters[AppRoute.guestEventRespond.placeholder]!;
              //     Event event = EventFetcher()
              // return RespondScreen(eventId: eventId);
              return FutureBuilder<Event>(
                future: EventFetcher.fetchEvent(eventId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  return RespondScreen(event: snapshot.data!);
                },
              );
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => CustomErrorPage(),
  );
}
