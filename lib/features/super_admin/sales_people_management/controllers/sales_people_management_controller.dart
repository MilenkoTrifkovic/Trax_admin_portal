import 'package:get/get.dart';
import 'package:trax_admin_portal/models/sales_person_model.dart';
import 'package:trax_admin_portal/services/sales_people_management_services.dart';

/// Controller for managing sales people
class SalesPeopleManagementController extends GetxController {
  final SalesPeopleManagementServices _salesPeopleServices = SalesPeopleManagementServices();
  
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
      Get.snackbar(
        'Error',
        'Failed to load sales people: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
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
      Get.snackbar(
        'Success',
        'Sales person added successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('Error adding sales person: $e');
      Get.snackbar(
        'Error',
        'Failed to add sales person: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
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
      Get.snackbar(
        'Success',
        'Sales person updated successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('Error updating sales person: $e');
      Get.snackbar(
        'Error',
        'Failed to update sales person: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
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
      Get.snackbar(
        'Success',
        'Sales person deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('Error deleting sales person: $e');
      Get.snackbar(
        'Error',
        'Failed to delete sales person: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }
}
