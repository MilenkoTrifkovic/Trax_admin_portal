import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:trax_admin_portal/controller/global_controllers/snackbar_message_controller.dart';
import 'package:trax_admin_portal/features/super_admin/global_controllers/super_admins_global_controller.dart';
import 'package:trax_admin_portal/models/super_admin_model.dart';

/// Local controller for managing super admins on the super admin management page.
/// This controller uses the global SuperAdminsGlobalController for data operations
/// and adds UI-specific logic and snackbar notifications.
class SuperAdminManagementController extends GetxController {
  final SuperAdminsGlobalController _globalController =
      Get.find<SuperAdminsGlobalController>();
  final SnackbarMessageController _snackbarController =
      Get.find<SnackbarMessageController>();

  // ═══════════════════════════════════════════════════════════════════════
  // Getters that delegate to global controller
  // ═══════════════════════════════════════════════════════════════════════

  /// Get loading state from global controller
  bool get isLoading => _globalController.isLoading.value;

  /// Get super admins list from global controller
  RxList<SuperAdminModel> get superAdmins => _globalController.superAdmins;

  // ═══════════════════════════════════════════════════════════════════════
  // Methods that delegate to global controller with UI feedback
  // ═══════════════════════════════════════════════════════════════════════

  /// Refresh super admins list
  Future<void> refreshSuperAdmins() async {
    await _globalController.refreshSuperAdmins();
  }

  /// Add a new super admin
  Future<void> addSuperAdmin(SuperAdminModel superAdmin) async {
    try {
      await _globalController.addSuperAdmin(superAdmin);
      _snackbarController.showSuccessMessage('Super admin added successfully');
    } catch (e) {
      print('Error adding super admin: $e');
      _snackbarController.showErrorMessage('Failed to add super admin');
      rethrow;
    }
  }

  /// Update an existing super admin
  Future<void> updateSuperAdmin(SuperAdminModel superAdmin) async {
    try {
      await _globalController.updateSuperAdmin(superAdmin);
      _snackbarController
          .showSuccessMessage('Super admin updated successfully');
    } catch (e) {
      print('Error updating super admin: $e');
      _snackbarController.showErrorMessage('Failed to update super admin');
      rethrow;
    }
  }

  /// Disable a super admin (soft delete)
  Future<void> disableSuperAdmin(String email) async {
    try {
      await _globalController.disableSuperAdmin(email);
      _snackbarController
          .showSuccessMessage('Super admin disabled successfully');
    } catch (e) {
      print('Error disabling super admin: $e');
      _snackbarController.showErrorMessage('Failed to disable super admin');
      rethrow;
    }
  }

  /// Enable a super admin
  Future<void> enableSuperAdmin(String email) async {
    try {
      await _globalController.enableSuperAdmin(email);
      _snackbarController
          .showSuccessMessage('Super admin enabled successfully');
    } catch (e) {
      print('Error enabling super admin: $e');
      _snackbarController.showErrorMessage('Failed to enable super admin');
      rethrow;
    }
  }

  /// Delete a super admin (soft delete)
  Future<void> deleteSuperAdmin(String email) async {
    try {
      await _globalController.deleteSuperAdmin(email);
      _snackbarController
          .showSuccessMessage('Super admin deleted successfully');
    } catch (e) {
      print('Error deleting super admin: $e');
      _snackbarController.showErrorMessage('Failed to delete super admin');
      rethrow;
    }
  }

  /// Restore a deleted super admin
  Future<void> restoreSuperAdmin(String email) async {
    try {
      await _globalController.restoreSuperAdmin(email);
      _snackbarController
          .showSuccessMessage('Super admin restored successfully');
    } catch (e) {
      print('Error restoring super admin: $e');
      _snackbarController.showErrorMessage('Failed to restore super admin');
      rethrow;
    }
  }

  /// Resend password setup email to a super admin
  Future<void> resendPasswordSetupEmail(SuperAdminModel superAdmin) async {
    try {
      await _globalController.resendPasswordSetupEmail(superAdmin);
      _snackbarController.showSuccessMessage(
          'Password setup email sent to ${superAdmin.email}');
    } catch (e) {
      print('Error sending password setup email: $e');
      _snackbarController
          .showErrorMessage('Failed to send password setup email');
      rethrow;
    }
  }

  /// Reset password for a super admin
  Future<void> resetPassword(String email) async {
    try {
      await _globalController.resetPassword(email);
      _snackbarController
          .showSuccessMessage('Password reset email sent to $email');
    } catch (e) {
      print('Error sending password reset email: $e');
      _snackbarController
          .showErrorMessage('Failed to send password reset email');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // UI Helper Methods
  // ═══════════════════════════════════════════════════════════════════════

  /// Copy email to clipboard
  void copyEmail(String email) {
    _snackbarController.showSuccessMessage('Email copied to clipboard');
  }

  /// Check if the given super admin is the current logged-in user
  bool isCurrentUser(SuperAdminModel superAdmin) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;
    return currentUser.email?.toLowerCase() == superAdmin.email.toLowerCase();
  }
}
