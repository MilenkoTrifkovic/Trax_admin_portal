import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:trax_admin_portal/controller/global_controllers/payments_controller.dart';
import 'package:trax_admin_portal/controller/global_controllers/snackbar_message_controller.dart';
import 'package:trax_admin_portal/services/cloud_functions_services.dart';

/// Controller for assigning free credits dialog
class AssignFreeCreditsController extends GetxController {
  final String organisationId;
  final String companyName;

  AssignFreeCreditsController({
    required this.organisationId,
    required this.companyName,
  });

  final formKey = GlobalKey<FormState>();
  final eventsController = TextEditingController();
  final noteController = TextEditingController();

  final isLoading = false.obs;
  final errorMessage = Rxn<String>();

  @override
  void onClose() {
    eventsController.dispose();
    noteController.dispose();
    super.onClose();
  }

  /// Validates the events input
  String? validateEvents(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter number of events';
    }
    final number = int.tryParse(value);
    if (number == null || number <= 0) {
      return 'Please enter a valid number greater than 0';
    }
    if (number > 1000) {
      return 'Maximum 1000 events allowed';
    }
    return null;
  }

  /// Validates the form
  bool validateForm() {
    return formKey.currentState?.validate() ?? false;
  }

  /// Gets the number of events from input
  int? getEventsCount() {
    final events = int.tryParse(eventsController.text);
    if (events == null || events <= 0) return null;
    return events;
  }

  /// Assigns free credits via cloud function
  Future<bool> assignCredits() async {
    final events = getEventsCount();
    if (events == null) return false;

    try {
      isLoading.value = true;
      errorMessage.value = null;

      final cloudFunctionsService = Get.find<CloudFunctionsService>();

      await cloudFunctionsService.assignFreeCredits(
        organisationId: organisationId,
        events: events,
        note: noteController.text.trim().isEmpty
            ? null
            : noteController.text.trim(),
      );

      // Refresh payments
      final paymentsController = Get.find<PaymentsController>();
      await paymentsController.loadPayments();

      // Show success message
      final snackbarController = Get.find<SnackbarMessageController>();
      snackbarController.showSuccessMessage(
        'Successfully assigned $events free event${events > 1 ? 's' : ''} to $companyName',
      );

      return true;
    } catch (e) {
      errorMessage.value = 'Failed to assign credits: $e';
      
      // Show error message
      final snackbarController = Get.find<SnackbarMessageController>();
      snackbarController.showErrorMessage(errorMessage.value!);
      
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
