import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trax_admin_portal/helper/firestore_helper.dart';
import 'package:trax_admin_portal/models/company_summary.dart';

/// Service class for managing company-related operations
class CompanyServices {
  final _db = FirebaseFirestore.instance;

  /// Fetches all companies with their event counts and assigned salespeople
  ///
  /// If [salesPersonId] is provided, only returns companies assigned to that salesperson.
  /// If [salesPersonId] is null, returns all companies.
  ///
  /// Returns a list of CompanySummary objects containing:
  /// - Company information (name, id)
  /// - Total number of events for that company
  /// - Assigned salesperson information (if any)
  Future<List<CompanySummary>> getAllCompaniesWithEventCounts({
    String? salesPersonId,
  }) async {
    try {
      print(
          '📊 Fetching companies with event counts${salesPersonId != null ? " for salesperson: $salesPersonId" : ""}...');

      // Fetch organisations - filter by salesperson if provided
      Query<Map<String, dynamic>> orgsQuery =
          _db.collection('organisations').where('isDisabled', isEqualTo: false);

      if (salesPersonId != null) {
        orgsQuery =
            orgsQuery.where('assignedSalesPersonId', isEqualTo: salesPersonId);
      }

      final orgsSnapshot = await retryFirestore(
        () => orgsQuery.get(),
        operationName: 'getAllOrganisations',
      );

      // Fetch all events to count by organisation
      final eventsSnapshot = await retryFirestore(
        () => _db
            .collection('events')
            .where('isDisabled', isEqualTo: false)
            .get(),
        operationName: 'getAllEvents',
      );

      // Count events per organisation
      final Map<String, int> eventCounts = {};
      for (var eventDoc in eventsSnapshot.docs) {
        final orgId = eventDoc.data()['organisationId'] as String?;
        if (orgId != null) {
          eventCounts[orgId] = (eventCounts[orgId] ?? 0) + 1;
        }
      }

      // Fetch all sales people from users collection
      final salesPeopleSnapshot = await retryFirestore(
        () => _db
            .collection('users')
            .where('role', isEqualTo: 'sales_person')
            .where('isDisabled', isEqualTo: false)
            .get(),
        operationName: 'getAllSalesPeople',
      );

      // Map sales people by their ID for quick lookup
      final Map<String, Map<String, dynamic>> salesPeopleMap = {};
      for (var salesDoc in salesPeopleSnapshot.docs) {
        final data = salesDoc.data();
        salesPeopleMap[salesDoc.id] = {
          'name': data['name'] as String? ?? '',
          'email': data['email'] as String? ?? '',
        };
      }

      // Build company summaries
      final List<CompanySummary> companies = [];
      for (var orgDoc in orgsSnapshot.docs) {
        final data = orgDoc.data();
        final orgId = orgDoc.id;
        final salesPersonId = data['assignedSalesPersonId'] as String?;

        companies.add(CompanySummary(
          organisationId: orgId,
          companyName: data['name'] as String? ?? 'Unknown',
          eventCount: eventCounts[orgId] ?? 0,
          salesPersonId: salesPersonId,
          salesPersonName: salesPersonId != null
              ? (salesPeopleMap[salesPersonId]?['name'] as String?)
              : null,
          salesPersonEmail: salesPersonId != null
              ? (salesPeopleMap[salesPersonId]?['email'] as String?)
              : null,
          createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
        ));
      }

      print('✅ Fetched ${companies.length} companies');
      return companies;
    } catch (e) {
      print('❌ Error fetching companies: $e');
      rethrow;
    }
  }

  /// Gets a single company summary by organisation ID
  Future<CompanySummary?> getCompanySummary(String organisationId) async {
    try {
      print('📊 Fetching company summary for: $organisationId');

      // Fetch organisation
      final orgDoc = await retryFirestore(
        () => _db.collection('organisations').doc(organisationId).get(),
        operationName: 'getOrganisation',
      );

      if (!orgDoc.exists) {
        print('❌ Organisation not found: $organisationId');
        return null;
      }

      final orgData = orgDoc.data()!;

      // Count events for this organisation
      final eventsSnapshot = await retryFirestore(
        () => _db
            .collection('events')
            .where('organisationId', isEqualTo: organisationId)
            .where('isDisabled', isEqualTo: false)
            .get(),
        operationName: 'getOrganisationEvents',
      );

      final eventCount = eventsSnapshot.docs.length;

      // Fetch salesperson if assigned
      final salesPersonId = orgData['assignedSalesPersonId'] as String?;
      String? salesPersonName;
      String? salesPersonEmail;

      if (salesPersonId != null) {
        final salesDoc = await retryFirestore(
          () => _db.collection('users').doc(salesPersonId).get(),
          operationName: 'getSalesPerson',
        );

        if (salesDoc.exists) {
          final salesData = salesDoc.data()!;
          salesPersonName = salesData['name'] as String?;
          salesPersonEmail = salesData['email'] as String?;
        }
      }

      final summary = CompanySummary(
        organisationId: organisationId,
        companyName: orgData['name'] as String? ?? 'Unknown',
        eventCount: eventCount,
        salesPersonId: salesPersonId,
        salesPersonName: salesPersonName,
        salesPersonEmail: salesPersonEmail,
        createdAt: (orgData['createdAt'] as Timestamp?)?.toDate(),
      );

      print('✅ Company summary fetched: ${summary.companyName}');
      return summary;
    } catch (e) {
      print('❌ Error fetching company summary: $e');
      rethrow;
    }
  }

  /// Assigns a salesperson to a company
  Future<void> assignSalesPersonToCompany(
    String organisationId,
    String salesPersonId,
  ) async {
    try {
      print(
          '👤 Assigning salesperson $salesPersonId to company $organisationId');

      await _db.collection('organisations').doc(organisationId).update({
        'assignedSalesPersonId': salesPersonId,
        'modifiedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Salesperson assigned successfully');
    } catch (e) {
      print('❌ Error assigning salesperson: $e');
      rethrow;
    }
  }

  /// Removes a salesperson assignment from a company
  Future<void> removeSalesPersonFromCompany(String organisationId) async {
    try {
      print('👤 Removing salesperson assignment from company $organisationId');

      await _db.collection('organisations').doc(organisationId).update({
        'assignedSalesPersonId': FieldValue.delete(),
        'modifiedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Salesperson assignment removed');
    } catch (e) {
      print('❌ Error removing salesperson assignment: $e');
      rethrow;
    }
  }
}
