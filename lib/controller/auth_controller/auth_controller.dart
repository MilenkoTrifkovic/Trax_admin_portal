import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:trax_admin_portal/models/organisation.dart';
import 'package:trax_admin_portal/models/sales_person_model.dart';
import 'package:trax_admin_portal/services/firestore_services/firestore_services.dart';
import 'package:trax_admin_portal/services/shared_pref_services.dart';
import 'package:trax_admin_portal/services/cloud_functions_services.dart';
import 'package:trax_admin_portal/services/sales_people_management_services.dart';
import 'package:trax_admin_portal/utils/enums/user_type.dart';

class AuthController extends GetxController {
  late final FirestoreServices _firestoreServices;
  late final SharedPrefServices _sharedPrefServices;
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
      : _sharedPrefServices = Get.find<SharedPrefServices>(),
        _firestoreServices = Get.find<FirestoreServices>(),
        _cloudFunctionsService = Get.find<CloudFunctionsService>() {}

  @override
  void onInit() {
    super.onInit();

    FirebaseAuth.instance.authStateChanges().listen((user) async {
      _isAuthenticated.value = user != null;

      if (user != null) {
        await loadUserProfile();
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

  /*  Future<void> checkCompanyInfo() async {
    if (!isAuthenticatedAndVerified) {
      print(
          'User not authenticated or not verified, skipping company info check');
      _companyInfoExists.value = false; // ✅ use RxBool
      return;
    }

    try {
      print('Checking company info existence...');

      final response = await _cloudFunctionsService.checkOrganisationInfo();
      print('Company info check response: $response');

      _companyInfoExists.value = response.hasOrganisation; // ✅
      print('Company info exists? ${_companyInfoExists.value}');
      print('response- hasOrganisation: ${response.hasOrganisation}');

      userRole.value = response.role != null
          ? UserRoleExtension.fromFirestore(response.role!)
          : null;
      organisationId = response.organisationId;
      print('Company info exists: ${response.hasOrganisation}');

      if (organisationId != null && organisationId!.isNotEmpty) {
        await fetchOrganisation();
      }
    } catch (e) {
      print('Error checking company info: $e');
      _companyInfoExists.value = false; // ✅
    }
  } */

  /*  Future<void> refreshCompanyInfo() async {
    await checkCompanyInfo();
  } */

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
      userRole.value = UserRole.guest;
      organisationId.value = null;
      _companyInfoExists.value = false;
      organisation.value = null;
      return;
    }

    final data = userDoc.data()!;
    final roleString = data['role'] as String? ?? 'guest';
    final orgId = data['organisationId'] as String?;

    // Use the extension method to properly convert from Firestore format
    userRole.value = UserRoleExtension.fromFirestore(roleString);

    organisationId.value = orgId;

    // Check if user is super admin
    final isSuperAdmin = userRole.value == UserRole.superAdmin;

    if (isSuperAdmin) {
      // Super admin: fetch all organisations
      try {
        organisations.value = await _firestoreServices.getAllOrganisations();
        
        // For super admin, companyInfoExists is true if there are any organisations
        _companyInfoExists.value = organisations.isNotEmpty;
        
        // Set the first organisation as the current one (if any exist)
        organisation.value = organisations.isNotEmpty ? organisations.first : null;
      } catch (e) {
        print('❌ Error fetching organisations for super admin: $e');
        organisations.clear();
        organisation.value = null;
        _companyInfoExists.value = false;
      }
    } else {
      // Regular users: fetch only their organisation
      _companyInfoExists.value =
          organisationId.value != null && organisationId.value!.isNotEmpty;

      if (organisationId.value != null && organisationId.value!.isNotEmpty) {
        try {
          organisation.value =
              await _firestoreServices.getOrganisation(organisationId.value!);
          organisations.clear(); // Clear any previous super admin data
        } catch (e) {
          print('❌ Error fetching organisation: $e');
          organisation.value = null;
        }
      } else {
        organisation.value = null;
        organisations.clear();
      }
    }
  }

/*   Future<void> loadUserProfile() async {
    final currentUser = firebaseAuth.currentUser;
    if (currentUser == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();

    if (!userDoc.exists) {
      // User exists in Firebase Auth but not in Firestore yet.
      // This only happens for FIRST signup before handleNewUser runs.
      userRole.value = UserRole.guest;
      organisationId = null;
      return;
    }

    final data = userDoc.data()!;
    final roleString = data['role'] as String? ?? 'guest';
    final orgId = data['organisationId'] as String?;

    // Use the extension method to properly convert from Firestore format
    userRole.value = UserRoleExtension.fromFirestore(roleString);

    organisationId = orgId;

    // Load organisation details if exists
    if (organisationId != null && organisationId!.isNotEmpty) {
      try {
        organisation.value =
            await FirestoreServices().getOrganisation(organisationId!);
      } catch (_) {
        organisation.value = null;
      }
    }
  }
 */
  bool get isVerified =>
      firebaseAuth.currentUser != null &&
      firebaseAuth.currentUser!.emailVerified;

  bool get isSuperAdmin => userRole.value == UserRole.superAdmin;
  
  bool get isRegularHost => 
      (userRole.value == UserRole.admin || userRole.value == UserRole.planner) && 
      companyInfoExists && 
      organisationId.value != null;

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
