import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:trax_admin_portal/models/organisation.dart';
import 'package:trax_admin_portal/models/sales_person_model.dart';
import 'package:go_router/go_router.dart';
import 'package:trax_admin_portal/services/firestore_services/firestore_services.dart';
// Removed unused import for SharedPrefServices
import 'package:trax_admin_portal/services/cloud_functions_services.dart';
import 'package:trax_admin_portal/controller/global_controllers/snackbar_message_controller.dart';
import 'package:trax_admin_portal/services/sales_people_management_services.dart';
import 'package:trax_admin_portal/utils/enums/user_type.dart';

class AuthController extends GetxController {
  /// Snackbar controller for showing global messages
  SnackbarMessageController? _snackbarController;
  late final FirestoreServices _firestoreServices;
  // Removed unused _sharedPrefServices
  late final CloudFunctionsService _cloudFunctionsService;
  final SalesPeopleManagementServices _salesPeopleServices =
      SalesPeopleManagementServices();

  final RxBool _isAuthenticated = false.obs;
  final RxBool _companyInfoExists = false.obs;

  bool get isAuthenticated => _isAuthenticated.value;
  bool get companyInfoExists => _companyInfoExists.value;

  var organisationId = RxnString();
  var userName = 'User'.obs;
  var isLoading = true.obs;
  var userRole = Rx<UserRole?>(null);
  var organisation = Rxn<Organisation>();
  var organisations = <Organisation>[].obs; // For super admin - all organisations
  var salesPerson = Rxn<SalesPersonModel>(); // ✅ Cached sales person data

  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  AuthController()
      : _firestoreServices = Get.find<FirestoreServices>(),
        _cloudFunctionsService = Get.find<CloudFunctionsService>();

  @override
  void onInit() {
    super.onInit();

    // Get Snackbar controller if registered
    if (Get.isRegistered<SnackbarMessageController>()) {
      _snackbarController = Get.find<SnackbarMessageController>();
    }

    FirebaseAuth.instance.authStateChanges().listen((user) async {
      _isAuthenticated.value = user != null;

      if (user != null) {
        await loadUserProfile();
        // After loading profile, check if user is allowed
        if (!(isSuperAdmin || isSalesPerson)) {
          // Not allowed: logout, show message, and redirect
          await logout();
          _snackbarController?.showErrorMessage(
            'This portal is only for Super Admin and Sales Person accounts.'
          );
          // Redirect to welcome page using GoRouter
          final context = Get.context;
          if (context != null) {
            // Use context.go to force navigation
            // ignore: use_build_context_synchronously
            Future.delayed(Duration.zero, () {
              // ignore: use_build_context_synchronously
              context.go('/welcome');
            });
          }
        }
      } else {
        organisationId.value = null;
        userRole.value = null;
        organisation.value = null;
        organisations.clear();
        salesPerson.value = null; // ✅ Clear cached sales person data
      }

      isLoading.value = false;
    });
  }

  void setOrganisationInfoExists(bool value) {
    _companyInfoExists.value = value;
  }

  void setAuthenticated(bool value) {
    _isAuthenticated.value = value;
  }

  Future<void> fetchOrganisation() async {
    if (organisationId.value == null || organisationId.value!.isEmpty) {
      print('Organisation ID is null or empty, cannot fetch organisation');
      organisation.value = null;
      return;
    }

    try {
      print('Fetching organisation with ID: ${organisationId.value}');
      final org = await _firestoreServices.getOrganisation(organisationId.value!);
      organisation.value = org;
      print('Organisation fetched successfully: ${org.name}');
    } catch (e) {
      print('Error fetching organisation: $e');
      organisation.value = null;
    }
  }



  // ───────────────────────────────────────────────────────────────
  // NEW: check org by looking at Firestore users/{uid}
  // ───────────────────────────────────────────────────────────────

  Future<void> checkOrganisationForCurrentUser() async {
    final user = firebaseAuth.currentUser;
    print('Current user: ${user?.uid}');
    if (user == null) {
      _companyInfoExists.value = false;
      organisationId.value = null;
      return;
    }

    // Prefer Firestore users/{uid}.organisationId
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = userDoc.data();
    final orgIdFromUser = data?['organisationId'] as String?;

    if (orgIdFromUser != null && orgIdFromUser.isNotEmpty) {
      organisationId.value = orgIdFromUser;
      _companyInfoExists.value = true;
      print('✅ Found organisationId on users/${user.uid}: $orgIdFromUser');
      return;
    }

    // Optional cloud function fallback (can also be removed later)
    final response = await _cloudFunctionsService.checkOrganisationInfo();
    _companyInfoExists.value = response.hasOrganisation;
    organisationId.value = response.organisationId;
  }

