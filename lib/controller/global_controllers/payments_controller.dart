import 'package:cloud_functions/cloud_functions.dart';
import 'package:get/get.dart';
import 'package:trax_admin_portal/models/payment.dart';

/// Global controller for managing payments/transactions across organisations.
/// 
/// This controller fetches payment data from the cloud function and stores
/// them in a map organized by organisationId for easy lookup.
class PaymentsController extends GetxController {
  /// Map of organisationId to list of payments
  final RxMap<String, List<Payment>> paymentsByOrganisation =
      <String, List<Payment>>{}.obs;

  /// Loading state indicator
  final RxBool isLoading = false.obs;

  /// Error message if loading fails
  final RxnString errorMessage = RxnString();

  /// Whether the controller has been initialized
  final RxBool isInitialized = false.obs;

  /// List of organisation IDs to fetch payments for
  final List<String> _organisationIds;

  PaymentsController(this._organisationIds);

  @override
  void onInit() {
    super.onInit();
    if (_organisationIds.isNotEmpty) {
      loadPayments();
    } else {
      isInitialized.value = true;
    }
  }

  /// Loads payments for all specified organisations from the cloud function
  Future<void> loadPayments() async {
    if (_organisationIds.isEmpty) {
      print('PaymentsController: No organisation IDs provided');
      isInitialized.value = true;
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = null;

      print(
          'PaymentsController: Loading payments for ${_organisationIds.length} organisations');

      final callable = FirebaseFunctions.instance
          .httpsCallable('getOrganisationPayments');

      final result = await callable.call(<String, dynamic>{
        'organisationIds': _organisationIds,
      });

      final responseData = result.data as Map<String, dynamic>?;

      if (responseData == null) {
        throw Exception('Cloud function returned null data');
      }

      // Parse the response - it should be a map of organisationId to list of payments
      final paymentsMap = responseData['payments'] as Map<String, dynamic>?;

      if (paymentsMap != null) {
        final Map<String, List<Payment>> parsedPayments = {};

        paymentsMap.forEach((orgId, paymentsList) {
          if (paymentsList is List) {
            parsedPayments[orgId] = paymentsList
                .map((p) => Payment.fromJson(Map<String, dynamic>.from(p)))
                .toList();
          }
        });

        paymentsByOrganisation.assignAll(parsedPayments);
        print(
            'PaymentsController: Loaded payments for ${parsedPayments.length} organisations');
      }

      isInitialized.value = true;
      isLoading.value = false;
    } on FirebaseFunctionsException catch (e) {
      print('PaymentsController: Firebase Functions Error: ${e.code} - ${e.message}');
      errorMessage.value = e.message ?? 'Failed to load payments';
      isLoading.value = false;
      isInitialized.value = true;
    } catch (e) {
      print('PaymentsController: Error loading payments: $e');
      errorMessage.value = 'Failed to load payments: $e';
      isLoading.value = false;
      isInitialized.value = true;
    }
  }

  /// Refreshes payments data
  Future<void> refresh() async {
    await loadPayments();
  }

  /// Gets all payments for a specific organisation
  List<Payment> getPaymentsForOrganisation(String organisationId) {
    return paymentsByOrganisation[organisationId] ?? [];
  }

  /// Gets the total amount paid by an organisation (in cents)
  int getTotalAmountForOrganisation(String organisationId) {
    final payments = getPaymentsForOrganisation(organisationId);
    return payments.fold(0, (sum, payment) => sum + payment.amount);
  }

  /// Gets the total events purchased by an organisation
  int getTotalEventsForOrganisation(String organisationId) {
    final payments = getPaymentsForOrganisation(organisationId);
    return payments.fold(0, (sum, payment) => sum + payment.events);
  }

  /// Gets all payments across all organisations
  List<Payment> getAllPayments() {
    return paymentsByOrganisation.values.expand((list) => list).toList();
  }

  /// Gets the total number of transactions
  int get totalTransactionCount {
    return paymentsByOrganisation.values
        .fold(0, (sum, list) => sum + list.length);
  }

  /// Adds an organisation ID and fetches its payments
  Future<void> addOrganisationAndFetch(String organisationId) async {
    if (!_organisationIds.contains(organisationId)) {
      _organisationIds.add(organisationId);
      await loadPayments();
    }
  }

  /// Updates the organisation IDs and refreshes payments
  Future<void> updateOrganisationIds(List<String> newIds) async {
    _organisationIds.clear();
    _organisationIds.addAll(newIds);
    await loadPayments();
  }
}
