import 'package:get/get.dart';
import 'package:trax_admin_portal/models/sales_person_model.dart';
import 'package:trax_admin_portal/services/sales_people_management_services.dart';

/// Global controller for managing sales people data across the entire app.
/// This controller is initialized in the shell route navigation wrapper and
/// maintains the sales people list throughout the app lifecycle.
/// 
/// Usage:
/// - Local controllers should use this instead of directly calling services
/// - Provides reactive access to sales people data
/// - Ensures data consistency across features
class SalesPeopleGlobalController extends GetxController {
  final SalesPeopleManagementServices _salesPeopleServices = SalesPeopleManagementServices();

  var isLoading = false.obs;
  var isInitialized = false.obs;
  RxList<SalesPersonModel> salesPeople = <SalesPersonModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadSalesPeople();
  }

  /// Load sales people from database
  Future<void> loadSalesPeople() async {
    try {
      isLoading.value = true;
      final fetchedSalesPeople = await _salesPeopleServices.getAllSalesPeople();
      salesPeople.value = fetchedSalesPeople;
      isInitialized.value = true;
      print('✅ Global: Loaded ${salesPeople.length} sales people');
    } catch (e) {
      print('❌ Global: Error loading sales people: $e');
      // Don't rethrow - allow app to continue even if sales people can't be loaded
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh sales people list
  Future<void> refreshSalesPeople() async {
    await loadSalesPeople();
  }

  /// Add a new sales person
  Future<SalesPersonModel> addSalesPerson(SalesPersonModel salesPerson) async {
    try {
      isLoading.value = true;
      final created = await _salesPeopleServices.createSalesPerson(salesPerson);
      salesPeople.add(created);
      print('✅ Global: Sales person added: ${created.name}');
      return created;
    } catch (e) {
      print('❌ Global: Error adding sales person: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Update an existing sales person
  Future<SalesPersonModel> updateSalesPerson(SalesPersonModel salesPerson) async {
    try {
      isLoading.value = true;
      final updated = await _salesPeopleServices.updateSalesPerson(salesPerson);
      final index = salesPeople.indexWhere((p) => p.docId == updated.docId);
      if (index != -1) {
        salesPeople[index] = updated;
        print('✅ Global: Sales person updated: ${updated.name}');
      }
      return updated;
    } catch (e) {
      print('❌ Global: Error updating sales person: $e');
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
      print('✅ Global: Sales person deleted: $salesPersonId');
    } catch (e) {
      print('❌ Global: Error deleting sales person: $e');
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
      print('✅ Global: Password setup email sent to: ${salesPerson.email}');
    } catch (e) {
      print('❌ Global: Error sending password setup email: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Getters for convenient access
  // ═══════════════════════════════════════════════════════════════════════

  /// Get a sales person by ID
  SalesPersonModel? getSalesPersonById(String salesPersonId) {
    try {
      return salesPeople.firstWhere((sp) => sp.docId == salesPersonId);
    } catch (e) {
      return null;
    }
  }

  /// Get a sales person by email
  SalesPersonModel? getSalesPersonByEmail(String email) {
    try {
      return salesPeople.firstWhere(
        (sp) => sp.email.toLowerCase() == email.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get all active sales people
  List<SalesPersonModel> get activeSalesPeople {
    return salesPeople.where((sp) => sp.isActive && !sp.isDisabled).toList();
  }

  /// Get all inactive sales people
  List<SalesPersonModel> get inactiveSalesPeople {
    return salesPeople.where((sp) => !sp.isActive || sp.isDisabled).toList();
  }

  /// Get sales people count
  int get salesPeopleCount => salesPeople.length;

  /// Get active sales people count
  int get activeSalesPeopleCount => activeSalesPeople.length;

  /// Check if sales people data is loaded
  bool get hasData => salesPeople.isNotEmpty;

  /// Get sales people as a map for dropdowns (id -> name)
  Map<String, String> get salesPeopleMap {
    return {
      for (var sp in activeSalesPeople) sp.docId: sp.name,
    };
  }

  /// Get sales people for dropdown with id and name
  List<Map<String, String>> get salesPeopleForDropdown {
    return activeSalesPeople.map((sp) {
      return {
        'id': sp.docId,
        'name': sp.name,
        'email': sp.email,
      };
    }).toList();
  }
}
