import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:trax_admin_portal/controller/auth_controller/auth_controller.dart';
import 'package:trax_admin_portal/controller/global_controllers/events_controller.dart';
import 'package:trax_admin_portal/controller/global_controllers/organisation_controller.dart';
import 'package:trax_admin_portal/controller/global_controllers/payments_controller.dart';
import 'package:trax_admin_portal/controller/global_controllers/venues_controller.dart';
import 'package:trax_admin_portal/controller/menus_list_controller.dart';
import 'package:trax_admin_portal/controller/menus_screen_controller.dart';
import 'package:trax_admin_portal/features/super_admin/global_controllers/sales_people_global_controller.dart';
import 'package:trax_admin_portal/features/super_admin/global_controllers/super_admins_global_controller.dart';
import 'package:trax_admin_portal/layout/header_resolver.dart';
import 'package:trax_admin_portal/utils/navigation/app_routes.dart';
import 'package:trax_admin_portal/utils/navigation/custom_error_page.dart';
import 'package:trax_admin_portal/utils/navigation/routes.dart';
import 'package:trax_admin_portal/view/admin/event_details/admin_event_details.dart';
import 'package:trax_admin_portal/view/authentication/login/email_verification_view.dart';
import 'package:trax_admin_portal/view/authentication/login/welcome_view.dart';
import 'package:trax_admin_portal/features/auth/password_reset/view/password_reset_page.dart';
import 'package:trax_admin_portal/widgets/content_wrapper.dart';
import 'package:trax_admin_portal/features/super_admin/super_admin_events/view/super_admin_page.dart';
import 'package:trax_admin_portal/features/super_admin/widgets/admin_navigation_rail_wrapper.dart';
import 'package:trax_admin_portal/features/super_admin/sales_people_management/view/sales_people_management_page.dart';
import 'package:trax_admin_portal/features/super_admin/super_admin_management/view/super_admin_management_page.dart';
import 'package:trax_admin_portal/features/super_admin/dashboard/view/dashboard_page.dart';

/// Router setup for the Super Admin and Sales Person portal.
/// Handles authentication and role-based routing for administrative users.

///
/// Structure:
/// - Welcome page (login)
/// - Email verification
/// - Super Admin shell route (dashboard, events, event details, sales people management)
/// - Sales Person shell route (dashboard, events, event details)
GoRouter buildRouter() {
  final authController = Get.find<AuthController>();
  return GoRouter(
    debugLogDiagnostics: true,
    initialLocation: AppRoute.welcome.path,
    routes: <RouteBase>[
      // Welcome/Login Page
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
              } else {
                print('Router: User has no admin/sales role, staying on welcome');
                // User authenticated but no admin/sales role
                // Stay on welcome page
              }
            });
          }

          return const WelcomeView();
        },
      ),

      // Email Verification Page
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
              print('Email Verification: Redirecting super admin to dashboard');
              return AppRoute.superAdminDashboard.path;
            } else if (authController.isSalesPerson) {
              print(
                  'Email Verification: Redirecting sales person to dashboard');
              return AppRoute.salesPersonDashboard.path;
            } else {
              print(
                  'Email Verification: User has no admin/sales role, redirecting to welcome');
              return AppRoute.welcome.path;
            }
          }
          return null;
        },
        path: AppRoute.emailVerification.path,
        builder: (context, state) => EmailVerificationView(),
      ),

      // Password Reset Page (public, no authentication required)
      GoRoute(
        path: AppRoute.resetPassword.path,
        builder: (context, state) {
          // Extract oobCode from query parameters
          final oobCode = state.uri.queryParameters['oobCode'] ?? '';
          return PasswordResetPage(oobCode: oobCode);
        },
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
            print('Super Admin: User is not super admin, logging out');
            authController.logout();
            return AppRoute.welcome.path;
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

              // Initialize global controllers for Super Admin section
              if (!Get.isRegistered<SalesPeopleGlobalController>()) {
                Get.put(SalesPeopleGlobalController(), permanent: true);
                print('✅ Initialized SalesPeopleGlobalController');
              }
              
              if (!Get.isRegistered<SuperAdminsGlobalController>()) {
                Get.put(SuperAdminsGlobalController(), permanent: true);
                print('✅ Initialized SuperAdminsGlobalController');
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

              // Initialize PaymentsController for super admin with all organisation IDs
              if (!Get.isRegistered<PaymentsController>()) {
                final organisationIds = authController.organisations
                    .map((org) => org.organisationId)
                    .whereType<String>()
                    .toList();
                Get.put(PaymentsController(organisationIds), permanent: true);
                print('✅ Initialized PaymentsController with ${organisationIds.length} organisations');
              }

              // Get the appropriate header for the current route
              final header = getPageHeader(state, context: context);

              return AdminNavigationRailWrapper(
                dashboardRoute: AppRoute.superAdminDashboard,
                eventsRoute: AppRoute.superAdminEvents,
                child: Column(
                  children: [
                    header,
                    Expanded(
                      child: ContentWrapper(
                        child: child,
                      ),
                    ),
                  ],
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
          GoRoute(
            path: AppRoute.superAdminManagement.path,
            builder: (context, state) => SuperAdminManagementPage(),
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
            // Only super admin and sales person are supported
            if (authController.isSuperAdmin) {
              print('Sales Person: Redirecting super admin to super admin area');
              return AppRoute.superAdminEvents.path;
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
              if (!Get.isRegistered<SalesPeopleGlobalController>()) {
                Get.put(SalesPeopleGlobalController(), permanent: true);
                print('✅ Initialized SalesPeopleGlobalController');
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
               if (!Get.isRegistered<PaymentsController>()) {
                final organisationIds = authController.organisations
                    .map((org) => org.organisationId)
                    .whereType<String>()
                    .toList();
                Get.put(PaymentsController(organisationIds), permanent: true);
                print('✅ Initialized PaymentsController with ${organisationIds.length} organisations');
              }

              // Get the appropriate header for the current route
              final header = getPageHeader(state, context: context);

              return AdminNavigationRailWrapper(
                hideSalesPeople:
                    true, // Hide Sales People section for sales person
                dashboardRoute: AppRoute.salesPersonDashboard,
                eventsRoute: AppRoute.salesPersonEvents,
                child: Column(
                  children: [
                    header,
                    Expanded(
                      child: ContentWrapper(
                        child: child,
                      ),
                    ),
                  ],
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
              final eventId = state.pathParameters[
                  AppRoute.salesPersonEventDetails.placeholder]!;
              return AdminEventDetails(
                eventId: eventId,
              );
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => CustomErrorPage(),
  );
}
