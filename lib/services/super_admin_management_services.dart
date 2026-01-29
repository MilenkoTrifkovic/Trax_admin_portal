import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:trax_admin_portal/models/super_admin_model.dart';

/// Service class for managing super admins in Firestore.
///
/// This service handles all CRUD operations for super admins, including:
/// - Creating new super admins (via cloud function)
/// - Fetching super admins (all, by ID)
/// - Updating super admin information (via cloud function)
/// - Soft deleting super admins (marking as disabled via cloud function)
/// - Deleting super admins (soft delete via cloud function)
class SuperAdminManagementServices {
  final _db = FirebaseFirestore.instance;

  /// Reference to users collection in Firestore (where super admins are stored)
  late final CollectionReference<Map<String, dynamic>> usersRef;

  SuperAdminManagementServices() {
    usersRef = _db.collection('users');
  }

  /// Creates a new super admin via cloud function.
  ///
  /// This calls the manageSuperAdmin cloud function with action='create'
  /// The function will:
  /// 1. Create Firebase Auth account
  /// 2. Set custom claims (role: super_admin)
  /// 3. Create Firestore document in users collection
  /// 4. Send password setup email
  ///
  /// Parameters:
  /// - [superAdmin]: The SuperAdminModel to create
  ///
  /// Returns the created SuperAdminModel with the UID from Firebase Auth.
  /// Throws [FirebaseFunctionsException] if the operation fails.
  Future<SuperAdminModel> createSuperAdmin(SuperAdminModel superAdmin) async {
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('manageSuperAdmin');
      final result = await callable.call({
        'action': 'create',
        'email': superAdmin.email,
        'name': superAdmin.name,
        if (superAdmin.phoneNumber != null)
          'phoneNumber': superAdmin.phoneNumber,
      });

      print('Super admin created: ${result.data}');

      final uid = result.data['uid'] as String;

      // Return the created super admin with the UID
      return superAdmin.copyWith(
        docId: uid,
        superAdminId: uid,
      );
    } on FirebaseFunctionsException catch (e) {
      print('Error creating super admin: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown error creating super admin: $e');
      rethrow;
    }
  }

  /// Fetches all super admins from Firestore.
  ///
  /// By default, excludes disabled and deleted super admins unless flags are set.
  /// Reads directly from Firestore users collection where role='super_admin'.
  ///
  /// Parameters:
  /// - [includeDisabled]: Whether to include disabled super admins (default: false)
  /// - [includeDeleted]: Whether to include deleted super admins (default: false)
  ///
  /// Returns a list of all SuperAdminModel objects.
  /// Throws [FirebaseException] if the fetch operation fails.
  Future<List<SuperAdminModel>> getAllSuperAdmins({
    bool includeDisabled = false,
    bool includeDeleted = false,
  }) async {
    try {
      // Query only by role to avoid composite index requirement
      // Then filter in memory for isDisabled and isDeleted
      Query<Map<String, dynamic>> query =
          usersRef.where('role', isEqualTo: 'super_admin');

      final snapshot = await query.get();

      // Filter in memory instead of in query
      final superAdmins = snapshot.docs
          .map((doc) => SuperAdminModel.fromFirestore(doc.data(), doc.id))
          .where((admin) {
        if (!includeDisabled && admin.isDisabled) return false;
        if (!includeDeleted && admin.isDeleted) return false;
        return true;
      }).toList();

      print('Fetched ${superAdmins.length} super admins from Firestore');
      return superAdmins;
    } on FirebaseException catch (e) {
      print('Firestore error fetching super admins: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown error fetching super admins: $e');
      rethrow;
    }
  }

  /// Fetches a single super admin by ID.
  ///
  /// Reads directly from Firestore users collection.
  ///
  /// Parameters:
  /// - [superAdminId]: The document ID of the super admin to fetch
  ///
  /// Returns the SuperAdminModel if found, null otherwise.
  /// Throws [FirebaseException] if the fetch operation fails.
  Future<SuperAdminModel?> getSuperAdminById(String superAdminId) async {
    try {
      final doc = await usersRef.doc(superAdminId).get();

      if (!doc.exists) {
        print('Super admin not found: $superAdminId');
        return null;
      }

      final data = doc.data();
      if (data == null || data['role'] != 'super_admin') {
        print('Document exists but is not a super admin: $superAdminId');
        return null;
      }

      return SuperAdminModel.fromFirestore(data, doc.id);
    } on FirebaseException catch (e) {
      print('Firestore error fetching super admin: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown error fetching super admin: $e');
      rethrow;
    }
  }

  /// Updates an existing super admin via cloud function.
  ///
  /// This calls the manageSuperAdmin cloud function with action='edit'
  /// The function will update the Firestore document and Firebase Auth display name.
  ///
  /// Parameters:
  /// - [superAdmin]: The SuperAdminModel with updated information
  ///
  /// Returns the updated SuperAdminModel.
  /// Throws [FirebaseFunctionsException] if the operation fails.
  Future<SuperAdminModel> updateSuperAdmin(SuperAdminModel superAdmin) async {
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('manageSuperAdmin');
      final result = await callable.call({
        'action': 'edit',
        'email': superAdmin.email,
        'name': superAdmin.name,
        if (superAdmin.phoneNumber != null)
          'phoneNumber': superAdmin.phoneNumber,
      });

      print('Super admin updated: ${result.data}');
      return superAdmin;
    } on FirebaseFunctionsException catch (e) {
      print('Error updating super admin: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown error updating super admin: $e');
      rethrow;
    }
  }

  /// Disables or enables a super admin via cloud function.
  ///
  /// This calls the manageSuperAdmin cloud function with action='disable'
  /// This is a soft delete - the document remains but isDisabled is set to true.
  ///
  /// Parameters:
  /// - [email]: The email of the super admin to disable/enable
  /// - [isDisabled]: true to disable, false to enable
  ///
  /// Throws [FirebaseFunctionsException] if the operation fails.
  Future<void> setDisabledStatus(String email, bool isDisabled) async {
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('manageSuperAdmin');
      final result = await callable.call({
        'action': 'disable',
        'email': email,
        'isDisabled': isDisabled,
      });

      print(
          'Super admin ${isDisabled ? "disabled" : "enabled"}: ${result.data}');
    } on FirebaseFunctionsException catch (e) {
      print(
          'Error ${isDisabled ? "disabling" : "enabling"} super admin: ${e.message}');
      rethrow;
    } catch (e) {
      print(
          'Unknown error ${isDisabled ? "disabling" : "enabling"} super admin: $e');
      rethrow;
    }
  }

  /// Deletes or restores a super admin via cloud function (soft delete).
  ///
  /// This calls the manageSuperAdmin cloud function with action='delete'
  /// When deleted, the user is hidden from the app but remains in Firestore.
  ///
  /// Parameters:
  /// - [email]: The email of the super admin to delete/restore
  /// - [isDeleted]: true to delete, false to restore
  ///
  /// Throws [FirebaseFunctionsException] if the operation fails.
  Future<void> setDeletedStatus(String email, bool isDeleted) async {
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('manageSuperAdmin');
      final result = await callable.call({
        'action': 'delete',
        'email': email,
        'isDeleted': isDeleted,
      });

      print(
          'Super admin ${isDeleted ? "deleted" : "restored"}: ${result.data}');
    } on FirebaseFunctionsException catch (e) {
      print(
          'Error ${isDeleted ? "deleting" : "restoring"} super admin: ${e.message}');
      rethrow;
    } catch (e) {
      print(
          'Unknown error ${isDeleted ? "deleting" : "restoring"} super admin: $e');
      rethrow;
    }
  }

  /// Streams all super admins from Firestore in real-time.
  ///
  /// This provides a real-time stream of super admin updates.
  ///
  /// Parameters:
  /// - [includeDisabled]: Whether to include disabled super admins (default: false)
  /// - [includeDeleted]: Whether to include deleted super admins (default: false)
  ///
  /// Returns a Stream of List<SuperAdminModel>.
  Stream<List<SuperAdminModel>> streamSuperAdmins({
    bool includeDisabled = false,
    bool includeDeleted = false,
  }) {
    try {
      // Query only by role to avoid composite index requirement
      // Then filter in memory for isDisabled and isDeleted
      Query<Map<String, dynamic>> query =
          usersRef.where('role', isEqualTo: 'super_admin');

      return query.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => SuperAdminModel.fromFirestore(doc.data(), doc.id))
            .where((admin) {
          if (!includeDisabled && admin.isDisabled) return false;
          if (!includeDeleted && admin.isDeleted) return false;
          return true;
        }).toList();
      });
    } catch (e) {
      print('Error streaming super admins: $e');
      rethrow;
    }
  }

  /// Resends password setup email to a super admin.
  ///
  /// This calls the manageSuperAdmin cloud function with action='create'
  /// for an existing user, which will send a password reset email.
  ///
  /// Parameters:
  /// - [superAdmin]: The SuperAdminModel to resend email to
  ///
  /// Throws [FirebaseFunctionsException] if the operation fails.
  Future<void> resendPasswordSetupEmail(SuperAdminModel superAdmin) async {
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('manageSuperAdmin');
      await callable.call({
        'action': 'create',
        'email': superAdmin.email,
        'name': superAdmin.name,
      });

      print('Password setup email resent to: ${superAdmin.email}');
    } on FirebaseFunctionsException catch (e) {
      print('Error resending password setup email: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown error resending password setup email: $e');
      rethrow;
    }
  }

  /// Reset password for a super admin
  ///
  /// Sends a password reset email to the super admin's email address.
  /// This allows them to reset their password if they forgot it or need to change it.
  ///
  /// Parameters:
  /// - [email]: The email address of the super admin
  ///
  /// Throws [FirebaseFunctionsException] if the operation fails.
  Future<void> resetPassword(String email) async {
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('manageSuperAdmin');
      await callable.call({
        'action': 'reset_password',
        'email': email,
      });

      print('Password reset email sent to: $email');
    } on FirebaseFunctionsException catch (e) {
      print('Error sending password reset email: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown error sending password reset email: $e');
      rethrow;
    }
  }
}
