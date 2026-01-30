import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:trax_admin_portal/helper/firestore_helper.dart';
import 'package:trax_admin_portal/helper/ref_code_generator.dart';
import 'package:trax_admin_portal/models/user_model.dart';
import 'package:trax_admin_portal/utils/enums/user_type.dart';
import 'package:uuid/uuid.dart';

/// Service class for managing sales people in Firestore.
/// 
/// This service handles all CRUD operations for sales people, including:
/// - Creating new sales people
/// - Fetching sales people (all, by ID, by organisation)
/// - Updating sales person information
/// - Soft deleting sales people (marking as disabled)
/// 
/// Note: Sales people are now stored in the 'users' collection with role = salesPerson
class SalesPeopleManagementServices {
  final _db = FirebaseFirestore.instance;

  /// Reference to users collection in Firestore (sales people are stored here with role = salesPerson)
  late final CollectionReference<Map<String, dynamic>> usersRef;

  SalesPeopleManagementServices() {
    usersRef = _db.collection('users');
  }

  /// Checks if a reference code already exists in Firestore
  /// Returns true if the code exists, false otherwise
  Future<bool> _refCodeExists(String refCode) async {
    try {
      final snapshot = await usersRef
          .where('refCode', isEqualTo: refCode)
          .where('role', isEqualTo: 'sales_person')
          .limit(1)
          .get();
      
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking refCode existence: $e');
      return false; // If check fails, assume it doesn't exist
    }
  }

  /// Generates a unique reference code for a sales person
  /// Checks for collisions and regenerates if necessary
  /// Max attempts: 10 (to prevent infinite loops)
  Future<String> _generateUniqueRefCode(String name) async {
    const maxAttempts = 10;
    
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final refCode = attempt == 0 
          ? RefCodeGenerator.generate(name)
          : RefCodeGenerator.regenerateDigits(RefCodeGenerator.generate(name));
      
      final exists = await _refCodeExists(refCode);
      
      if (!exists) {
        print('Generated unique refCode: $refCode (attempt ${attempt + 1})');
        return refCode;
      }
      
      print('RefCode $refCode already exists, trying again...');
    }
    