  bool get isAuthenticatedAndVerified {
    final currentUser = FirebaseAuth.instance.currentUser;
    return currentUser != null && currentUser.emailVerified;
  }

  Future<void> loadUserProfile() async {
    final currentUser = firebaseAuth.currentUser;
    if (currentUser == null) return;

    try {
      // First, check if user is a sales person by email
      try {
        final fetchedSalesPerson = await _salesPeopleServices.getSalesPersonByEmail(
          currentUser.email ?? '',
        );
        if (fetchedSalesPerson != null && fetchedSalesPerson.isActive && !fetchedSalesPerson.isDisabled) {
          // User is an active sales person
          print('✅ User is an active sales person: ${fetchedSalesPerson.name}');
          salesPerson.value = fetchedSalesPerson; // ✅ Cache the sales person data
          userRole.value = UserRole.salesPerson;
          organisationId.value = null;
          _companyInfoExists.value = false;
          organisation.value = null;
          // Sales people can view all organisations (like super admins)
          try {
            organisations.value = await _firestoreServices.getAllOrganisations();
            print('✅ Loaded ${organisations.length} organisations for sales person');
          } catch (e) {
            print('❌ Error fetching organisations for sales person: $e');
            organisations.clear();
          }
          return;
        } else {
          // Not a sales person or inactive - clear cached data
          salesPerson.value = null;
        }
      } catch (e) {
        print('⚠️ Error checking sales_people collection: $e');
        salesPerson.value = null;
        // Continue to check users collection
      }

      // Not a sales person, check users collection
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) {
        // User exists in Firebase Auth but not in Firestore yet.
        // This only happens for FIRST signup before handleNewUser runs.
        userRole.value = null;
        organisationId.value = null;
        _companyInfoExists.value = false;
        organisation.value = null;
        return;
      }

      final data = userDoc.data()!;
      final roleString = data['role'] as String? ?? '';
      final orgId = data['organisationId'] as String?;

      // Use the extension method to properly convert from Firestore format
      userRole.value = UserRoleExtension.fromFirestore(roleString);
      organisationId.value = orgId;

      // Only super admin and sales person roles are supported
      final isSuperAdmin = userRole.value == UserRole.superAdmin;
      final isSalesPerson = userRole.value == UserRole.salesPerson;

      if (isSuperAdmin) {
        // Super admin: fetch all organisations
        try {
          organisations.value = await _firestoreServices.getAllOrganisations();
          _companyInfoExists.value = organisations.isNotEmpty;
          organisation.value = organisations.isNotEmpty ? organisations.first : null;
        } catch (e) {
          print('❌ Error fetching organisations for super admin: $e');
          organisations.clear();
          organisation.value = null;
          _companyInfoExists.value = false;
        }
      } else if (isSalesPerson) {
        // Sales person: already handled above
        // No further action needed
      } else {
        // Not a supported role
        userRole.value = null;
        organisationId.value = null;
        _companyInfoExists.value = false;
        organisation.value = null;
        organisations.clear();
        // Show friendly error message
        _snackbarController?.showErrorMessage('This portal is only for Super Admin and Sales Person accounts.');
      }
    } catch (e) {
      // Catch any Firestore or other exceptions and show a friendly message
      print('Error loading user profile: $e');
      userRole.value = null;
      organisationId.value = null;
      _companyInfoExists.value = false;
      organisation.value = null;
      organisations.clear();
      _snackbarController?.showErrorMessage('This portal is only for Super Admin and Sales Person accounts.');
    }
  }

// ...existing code...
  bool get isVerified =>
      firebaseAuth.currentUser != null &&
      firebaseAuth.currentUser!.emailVerified;

  bool get isSuperAdmin => userRole.value == UserRole.superAdmin;
  bool get isSalesPerson => userRole.value == UserRole.salesPerson;

  /// Super admin: Set selected organisation
  void setSelectedOrganisation(Organisation org) {
    organisation.value = org;
    organisationId.value = org.organisationId;
    print('✅ Super admin selected organisation: ${org.name} (ID: ${org.organisationId})');
  }

  /// Super admin: Clear selected organisation
  void clearSelectedOrganisation() {
    organisation.value = organisations.isNotEmpty ? organisations.first : null;
    organisationId.value = null;
    print('🧹 Cleared selected organisation for super admin');
  }

  Future<void> logout() async {
    await firebaseAuth.signOut();

    organisationId.value = null;
    userRole.value = null;
    organisation.value = null;
    organisations.clear();
    salesPerson.value = null; // ✅ Clear cached sales person data
  }
}
