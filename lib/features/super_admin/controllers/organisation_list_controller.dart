import 'package:get/get.dart';
import 'package:trax_admin_portal/controller/auth_controller/auth_controller.dart';
import 'package:trax_admin_portal/models/organisation.dart';
import 'package:trax_admin_portal/utils/enums/sort_type.dart';

/// Controller for managing organization list with search and sort functionality
class OrganisationListController extends GetxController {
  final AuthController authController = Get.find<AuthController>();
  
  RxList<Organisation> filteredOrganisations = <Organisation>[].obs;
  
  @override
  void onInit() {
    super.onInit();
    // Initialize filtered list with all organizations, sorted A-Z by default (case-insensitive)
    final orgs = List<Organisation>.from(authController.organisations);
    orgs.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    filteredOrganisations.assignAll(orgs);
  }

  /// Filters organizations based on search text, matching organization names
  /// Case-insensitive search that updates filteredOrganisations in real-time
  void filterOrganisations(String value) {
    final orgs = authController.organisations;
    
    if (value.isEmpty) {
      filteredOrganisations.assignAll(orgs);
    } else {
      filteredOrganisations.assignAll(
        orgs.where((org) => 
          org.name.toLowerCase().contains(value.toLowerCase())
        )
      );
      print('Filtered organisations count: ${filteredOrganisations.length}');
    }
  }

  /// Sorts the filtered organizations list based on the specified sort type
  /// Supports sorting by name (A-Z/Z-A) - case-insensitive
  void sortOrganisations(SortType sortType) {
    switch (sortType) {
      case SortType.nameAZ:
        filteredOrganisations.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case SortType.nameZA:
        filteredOrganisations.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case SortType.dateNewest:
      case SortType.dateOldest:
        // Date sorting not applicable for organizations
        break;
    }
  }

  /// Clears the search filter and shows all organizations
  void clearFilter() {
    filteredOrganisations.assignAll(authController.organisations);
  }
}
