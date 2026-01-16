import 'package:get/get.dart';
import 'package:trax_admin_portal/controller/auth_controller/auth_controller.dart';
import 'package:trax_admin_portal/services/dashboard_services.dart';

/// Controller for managing dashboard state and data
class DashboardController extends GetxController {
  final DashboardServices _dashboardServices = DashboardServices();
  final AuthController _authController = Get.find<AuthController>();
  
  // Observable states
  final RxBool isLoading = false.obs;
  
  // Metrics
  final RxInt guestsCount = 0.obs;
  final RxInt eventsCount = 0.obs;
  final RxInt organisationsCount = 0.obs;
  final RxInt salesPeopleCount = 0.obs;
  
  @override
  void onInit() {
    super.onInit();
    _loadDashboardData();
  }
  
  /// Load dashboard data on initialization
  Future<void> _loadDashboardData() async {
    try {
      isLoading.value = true;
      
      // Get salesPersonId if user is a salesperson
      final salesPersonId = _authController.isSalesPerson 
          ? _authController.salesPerson.value?.salesPersonId 
          : null;
      
      // Fetch all metrics (filtered by salesPersonId if applicable)
      final metrics = await _dashboardServices.getAllMetrics(
        salesPersonId: salesPersonId,
      );
      
      // Update observable values
      guestsCount.value = metrics['guests'] ?? 0;
      eventsCount.value = metrics['events'] ?? 0;
      organisationsCount.value = metrics['organisations'] ?? 0;
      salesPeopleCount.value = metrics['salesPeople'] ?? 0;
      
    } catch (e) {
      print('Error loading dashboard data: $e');
      Get.snackbar(
        'Error',
        'Failed to load dashboard data',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Refresh dashboard data
  Future<void> refreshDashboard() async {
    await _loadDashboardData();
  }
}
