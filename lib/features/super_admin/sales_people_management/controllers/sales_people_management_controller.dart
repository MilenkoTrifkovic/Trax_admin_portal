import 'package:get/get.dart';
import 'package:trax_admin_portal/controller/global_controllers/snackbar_message_controller.dart';
import 'package:trax_admin_portal/features/super_admin/global_controllers/sales_people_global_controller.dart';
import 'package:trax_admin_portal/models/user_model.dart';

/// Local controller for managing sales people on the sales people management page.
/// This controller uses the global SalesPeopleGlobalController for data operations
/// and adds UI-specific logic and snackbar notifications.
/// 
/// Note: Sales people are now stored in the 'users' collection with role = salesPerson
class SalesPeopleManagementController extends GetxController {
  final SalesPeopleGlobalController _globalController = Get.find<SalesPeopleGlobalController>();
  final SnackbarMessageController _snackbarController = Get.find<SnackbarMessageController>();

  // ═══════════════════════════════════════════════════════════════════════
  // Getters that delegate to global controller
  // ═══════════════════════════════════════════════════════════════════════

  /// Get loading state from global controller
  bool get isLoading => _globalController.isLoading.value;

  /// Get sales people list from global controller
  RxList<UserModel> get salesPeople => _globalController.salesPeople;

  // ═══════════════════════════════════════════════════════════════════════
  // Methods that delegate to global controller with UI feedback
  // ═══════════════════════════════════════════════════════════════════════

  /// Refresh sales people list
  Future<void> refreshSalesPeople() async {
    await _globalController.refreshSalesPeople();
  }

  /// Add a new sales person
  Future<void> addSalesPerson(UserModel salesPerson) async {
    try {
      await _globalController.addSalesPerson(salesPerson);
      _snackbarController.showSuccessMessage('Sales person added successfully');
    } catch (e) {
      print('Error adding sales person: $e');
      _snackbarController.showErrorMessage('Failed to add sales person');
      rethrow;
    }
  }

  /// Update an existing sales person
  Future<void> updateSalesPerson(UserModel salesPerson) async {
    try {
      await _globalController.updateSalesPerson(salesPerson);
      _snackbarController.showSuccessMessage('Sales person updated successfully');
    } catch (e) {
      print('Error updating sales person: $e');
      _snackbarController.showErrorMessage('Failed to update sales person');
      rethrow;
    }
  }

  /// Delete a sales person (soft delete)
  Future<void> deleteSalesPerson(String salesPersonId) async {
    try {
      await _globalController.deleteSalesPerson(salesPersonId);
      _snackbarController.showSuccessMessage('Sales person deleted successfully');
    } catch (e) {
      print('Error deleting sales person: $e');
      _snackbarController.showErrorMessage('Failed to delete sales person');
      rethrow;
    }
  }

  /// Resend password setup email to a sales person
  Future<void> resendPasswordSetupEmail(UserModel salesPerson) async {
    try {
      await _globalController.resendPasswordSetupEmail(salesPerson);
      _snackbarController.showSuccessMessage('Password setup email sent to ${salesPerson.email}');
    } catch (e) {
      print('Error sending password setup email: $e');
      _snackbarController.showErrorMessage('Failed to send password setup email');
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

  /// Copy reference code to clipboard
  void copyRefCode(String refCode) {
    _snackbarController.showSuccessMessage('Reference code "$refCode" copied to clipboard');
  }
}
