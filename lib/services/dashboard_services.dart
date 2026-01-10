import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trax_admin_portal/helper/firestore_helper.dart';

/// Service for fetching dashboard metrics and statistics
class DashboardServices {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  /// Get total count of guests
  Future<int> getGuestsCount() async {
    try {
      return await retryFirestore(() async {
        final snapshot = await _db
            .collection('guests')
            .where('isDisabled', isEqualTo: false)
            .count()
            .get();
        return snapshot.count ?? 0;
      });
    } catch (e) {
      print('Error getting guests count: $e');
      rethrow;
    }
  }
  
  /// Get total count of events
  Future<int> getEventsCount() async {
    try {
      return await retryFirestore(() async {
        final snapshot = await _db
            .collection('events')
            .where('isDisabled', isEqualTo: false)
            .count()
            .get();
        return snapshot.count ?? 0;
      });
    } catch (e) {
      print('Error getting events count: $e');
      rethrow;
    }
  }
  
  /// Get total count of organisations
  Future<int> getOrganisationsCount() async {
    try {
      return await retryFirestore(() async {
        final snapshot = await _db
            .collection('organisations')
            .where('isDisabled', isEqualTo: false)
            .count()
            .get();
        return snapshot.count ?? 0;
      });
    } catch (e) {
      print('Error getting organisations count: $e');
      rethrow;
    }
  }
  
  /// Get total count of sales people
  Future<int> getSalesPeopleCount() async {
    try {
      return await retryFirestore(() async {
        final snapshot = await _db
            .collection('sales_people')
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
  Future<Map<String, int>> getAllMetrics() async {
    try {
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
    } catch (e) {
      print('Error getting all metrics: $e');
      rethrow;
    }
  }
}
