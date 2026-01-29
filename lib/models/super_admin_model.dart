import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for Super Admin users
/// Super admins have the highest level of access and can manage other super admins
class SuperAdminModel {
  /// Firestore document id (matches Firebase Auth UID)
  final String docId;

  /// Business id field (optional, can be set to doc id)
  final String? superAdminId;

  final String name;
  final String email;

  /// Contact information (optional)
  final String? phoneNumber;

  final DateTime? createdAt;
  final DateTime? modifiedAt;

  /// Disable flag - when true, the super admin cannot log in but remains visible in the app
  final bool isDisabled;

  /// Soft delete flag - when true, the super admin is hidden from the app
  final bool isDeleted;

  SuperAdminModel({
    this.docId = '',
    this.superAdminId,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.createdAt,
    this.modifiedAt,
    this.isDisabled = false,
    this.isDeleted = false,
  });

  /// Firestore: create (new document)
  Map<String, dynamic> toFirestoreCreate() {
    return {
      if (docId.isNotEmpty) 'docId': docId,
      if (superAdminId != null && superAdminId!.trim().isNotEmpty)
        'superAdminId': superAdminId,
      'name': name,
      'email': email,
      if (phoneNumber != null && phoneNumber!.trim().isNotEmpty) 
        'phoneNumber': phoneNumber,
      'isDisabled': isDisabled,
      'isDeleted': isDeleted,
      'role': 'super_admin', // Always set role for super admin
      'createdAt': FieldValue.serverTimestamp(),
      'modifiedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Firestore: update (existing document)
  Map<String, dynamic> toFirestoreUpdate() {
    return {
      if (docId.isNotEmpty) 'docId': docId,
      if (superAdminId != null && superAdminId!.trim().isNotEmpty)
        'superAdminId': superAdminId,
      'name': name,
      'email': email,
      if (phoneNumber != null && phoneNumber!.trim().isNotEmpty) 
        'phoneNumber': phoneNumber,
      'isDisabled': isDisabled,
      'isDeleted': isDeleted,
      'role': 'super_admin',
      'modifiedAt': FieldValue.serverTimestamp(),
    };
  }

  factory SuperAdminModel.fromFirestore(
      Map<String, dynamic> data, [String? id]) {
    DateTime? parseTimestamp(dynamic t) {
      if (t == null) return null;
      if (t is Timestamp) return t.toDate();
      if (t is DateTime) return t;
      return null;
    }

    // Resolve docId: prefer Firestore doc id param, then stored docId, then fallback to superAdminId
    final resolvedDocId = (id?.trim().isNotEmpty == true)
        ? id!.trim()
        : (data['docId']?.toString().trim().isNotEmpty == true)
            ? data['docId'].toString().trim()
            : (data['superAdminId']?.toString().trim().isNotEmpty == true)
                ? data['superAdminId'].toString().trim()
                : '';

    return SuperAdminModel(
      docId: resolvedDocId,
      superAdminId: data['superAdminId']?.toString(),
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phoneNumber: data['phoneNumber']?.toString(),
      createdAt: parseTimestamp(data['createdAt']),
      modifiedAt: parseTimestamp(data['modifiedAt']),
      isDisabled: data['isDisabled'] as bool? ?? false,
      isDeleted: data['isDeleted'] as bool? ?? false,
    );
  }

  SuperAdminModel copyWith({
    String? docId,
    String? superAdminId,
    String? name,
    String? email,
    String? phoneNumber,
    DateTime? createdAt,
    DateTime? modifiedAt,
    bool? isDisabled,
    bool? isDeleted,
  }) {
    return SuperAdminModel(
      docId: docId ?? this.docId,
      superAdminId: superAdminId ?? this.superAdminId,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      isDisabled: isDisabled ?? this.isDisabled,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  /// Create an empty model for form initialization
  factory SuperAdminModel.empty() {
    return SuperAdminModel(
      name: '',
      email: '',
    );
  }

  /// Check if this super admin is active (not disabled and not deleted)
  bool get isActive => !isDisabled && !isDeleted;

  @override
  String toString() {
    return 'SuperAdminModel(docId: $docId, name: $name, email: $email, isDisabled: $isDisabled, isDeleted: $isDeleted)';
  }
}
