import 'package:get/get.dart';
import 'package:trax_admin_portal/controller/global_controllers/snackbar_message_controller.dart';
import 'package:trax_admin_portal/models/company_summary.dart';
import 'package:trax_admin_portal/services/company_services.dart';

/// Controller for managing companies list and operations
class CompaniesController extends GetxController {
  final CompanyServices _companyServices = CompanyServices();
  final SnackbarMessageController _snackbarController =
      Get.find<SnackbarMessageController>();

  var isLoading = false.obs;
  RxList<CompanySummary> allCompanies = <CompanySummary>[].obs;
  RxList<CompanySummary> filteredCompanies = <CompanySummary>[].obs;

  var searchQuery = ''.obs;
  var selectedSalesPersonFilter = Rx<String?>(null);

  // Sorting state
  var sortColumn = Rx<String?>(null); // 'name', 'salesperson', 'events'
  var sortAscending = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadCompanies();
  }

  /// Load all companies with their event counts
  Future<void> loadCompanies() async {
    try {
      isLoading.value = true;
      final companies = await _companyServices.getAllCompaniesWithEventCounts();
      allCompanies.value = companies;
      _applyFilters();
      print('Loaded ${companies.length} companies');
    } catch (e) {
      print('Error loading companies: $e');
      _snackbarController.showErrorMessage('Failed to load companies');
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh companies list
  Future<void> refreshCompanies() async {
    await loadCompanies();
  }

  /// Filter companies by search query and salesperson
  void _applyFilters() {
    var filtered = allCompanies.toList();

    // Apply search filter
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      filtered = filtered.where((company) {
        return company.companyName.toLowerCase().contains(query);
      }).toList();
    }

    // Apply salesperson filter
    if (selectedSalesPersonFilter.value != null) {
      filtered = filtered.where((company) {
        return company.salesPersonId == selectedSalesPersonFilter.value;
      }).toList();
    }

    // Apply sorting
    if (sortColumn.value != null) {
      _sortCompanies(filtered);
    }

    filteredCompanies.value = filtered;
  }

  /// Sort companies by specified column
  void _sortCompanies(List<CompanySummary> companies) {
    switch (sortColumn.value) {
      case 'name':
        companies.sort((a, b) {
          final comparison = a.companyName.toLowerCase().compareTo(b.companyName.toLowerCase());
          return sortAscending.value ? comparison : -comparison;
        });
        break;
      case 'salesperson':
        companies.sort((a, b) {
          final aName = a.salesPersonName?.toLowerCase() ?? '';
          final bName = b.salesPersonName?.toLowerCase() ?? '';
          final comparison = aName.compareTo(bName);
          return sortAscending.value ? comparison : -comparison;
        });
        break;
      case 'events':
        companies.sort((a, b) {
          final comparison = a.eventCount.compareTo(b.eventCount);
          return sortAscending.value ? comparison : -comparison;
        });
        break;
    }
  }

  /// Toggle sort for a column
  void toggleSort(String column) {
    if (sortColumn.value == column) {
      // Same column - toggle direction
      sortAscending.value = !sortAscending.value;
    } else {
      // New column - set to ascending
      sortColumn.value = column;
      sortAscending.value = true;
    }
    _applyFilters();
  }

  /// Update search query
  void updateSearchQuery(String query) {
    searchQuery.value = query;
    _applyFilters();
  }

  /// Update salesperson filter
  void updateSalesPersonFilter(String? salesPersonId) {
    selectedSalesPersonFilter.value = salesPersonId;
    _applyFilters();
  }

  /// Clear all filters
  void clearFilters() {
    searchQuery.value = '';
    selectedSalesPersonFilter.value = null;
    sortColumn.value = null;
    sortAscending.value = true;
    _applyFilters();
  }

  /// Get unique salespeople from companies
  List<Map<String, String>> getUniqueSalesPeople() {
    final Set<String> seen = {};
    final List<Map<String, String>> salesPeople = [];

    for (var company in allCompanies) {
      if (company.salesPersonId != null &&
          company.salesPersonName != null &&
          !seen.contains(company.salesPersonId)) {
        seen.add(company.salesPersonId!);
        salesPeople.add({
          'id': company.salesPersonId!,
          'name': company.salesPersonName!,
        });
      }
    }

    return salesPeople;
  }

  /// Get total number of events across all companies
  int getTotalEventCount() {
    return allCompanies.fold(0, (sum, company) => sum + company.eventCount);
  }

  /// Assign salesperson to company
  Future<void> assignSalesPerson(
      String organisationId, String salesPersonId) async {
    try {
      isLoading.value = true;
      await _companyServices.assignSalesPersonToCompany(
          organisationId, salesPersonId);
      await refreshCompanies();
      _snackbarController
          .showSuccessMessage('Salesperson assigned successfully');
    } catch (e) {
      print('Error assigning salesperson: $e');
      _snackbarController.showErrorMessage('Failed to assign salesperson');
    } finally {
      isLoading.value = false;
    }
  }

  /// Remove salesperson from company
  Future<void> removeSalesPerson(String organisationId) async {
    try {
      isLoading.value = true;
      await _companyServices.removeSalesPersonFromCompany(organisationId);
      await refreshCompanies();
      _snackbarController
          .showSuccessMessage('Salesperson removed successfully');
    } catch (e) {
      print('Error removing salesperson: $e');
      _snackbarController.showErrorMessage('Failed to remove salesperson');
    } finally {
      isLoading.value = false;
    }
  }
}
