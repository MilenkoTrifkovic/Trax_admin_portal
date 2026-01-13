import 'package:get/get.dart';
import 'package:trax_admin_portal/controller/auth_controller/auth_controller.dart';
import 'package:trax_admin_portal/controller/global_controllers/snackbar_message_controller.dart';
import 'package:trax_admin_portal/features/super_admin/companies/controllers/companies_controller.dart';
import 'package:trax_admin_portal/models/company_summary.dart';
import 'package:trax_admin_portal/services/company_services.dart';

/// Controller for Super Admin Event List Screen
/// Handles business logic for displaying company info and managing salesperson assignments
class SuperAdminEventListController extends GetxController {
  final CompanyServices _companyServices = CompanyServices();
  final AuthController _authController = Get.find<AuthController>();
  final SnackbarMessageController _snackbarController =
      Get.find<SnackbarMessageController>();

  var isLoadingCompanySummary = false.obs;
  var isAssigningSalesPerson = false.obs;
  var isEditingSalesPerson = false.obs;
  Rx<CompanySummary?> companySummary = Rx<CompanySummary?>(null);
  Rx<String?> selectedSalesPersonId = Rx<String?>(null);

  @override
  void onInit() {
    super.onInit();
    // Listen to organisation changes and load company summary
    ever(_authController.organisationId, (organisationId) {
      if (organisationId != null) {
        loadCompanySummary(organisationId);
      } else {
        companySummary.value = null;
      }
    });

    // Load initial company summary if organisation is already selected
    if (_authController.organisationId.value != null) {
      loadCompanySummary(_authController.organisationId.value!);
    }
  }

  /// Start editing salesperson assignment
  void startEditingSalesPerson(String? currentSalesPersonId) {
    selectedSalesPersonId.value = currentSalesPersonId;
    isEditingSalesPerson.value = true;
  }

  /// Cancel editing salesperson assignment
  void cancelEditingSalesPerson() {
    isEditingSalesPerson.value = false;
    selectedSalesPersonId.value = null;
  }

  /// Update selected salesperson in dropdown (before saving)
  void updateSelectedSalesPerson(String? salesPersonId) {
    selectedSalesPersonId.value = salesPersonId;
  }

  /// Load company summary with event count and salesperson info
  Future<void> loadCompanySummary(String organisationId) async {
    try {
      isLoadingCompanySummary.value = true;
      final summary = await _companyServices.getCompanySummary(organisationId);
      companySummary.value = summary;
      if (summary != null) {
        print('✅ Loaded company summary: ${summary.companyName}');
      }
    } catch (e) {
      print('❌ Error loading company summary: $e');
      _snackbarController.showErrorMessage('Failed to load company information');
      companySummary.value = null;
    } finally {
      isLoadingCompanySummary.value = false;
    }
  }

  /// Refresh company summary for current organisation
  Future<void> refreshCompanySummary() async {
    final orgId = _authController.organisationId.value;
    if (orgId != null) {
      await loadCompanySummary(orgId);
    }
  }

  /// Assign salesperson to the current organisation
  Future<void> assignSalesPersonToCompany(
    String organisationId,
    String salesPersonId,
  ) async {
    try {
      isAssigningSalesPerson.value = true;
      await _companyServices.assignSalesPersonToCompany(
        organisationId,
        salesPersonId,
      );
      
      // Reload company summary to get updated data
      await loadCompanySummary(organisationId);
      
      // Refresh companies list if CompaniesController is available
      _refreshCompaniesListIfAvailable();
      
      _snackbarController.showSuccessMessage('Salesperson assigned successfully');
      print('✅ Salesperson assigned to organisation: $organisationId');
    } catch (e) {
      print('❌ Error assigning salesperson: $e');
      _snackbarController.showErrorMessage('Failed to assign salesperson');
      rethrow; // Let the UI handle the error state
    } finally {
      isAssigningSalesPerson.value = false;
    }
  }

  /// Remove salesperson from the current organisation
  Future<void> removeSalesPersonFromCompany(String organisationId) async {
    try {
      isAssigningSalesPerson.value = true;
      await _companyServices.removeSalesPersonFromCompany(organisationId);
      
      // Reload company summary to get updated data
      await loadCompanySummary(organisationId);
      
      // Refresh companies list if CompaniesController is available
      _refreshCompaniesListIfAvailable();
      
      _snackbarController.showSuccessMessage('Salesperson removed successfully');
      print('✅ Salesperson removed from organisation: $organisationId');
    } catch (e) {
      print('❌ Error removing salesperson: $e');
      _snackbarController.showErrorMessage('Failed to remove salesperson');
      rethrow; // Let the UI handle the error state
    } finally {
      isAssigningSalesPerson.value = false;
    }
  }

  /// Refresh companies list if CompaniesController is available
  void _refreshCompaniesListIfAvailable() {
    try {
      // Try to find CompaniesController (it may not exist if we're not on companies page)
      if (Get.isRegistered<CompaniesController>()) {
        final companiesController = Get.find<CompaniesController>();
        companiesController.refreshCompanies();
        print('🔄 Triggered refresh of companies list');
      }
    } catch (e) {
      // CompaniesController not available, no need to refresh
      print('ℹ️ CompaniesController not available for refresh');
    }
  }

  /// Handle salesperson change (assign, change, or remove)
  /// Returns true if successful, false if error occurred
  Future<bool> handleSalesPersonChange(
    String organisationId,
    String? salesPersonId,
  ) async {
    if (isAssigningSalesPerson.value) {
      return false; // Already processing
    }

    try {
      isAssigningSalesPerson.value = true;

      if (salesPersonId == null || salesPersonId.isEmpty || salesPersonId == 'none') {
        // Remove salesperson
        await removeSalesPersonFromCompany(organisationId);
      } else {
        // Assign/change salesperson
        await assignSalesPersonToCompany(organisationId, salesPersonId);
      }

      // Success - close edit mode
      isEditingSalesPerson.value = false;
      selectedSalesPersonId.value = null;
      return true;
    } catch (e) {
      // Error already logged and snackbar shown by sub-methods
      return false;
    } finally {
      isAssigningSalesPerson.value = false;
    }
  }

  /// Clear selected organisation and return to companies list
  void clearSelectedOrganisation() {
    _authController.clearSelectedOrganisation();
    companySummary.value = null;
    print('✅ Cleared selected organisation');
  }

  /// Check if an organisation is currently selected
  bool get hasSelectedOrganisation =>
      _authController.organisationId.value != null;

  /// Get the currently selected organisation ID
  String? get selectedOrganisationId => _authController.organisationId.value;

  /// Check if current user is allowed to edit salesperson assignments
  /// Only super admins can edit, sales people and others have read-only access
  bool get canEditSalesPerson => _authController.isSuperAdmin;
}