    // Fallback: if we still have collision after 10 attempts, 
    // use timestamp-based suffix
    final timestamp = DateTime.now().millisecondsSinceEpoch % 1000;
    final fallbackCode = '${RefCodeGenerator.generate(name).substring(0, 3)}$timestamp';
    print('Using fallback refCode: $fallbackCode');
    return fallbackCode;
  }

  /// Creates a new sales person in Firestore.
  /// 
  /// Generates a unique userId using UUID v4 if not provided.
  /// Generates a unique reference code (refCode) based on the person's name.
  /// Uses the userId as the Firestore document ID for consistency.
  /// Also creates a Firebase Auth account and sends password setup email.
  /// 
  /// Parameters:
  /// - [salesPerson]: The UserModel to create (must have role = salesPerson)
  /// 
  /// Returns the created UserModel with generated IDs and refCode.
  /// Throws [FirebaseException] if the create operation fails.
  /// Throws [FirebaseFunctionsException] if account creation fails.
  Future<UserModel> createSalesPerson(UserModel salesPerson) async {
    try {
      if (salesPerson.role != UserRole.salesPerson) {
        throw Exception('User must have salesPerson role');
      }

      final uuid = Uuid();
      final userId = (salesPerson.userId != null && 
                            salesPerson.userId!.isNotEmpty)
          ? salesPerson.userId!
          : uuid.v4();

      // Generate unique reference code
      final refCode = await _generateUniqueRefCode(salesPerson.name);

      final toCreate = salesPerson.copyWith(
        userId: userId,
        refCode: refCode,
        isDisabled: false, // Sales people are enabled by default
      );

      // Step 1: Call cloud function FIRST to check for duplicates, create Auth, and Firestore doc
      // The cloud function will:
      // - Check if email already exists in Firestore
      // - Create Firebase Auth account
      // - Create Firestore document
      // - Send password reset email
      try {
        final callable = FirebaseFunctions.instance.httpsCallable('createSalesPersonAccount');
        final result = await callable.call({
          'email': toCreate.email,
          'name': toCreate.name,
          'salesPersonId': userId,
          'refCode': refCode,  // Pass refCode to cloud function
          'address': toCreate.address,
          'city': toCreate.city,
          'state': toCreate.state,
          'country': toCreate.country,
        });

        print('Cloud function response: ${result.data}');
        print('Sales person created successfully via cloud function');
        
      } on FirebaseFunctionsException catch (e) {
        print('Error from cloud function: ${e.message}');
        // If cloud function fails, throw the error
        throw Exception('Failed to create sales person: ${e.message}');
      }

      print('Sales person created successfully: $userId');
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
  /// Returns a list of all UserModel objects with role = salesPerson.
  /// Throws [FirebaseException] if the fetch operation fails.
  Future<List<UserModel>> getAllSalesPeople({
    bool includeDisabled = false,
  }) async {
    try {
      Query<Map<String, dynamic>> query = usersRef
          .where('role', isEqualTo: 'sales_person');

      if (!includeDisabled) {
        query = query.where('isDisabled', isEqualTo: false);
      }

      final snapshot = await retryFirestore(
        () => query.get(),
        operationName: 'getAllSalesPeople',
      );

      final salesPeople = snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc.data(), doc.id))
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

  /// Fetches a single sales person by their salesPersonId (userId).
  /// 
  /// Parameters:
  /// - [salesPersonId]: The userId to search for
  /// 
  /// Returns the UserModel if found.
  /// Throws [FirebaseException] if the fetch operation fails.
  /// Throws [Exception] if the sales person is not found.
  Future<UserModel> getSalesPersonById(String salesPersonId) async {
    try {
      // Try direct doc lookup using salesPersonId as the doc id
      final docRef = usersRef.doc(salesPersonId);
      final snapshot = await retryFirestore(
        () => docRef.get(),
        operationName: 'getSalesPersonById',
      );

      if (!snapshot.exists) {
        throw Exception('Sales person not found with ID: $salesPersonId');
      }

      final data = snapshot.data()!;
      if (data['role'] != 'sales_person') {
        throw Exception('User is not a sales person: $salesPersonId');
      }

      final salesPerson = UserModel.fromFirestore(data, snapshot.id);

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
  /// Uses the userId from the model to locate the document.
  /// Preserves createdAt timestamp and updates modifiedAt automatically.
  /// 
  /// Parameters:
  /// - [salesPerson]: The updated UserModel (must have role = salesPerson)
  /// 
  /// Returns the updated UserModel.
  /// Throws [FirebaseException] if the update operation fails.
  /// Throws [Exception] if the sales person is not found.
  Future<UserModel> updateSalesPerson(UserModel salesPerson) async {
    try {
      if (salesPerson.role != UserRole.salesPerson) {
        throw Exception('User must have salesPerson role');
      }

      if (salesPerson.userId == null || salesPerson.userId!.isEmpty) {
        throw Exception('User ID is required for update');
      }

      final userId = salesPerson.userId!;

      final docRef = usersRef.doc(userId);
      final docSnap = await docRef.get();

      if (!docSnap.exists) {
        throw Exception('Sales person not found with ID: $userId');
      }

      // Verify it's a sales person
      final data = docSnap.data()!;
      if (data['role'] != 'sales_person') {
        throw Exception('User is not a sales person: $userId');
      }

      // Update the document
      await docRef.update(salesPerson.toFirestoreUpdate());

      print('Sales person updated successfully: $userId');
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
  /// - [salesPersonId]: The userId of the person to delete
  /// 
  /// Throws [FirebaseException] if the delete operation fails.
  /// Throws [Exception] if the sales person is not found.
  Future<void> deleteSalesPerson(String salesPersonId) async {
    try {
      final docRef = usersRef.doc(salesPersonId);
      final docSnap = await docRef.get();

      if (!docSnap.exists) {
        throw Exception('Sales person not found with ID: $salesPersonId');
      }

      // Verify it's a sales person
      final data = docSnap.data()!;
      if (data['role'] != 'sales_person') {
        throw Exception('User is not a sales person: $salesPersonId');
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
  /// - [salesPersonId]: The userId of the person to permanently delete
  /// 
  /// Throws [FirebaseException] if the delete operation fails.
  Future<void> permanentlyDeleteSalesPerson(String salesPersonId) async {
    try {
      await usersRef.doc(salesPersonId).delete();
      print('Sales person permanently deleted: $salesPersonId');
    } on FirebaseException catch (e) {
      print('Firestore error permanently deleting sales person: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown error permanently deleting sales person: $e');
      rethrow;
    }
  }

  /// Gets a sales person by their email address.
  /// 
  /// Parameters:
  /// - [email]: The email address to search for
  /// 
  /// Returns the UserModel if found, null otherwise.
  /// Throws [FirebaseException] if the query fails.
  Future<UserModel?> getSalesPersonByEmail(String email) async {
    try {
      final snapshot = await retryFirestore(
        () => usersRef
            .where('email', isEqualTo: email.toLowerCase())
            .where('role', isEqualTo: 'sales_person')
            .where('isDisabled', isEqualTo: false)
            .limit(1)
            .get(),
        operationName: 'getSalesPersonByEmail',
      );

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final salesPerson = UserModel.fromFirestore(
        snapshot.docs.first.data(),
        snapshot.docs.first.id,
      );

      print('Found sales person: ${salesPerson.name} (${salesPerson.email})');
      return salesPerson;
    } on FirebaseException catch (e) {
      print('Firestore error fetching sales person by email: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown error fetching sales person by email: $e');
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
  /// Returns a list of matching UserModel objects.
  Future<List<UserModel>> searchSalesPeople(
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
  /// - [salesPersonId]: The userId of the person to restore
  /// 
  /// Throws [FirebaseException] if the restore operation fails.
  /// Throws [Exception] if the sales person is not found.
  Future<void> restoreSalesPerson(String salesPersonId) async {
    try {
      final docRef = usersRef.doc(salesPersonId);
      final docSnap = await docRef.get();

      if (!docSnap.exists) {
        throw Exception('Sales person not found with ID: $salesPersonId');
      }

      // Verify it's a sales person
      final data = docSnap.data()!;
      if (data['role'] != 'sales_person') {
        throw Exception('User is not a sales person: $salesPersonId');
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

  /// Resends the password setup email to a sales person.
  /// Resends password setup email to an existing sales person.
  /// 
  /// This can be used if:
  /// - Initial account creation failed
  /// - User lost the original email
  /// - User needs to reset their password
  /// 
  /// Parameters:
  /// - [salesPerson]: The UserModel to send email to (must have role = salesPerson)
  /// 
  /// Throws [FirebaseFunctionsException] if the operation fails.
  Future<void> resendPasswordSetupEmail(UserModel salesPerson) async {
    try {
      if (salesPerson.email.isEmpty) {
        throw Exception('Sales person email is required');
      }

      if (salesPerson.userId == null || salesPerson.userId!.isEmpty) {
        throw Exception('Sales person ID is required');
      }

      if (salesPerson.role != UserRole.salesPerson) {
        throw Exception('User must have salesPerson role');
      }

      // Call the same cloud function - it will handle existing users
      final callable = FirebaseFunctions.instance.httpsCallable('createSalesPersonAccount');
      final result = await callable.call({
        'email': salesPerson.email,
        'name': salesPerson.name,
        'salesPersonId': salesPerson.userId!,
        'refCode': salesPerson.refCode ?? '', // Pass existing refCode
        'address': salesPerson.address,
        'city': salesPerson.city,
        'state': salesPerson.state,
        'country': salesPerson.country,
        'isResend': true, // Mark this as a resend operation
      });

      print('Password setup email sent: ${result.data}');
    } on FirebaseFunctionsException catch (e) {
      print('Error sending password setup email: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown error sending password setup email: $e');
      rethrow;
    }
  }
}
