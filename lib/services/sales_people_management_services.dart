import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trax_admin_portal/helper/firestore_helper.dart';
import 'package:trax_admin_portal/models/sales_person_model.dart';
import 'package:uuid/uuid.dart';

/// Service class for managing sales people in Firestore.
/// 
/// This service handles all CRUD operations for sales people, including:
/// - Creating new sales people
/// - Fetching sales people (all, by ID, by organisation)
/// - Updating sales person information
/// - Soft deleting sales people (marking as disabled)
class SalesPeopleManagementServices {
  final _db = FirebaseFirestore.instance;

  /// Reference to sales_people collection in Firestore
  late final CollectionReference<Map<String, dynamic>> salesPeopleRef;

  SalesPeopleManagementServices() {
    salesPeopleRef = _db.collection('sales_people');
  }

  /// Creates a new sales person in Firestore.
  /// 
  /// Generates a unique salesPersonId using UUID v4 if not provided.
  /// Uses the salesPersonId as the Firestore document ID for consistency.
  /// 
  /// Parameters:
  /// - [salesPerson]: The SalesPersonModel to create
  /// 
  /// Returns the created SalesPersonModel with generated IDs.
  /// Throws [FirebaseException] if the create operation fails.
  Future<SalesPersonModel> createSalesPerson(SalesPersonModel salesPerson) async {
    try {
      final uuid = Uuid();
      final salesPersonId = (salesPerson.salesPersonId != null && 
                            salesPerson.salesPersonId!.isNotEmpty)
          ? salesPerson.salesPersonId!
          : uuid.v4();

      final toCreate = salesPerson.copyWith(
        docId: salesPersonId,
        salesPersonId: salesPersonId,
      );

      // Use salesPersonId as Firestore document ID
      final docRef = salesPeopleRef.doc(salesPersonId);
      await docRef.set(toCreate.toFirestoreCreate());

      print('Sales person created successfully: $salesPersonId');
      return toCreate;
    } on FirebaseException catch (e) {
      print('Firestore error creating sales person: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown error creating sales person: $e');
      rethrow;
    }
  }

  /// Fetches all sales people from Firestore.
  /// 
  /// By default, excludes disabled sales people unless [includeDisabled] is true.
  /// 
  /// Parameters:
  /// - [includeDisabled]: Whether to include disabled sales people (default: false)
  /// 
  /// Returns a list of all SalesPersonModel objects.
  /// Throws [FirebaseException] if the fetch operation fails.
  Future<List<SalesPersonModel>> getAllSalesPeople({
    bool includeDisabled = false,
  }) async {
    try {
      Query<Map<String, dynamic>> query = salesPeopleRef;

      if (!includeDisabled) {
        query = query.where('isDisabled', isEqualTo: false);
      }

      final snapshot = await retryFirestore(
        () => query.get(),
        operationName: 'getAllSalesPeople',
      );

      final salesPeople = snapshot.docs
          .map((doc) => SalesPersonModel.fromFirestore(doc.data(), doc.id))
          .toList();

      print('Fetched ${salesPeople.length} sales people');
      return salesPeople;
    } on FirebaseException catch (e) {
      print('Firestore error fetching all sales people: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown error fetching all sales people: $e');
      rethrow;
    }
  }

  /// Fetches a single sales person by their salesPersonId.
  /// 
  /// Parameters:
  /// - [salesPersonId]: The salesPersonId to search for
  /// 
  /// Returns the SalesPersonModel if found.
  /// Throws [FirebaseException] if the fetch operation fails.
  /// Throws [Exception] if the sales person is not found.
  Future<SalesPersonModel> getSalesPersonById(String salesPersonId) async {
    try {
      // Try direct doc lookup using salesPersonId as the doc id
      final docRef = salesPeopleRef.doc(salesPersonId);
      final snapshot = await retryFirestore(
        () => docRef.get(),
        operationName: 'getSalesPersonById',
      );

      if (!snapshot.exists) {
        throw Exception('Sales person not found with ID: $salesPersonId');
      }

      final salesPerson = SalesPersonModel.fromFirestore(
        snapshot.data()!,
        snapshot.id,
      );

      print('Fetched sales person: ${salesPerson.name}');
      return salesPerson;
    } on FirebaseException catch (e) {
      print('Firestore error fetching sales person: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown error fetching sales person: $e');
      rethrow;
    }
  }

