import 'package:get/get.dart';
import 'package:trax_admin_portal/models/super_admin_model.dart';
import 'package:trax_admin_portal/services/super_admin_management_services.dart';

/// Global controller for managing super admins across the application.
///
/// This controller maintains the global state of super admins and provides
/// methods for CRUD operations. It's registered as permanent and shared
/// across all screens that need super admin data.
///
/// Used by:
/// - SuperAdminManagementController (local page controller)
/// - Any other feature that needs super admin data
class SuperAdminsGlobalController extends GetxController {
  final SuperAdminManagementServices _services = SuperAdminManagementServices();

  // ═══════════════════════════════════════════════════════════════════════
  // Observable State
  // ═══════════════════════════════════════════════════════════════════════

  /// List of all super admins
  final RxList<SuperAdminModel> superAdmins = <SuperAdminModel>[].obs;

  /// Loading state
  final RxBool isLoading = false.obs;

  /// Error message (if any)
  final RxnString errorMessage = RxnString();

  // ═══════════════════════════════════════════════════════════════════════
  // Lifecycle
  // ═══════════════════════════════════════════════════════════════════════

  @override
  void onInit() {
    super.onInit();
    print('SuperAdminsGlobalController initialized');
    // Load super admins on init
    refreshSuperAdmins();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Public Methods
  // ═══════════════════════════════════════════════════════════════════════

  /// Refresh the list of super admins from Firestore
  Future<void> refreshSuperAdmins() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;

      final fetchedSuperAdmins = await _services.getAllSuperAdmins(
        includeDisabled: true, // Show disabled admins so they can be re-enabled
        includeDeleted: false,
      );

      superAdmins.value = fetchedSuperAdmins;
      print('Refreshed super admins: ${superAdmins.length} items');
    } catch (e) {
      print('Error refreshing super admins: $e');
      errorMessage.value = 'Failed to load super admins';
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Add a new super admin
  Future<void> addSuperAdmin(SuperAdminModel superAdmin) async {
    try {
      isLoading.value = true;
      errorMessage.value = null;

      final created = await _services.createSuperAdmin(superAdmin);

      // Add to list
      superAdmins.add(created);
      print('Added super admin to list: ${created.email}');
    } catch (e) {
      print('Error adding super admin: $e');
      errorMessage.value = 'Failed to add super admin';
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Update an existing super admin
  Future<void> updateSuperAdmin(SuperAdminModel superAdmin) async {
    try {
      isLoading.value = true;
      errorMessage.value = null;

      await _services.updateSuperAdmin(superAdmin);

      // Update in list
      final index =
          superAdmins.indexWhere((sa) => sa.docId == superAdmin.docId);
      if (index != -1) {
        superAdmins[index] = superAdmin;
        print('Updated super admin in list: ${superAdmin.email}');
      }
    } catch (e) {
      print('Error updating super admin: $e');
      errorMessage.value = 'Failed to update super admin';
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Disable a super admin (soft delete)
  Future<void> disableSuperAdmin(String email) async {
    try {
      isLoading.value = true;
      errorMessage.value = null;

      await _services.setDisabledStatus(email, true);

      // Update the admin in the list to reflect disabled status
      final index = superAdmins.indexWhere((sa) => sa.email == email);
      if (index != -1) {
        superAdmins[index] = superAdmins[index].copyWith(isDisabled: true);
      }
      print('Disabled super admin: $email');
    } catch (e) {
      print('Error disabling super admin: $e');
      errorMessage.value = 'Failed to disable super admin';
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Enable a super admin
  Future<void> enableSuperAdmin(String email) async {
    try {
      isLoading.value = true;
      errorMessage.value = null;

      await _services.setDisabledStatus(email, false);

      // Update the admin in the list to reflect enabled status
      final index = superAdmins.indexWhere((sa) => sa.email == email);
      if (index != -1) {
        superAdmins[index] = superAdmins[index].copyWith(isDisabled: false);
      }
      print('Enabled super admin: $email');
    } catch (e) {
      print('Error enabling super admin: $e');
      errorMessage.value = 'Failed to enable super admin';
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Delete a super admin (soft delete)
  Future<void> deleteSuperAdmin(String email) async {
    try {
      isLoading.value = true;
      errorMessage.value = null;

      await _services.setDeletedStatus(email, true);

      // Remove from list (since we filter out deleted ones)
      superAdmins.removeWhere((sa) => sa.email == email);
      print('Deleted super admin: $email');
    } catch (e) {
      print('Error deleting super admin: $e');
      errorMessage.value = 'Failed to delete super admin';
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Restore a deleted super admin
  Future<void> restoreSuperAdmin(String email) async {
    try {
      isLoading.value = true;
      errorMessage.value = null;

      await _services.setDeletedStatus(email, false);

      // Refresh list to include the newly restored admin
      await refreshSuperAdmins();
      print('Restored super admin: $email');
    } catch (e) {
      print('Error restoring super admin: $e');
      errorMessage.value = 'Failed to restore super admin';
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Resend password setup email to a super admin
  Future<void> resendPasswordSetupEmail(SuperAdminModel superAdmin) async {
    try {
      isLoading.value = true;
      errorMessage.value = null;

      await _services.resendPasswordSetupEmail(superAdmin);
      print('Resent password setup email to: ${superAdmin.email}');
    } catch (e) {
      print('Error resending password setup email: $e');
      errorMessage.value = 'Failed to resend password setup email';
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Reset password for a super admin
  Future<void> resetPassword(String email) async {
    try {
      isLoading.value = true;
      errorMessage.value = null;

      await _services.resetPassword(email);
      print('Password reset email sent to: $email');
    } catch (e) {
      print('Error sending password reset email: $e');
      errorMessage.value = 'Failed to send password reset email';
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Get a super admin by ID
  Future<SuperAdminModel?> getSuperAdminById(String superAdminId) async {
    try {
      return await _services.getSuperAdminById(superAdminId);
    } catch (e) {
      print('Error fetching super admin by ID: $e');
      return null;
    }
  }
}
