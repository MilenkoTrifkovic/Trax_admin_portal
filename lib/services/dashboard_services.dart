import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trax_admin_portal/helper/firestore_helper.dart';

/// Service for fetching dashboard metrics and statistics
class DashboardServices {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  /// Get total count of guests
  /// If [salesPersonId] is provided, only counts guests for events belonging to organisations assigned to that salesperson
  Future<int> getGuestsCount({String? salesPersonId}) async {
    try {
      return await retryFirestore(() async {
        if (salesPersonId != null) {
          // Get event IDs for this salesperson's organisations
          final eventIds = await _getEventIdsForSalesPerson(salesPersonId);
          
          if (eventIds.isEmpty) return 0;
          
          // Count guests across all these events
          // Firestore 'in' queries are limited to 30 items, so we need to batch
          int totalCount = 0;
          for (int i = 0; i < eventIds.length; i += 30) {
            final batch = eventIds.skip(i).take(30).toList();
            final snapshot = await _db
                .collection('guests')
                .where('eventId', whereIn: batch)
                .where('isDisabled', isEqualTo: false)
                .count()
                .get();
            totalCount += snapshot.count ?? 0;
          }
          return totalCount;
        } else {
          // Get all guests
          final snapshot = await _db
              .collection('guests')
              .where('isDisabled', isEqualTo: false)
              .count()
              .get();
          return snapshot.count ?? 0;
        }
      });
    } catch (e) {
      print('Error getting guests count: $e');
      rethrow;
    }
  }
  
  /// Get total count of events
  /// If [salesPersonId] is provided, only counts events for organisations assigned to that salesperson
  Future<int> getEventsCount({String? salesPersonId}) async {
    try {
      return await retryFirestore(() async {
        if (salesPersonId != null) {
          // Get organisation IDs for this salesperson
          final orgIds = await _getOrganisationIdsForSalesPerson(salesPersonId);
          
          if (orgIds.isEmpty) return 0;
          
          // Count events across all these organisations
          // Firestore 'in' queries are limited to 30 items, so we need to batch
          int totalCount = 0;
          for (int i = 0; i < orgIds.length; i += 30) {
            final batch = orgIds.skip(i).take(30).toList();
            final snapshot = await _db
                .collection('events')
                .where('organisationId', whereIn: batch)
                .where('isDisabled', isEqualTo: false)
                .count()
                .get();
            totalCount += snapshot.count ?? 0;
          }
          return totalCount;
        } else {
          // Get all events
          final snapshot = await _db
              .collection('events')
              .where('isDisabled', isEqualTo: false)
              .count()
              .get();
          return snapshot.count ?? 0;
        }
      });
    } catch (e) {
      print('Error getting events count: $e');
      rethrow;
    }
  }
  
  /// Get total count of organisations
  /// If [salesPersonId] is provided, only counts organisations assigned to that salesperson
  Future<int> getOrganisationsCount({String? salesPersonId}) async {
    try {
      return await retryFirestore(() async {
        if (salesPersonId != null) {
          // Get organisations assigned to this salesperson
          final snapshot = await _db
              .collection('organisations')
              .where('assignedSalesPersonId', isEqualTo: salesPersonId)
              .where('isDisabled', isEqualTo: false)
              .count()
              .get();
          return snapshot.count ?? 0;
        } else {
          // Get all organisations
          final snapshot = await _db
              .collection('organisations')
              .where('isDisabled', isEqualTo: false)
              .count()
              .get();
          return snapshot.count ?? 0;
        }
      });
    } catch (e) {
      print('Error getting organisations count: $e');
      rethrow;
    }
  }
  
  /// Get total count of sales people
  /// Only fetched when [salesPersonId] is null (not needed for salesperson view)
  Future<int> getSalesPeopleCount() async {
    try {
      return await retryFirestore(() async {
        final snapshot = await _db
            .collection('users')
            .where('role', isEqualTo: 'sales_person')
            .where('isDisabled', isEqualTo: false)
            .count()
            .get();
        return snapshot.count ?? 0;
      });
    } catch (e) {
      print('Error getting sales people count: $e');
      rethrow;
    }
  }
  
  /// Get all dashboard metrics at once
  /// If [salesPersonId] is provided, metrics are filtered to that salesperson's assigned organisations
  Future<Map<String, int>> getAllMetrics({String? salesPersonId}) async {
    try {
      if (salesPersonId != null) {
        // For salesperson view - no need to fetch salesPeople count
        final results = await Future.wait([
          getGuestsCount(salesPersonId: salesPersonId),
          getEventsCount(salesPersonId: salesPersonId),
          getOrganisationsCount(salesPersonId: salesPersonId),
        ]);
        
        return {
          'guests': results[0],
          'events': results[1],
          'organisations': results[2],
          'salesPeople': 0, // Not needed for salesperson view
        };
      } else {
        // For super admin view - fetch all metrics
        final results = await Future.wait([
          getGuestsCount(),
          getEventsCount(),
          getOrganisationsCount(),
          getSalesPeopleCount(),
        ]);
        
        return {
          'guests': results[0],
          'events': results[1],
          'organisations': results[2],
          'salesPeople': results[3],
        };
      }
    } catch (e) {
      print('Error getting all metrics: $e');
      rethrow;
    }
  }
  
  /// Helper: Get organisation IDs assigned to a salesperson
  /// NOTE: Reads full organisation documents because Firestore doesn't support field projection
  /// This is unavoidable - we need the organisationId values to query events
  Future<List<String>> _getOrganisationIdsForSalesPerson(String salesPersonId) async {
    final snapshot = await _db
        .collection('organisations')
        .where('assignedSalesPersonId', isEqualTo: salesPersonId)
        .where('isDisabled', isEqualTo: false)
        .get();
    
    return snapshot.docs
        .map((doc) => doc.data()['organisationId'] as String?)
        .where((id) => id != null && id.isNotEmpty)
        .cast<String>()
        .toList();
  }
  
  /// Helper: Get event IDs for organisations assigned to a salesperson
  /// NOTE: Reads full event documents because Firestore doesn't support field projection
  /// This is unavoidable - we need the eventId values to count guests
  Future<List<String>> _getEventIdsForSalesPerson(String salesPersonId) async {
    // First get the organisation IDs
    final orgIds = await _getOrganisationIdsForSalesPerson(salesPersonId);
    
    if (orgIds.isEmpty) return [];
    
    // Then get all events for these organisations
    final List<String> eventIds = [];
    
    // Firestore 'in' queries are limited to 30 items, so we need to batch
    for (int i = 0; i < orgIds.length; i += 30) {
      final batch = orgIds.skip(i).take(30).toList();
      final snapshot = await _db
          .collection('events')
          .where('organisationId', whereIn: batch)
          .where('isDisabled', isEqualTo: false)
          .get();
      
      eventIds.addAll(
        snapshot.docs
            .map((doc) => doc.data()['eventId'] as String?)
            .where((id) => id != null && id.isNotEmpty)
            .cast<String>()
      );
    }
    
    return eventIds;
  }
}