  /// Updates an existing sales person in Firestore.
  /// 
  /// Uses the salesPersonId from the model to locate the document.
  /// Preserves createdAt timestamp and updates modifiedAt automatically.
  /// 
  /// Parameters:
  /// - [salesPerson]: The updated SalesPersonModel
  /// 
  /// Returns the updated SalesPersonModel.
  /// Throws [FirebaseException] if the update operation fails.
  /// Throws [Exception] if the sales person is not found.
  Future<SalesPersonModel> updateSalesPerson(SalesPersonModel salesPerson) async {
    try {
      if (salesPerson.docId.isEmpty && 
          (salesPerson.salesPersonId == null || salesPerson.salesPersonId!.isEmpty)) {
        throw Exception('Sales person ID is required for update');
      }

      final salesPersonId = salesPerson.docId.isNotEmpty 
          ? salesPerson.docId 
          : salesPerson.salesPersonId!;

      final docRef = salesPeopleRef.doc(salesPersonId);
      final docSnap = await docRef.get();

      if (!docSnap.exists) {
        throw Exception('Sales person not found with ID: $salesPersonId');
      }

      // Update the document
      await docRef.update(salesPerson.toFirestoreUpdate());

      print('Sales person updated successfully: $salesPersonId');
      return salesPerson;
    } on FirebaseException catch (e) {
      print('Firestore error updating sales person: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown error updating sales person: $e');
      rethrow;
    }
  }

  /// Soft deletes a sales person by marking them as disabled.
  /// 
  /// This method does not permanently delete the document, but sets
  /// isDisabled to true so they won't appear in normal queries.
  /// 
  /// Parameters:
  /// - [salesPersonId]: The salesPersonId of the person to delete
  /// 
  /// Throws [FirebaseException] if the delete operation fails.
  /// Throws [Exception] if the sales person is not found.
  Future<void> deleteSalesPerson(String salesPersonId) async {
    try {
      final docRef = salesPeopleRef.doc(salesPersonId);
      final docSnap = await docRef.get();

      if (!docSnap.exists) {
        throw Exception('Sales person not found with ID: $salesPersonId');
      }

      await docRef.update({
        'isDisabled': true,
        'modifiedAt': FieldValue.serverTimestamp(),
      });

      print('Sales person soft deleted successfully: $salesPersonId');
    } on FirebaseException catch (e) {
      print('Firestore error deleting sales person: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown error deleting sales person: $e');
      rethrow;
    }
  }

  /// Permanently deletes a sales person from Firestore.
  /// 
  /// WARNING: This operation cannot be undone. Use [deleteSalesPerson] 
  /// for soft delete instead in most cases.
  /// 
  /// Parameters:
  /// - [salesPersonId]: The salesPersonId of the person to permanently delete
  /// 
  /// Throws [FirebaseException] if the delete operation fails.
  Future<void> permanentlyDeleteSalesPerson(String salesPersonId) async {
    try {
      await salesPeopleRef.doc(salesPersonId).delete();
      print('Sales person permanently deleted: $salesPersonId');
    } on FirebaseException catch (e) {
      print('Firestore error permanently deleting sales person: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown error permanently deleting sales person: $e');
      rethrow;
    }
  }

  /// Searches for sales people by name or email.
  /// 
  /// This performs a client-side filter since Firestore doesn't support
  /// full-text search natively. For better performance with large datasets,
  /// consider using Algolia or similar service.
  /// 
  /// Parameters:
  /// - [query]: The search query string
  /// - [includeDisabled]: Whether to include disabled sales people (default: false)
  /// 
  /// Returns a list of matching SalesPersonModel objects.
  Future<List<SalesPersonModel>> searchSalesPeople(
    String query, {
    bool includeDisabled = false,
  }) async {
    try {
      final allSalesPeople = await getAllSalesPeople(
        includeDisabled: includeDisabled,
      );

      if (query.isEmpty) {
        return allSalesPeople;
      }

      final lowerQuery = query.toLowerCase();
      return allSalesPeople.where((person) {
        return person.name.toLowerCase().contains(lowerQuery) ||
               person.email.toLowerCase().contains(lowerQuery);
      }).toList();
    } catch (e) {
      print('Error searching sales people: $e');
      rethrow;
    }
  }

  /// Restores a soft-deleted sales person by setting isDisabled to false.
  /// 
  /// Parameters:
  /// - [salesPersonId]: The salesPersonId of the person to restore
  /// 
  /// Throws [FirebaseException] if the restore operation fails.
  /// Throws [Exception] if the sales person is not found.
  Future<void> restoreSalesPerson(String salesPersonId) async {
    try {
      final docRef = salesPeopleRef.doc(salesPersonId);
      final docSnap = await docRef.get();

      if (!docSnap.exists) {
        throw Exception('Sales person not found with ID: $salesPersonId');
      }

      await docRef.update({
        'isDisabled': false,
        'modifiedAt': FieldValue.serverTimestamp(),
      });

      print('Sales person restored successfully: $salesPersonId');
    } on FirebaseException catch (e) {
      print('Firestore error restoring sales person: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown error restoring sales person: $e');
      rethrow;
    }
  }
}
