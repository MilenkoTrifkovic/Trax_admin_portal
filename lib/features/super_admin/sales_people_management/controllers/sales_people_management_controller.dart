import 'package:get/get.dart';
import 'package:trax_admin_portal/controller/global_controllers/snackbar_message_controller.dart';
import 'package:trax_admin_portal/models/sales_person_model.dart';
import 'package:trax_admin_portal/services/sales_people_management_services.dart';

/// Controller for managing sales people
class SalesPeopleManagementController extends GetxController {
  final SalesPeopleManagementServices _salesPeopleServices = SalesPeopleManagementServices();
  final SnackbarMessageController _snackbarController = Get.find<SnackbarMessageController>();
  
  var isLoading = false.obs;
  RxList<SalesPersonModel> salesPeople = <SalesPersonModel>[].obs;
  
  @override
  void onInit() {
    super.onInit();
    _loadSalesPeople();
  }
  
  /// Load sales people from database
  Future<void> _loadSalesPeople() async {
    try {
      isLoading.value = true;
      final fetchedSalesPeople = await _salesPeopleServices.getAllSalesPeople();
      salesPeople.value = fetchedSalesPeople;
      print('Loaded ${salesPeople.length} sales people');
    } catch (e) {
      print('Error loading sales people: $e');
      _snackbarController.showErrorMessage('Failed to load sales people');
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Refresh sales people list
  Future<void> refreshSalesPeople() async {
    await _loadSalesPeople();
  }
  
  /// Add a new sales person
  Future<void> addSalesPerson(SalesPersonModel salesPerson) async {
    try {
      isLoading.value = true;
      final created = await _salesPeopleServices.createSalesPerson(salesPerson);
      salesPeople.add(created);
      _snackbarController.showSuccessMessage('Sales person added successfully');
    } catch (e) {
      print('Error adding sales person: $e');
      _snackbarController.showErrorMessage('Failed to add sales person');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Update an existing sales person
  Future<void> updateSalesPerson(SalesPersonModel salesPerson) async {
    try {
      isLoading.value = true;
      final updated = await _salesPeopleServices.updateSalesPerson(salesPerson);
      final index = salesPeople.indexWhere((p) => p.docId == updated.docId);
      if (index != -1) {
        salesPeople[index] = updated;
      }
      _snackbarController.showSuccessMessage('Sales person updated successfully');
    } catch (e) {
      print('Error updating sales person: $e');
      _snackbarController.showErrorMessage('Failed to update sales person');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Delete a sales person (soft delete)
  Future<void> deleteSalesPerson(String salesPersonId) async {
    try {
      isLoading.value = true;
      await _salesPeopleServices.deleteSalesPerson(salesPersonId);
      salesPeople.removeWhere((p) => p.docId == salesPersonId);
      _snackbarController.showSuccessMessage('Sales person deleted successfully');
    } catch (e) {
      print('Error deleting sales person: $e');
      _snackbarController.showErrorMessage('Failed to delete sales person');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Resend password setup email to a sales person
  Future<void> resendPasswordSetupEmail(SalesPersonModel salesPerson) async {
    try {
      isLoading.value = true;
      await _salesPeopleServices.resendPasswordSetupEmail(salesPerson);
      _snackbarController.showSuccessMessage('Password setup email sent to ${salesPerson.email}');
    } catch (e) {
      print('Error sending password setup email: $e');
      _snackbarController.showErrorMessage('Failed to send password setup email');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }
}
