import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trax_admin_portal/utils/enums/user_type.dart';

/// Unified User model that supports all user types including sales people.
///
/// Common fields for all users:
/// - `userId` : Firebase Auth UID or logical user id
/// - `name` : User's full name
/// - `email` : User's email address
/// - `password` : User password (nullable, typically null as we use Firebase Auth)
/// - `role` : UserRole enum (superAdmin, admin, user, guest, planner, salesPerson)
/// - `country` : User's country
/// - `createdAt` : Timestamp when user was created
/// - `modifiedAt` : Timestamp when user was last modified
/// - `isDisabled` : Whether the user is disabled (also controls active/inactive status for sales people)
/// - `managedByOrgIds` : List of organisation IDs this user manages (null for sales people)
/// - `organisationId` : Organisation this user belongs to (null for sales people)
/// - `refCode` : Reference code (used for sales people, null for others)
///
/// Sales person specific fields:
/// - `address`, `city`, `state` : Location details (null for non-sales users)
///
/// Note: For sales people, isDisabled controls their active/inactive status
class UserModel {
  final String? userId;
  final String name;
  final String email;
  final String? password; // Typically null, stored for future use
  final UserRole role;
  final String? country;
  final DateTime? createdAt;
  final DateTime? modifiedAt;
  final bool isDisabled;
  final List<String>? managedByOrgIds;
  final String? organisationId;
  final String? refCode;
  
  // Sales person specific fields
  final String? address;
  final String? city;
  final String? state;

  UserModel({
    this.userId,
    required this.name,
    required this.email,
    this.password,
    required this.role,
    this.country,
    this.createdAt,
    this.modifiedAt,
    this.isDisabled = false,
    this.managedByOrgIds,
    this.organisationId,
    this.refCode,
    // Sales person specific
    this.address,
    this.city,
    this.state,
  });

  /// Firestore: create (new document)
  Map<String, dynamic> toFirestoreCreate() {
    return {
      if (userId != null) 'userId': userId,
      'name': name,
      'email': email,
      if (password != null) 'password': password,
      'role': role.toFirestore(),
      if (country != null) 'country': country,
      'isDisabled': isDisabled,
      'managedByOrgIds': managedByOrgIds, // Always save, even if null
      'organisationId': organisationId, // Always save, even if null
      if (refCode != null) 'refCode': refCode,
      // Sales person specific fields
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      'createdAt': FieldValue.serverTimestamp(),
      'modifiedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Firestore: update (existing document)
  Map<String, dynamic> toFirestoreUpdate() {
    return {
      if (userId != null) 'userId': userId,
      'name': name,
      'email': email,
      if (password != null) 'password': password,
      'role': role.toFirestore(),
      if (country != null) 'country': country,
      'isDisabled': isDisabled,
      'managedByOrgIds': managedByOrgIds, // Always save, even if null
      'organisationId': organisationId, // Always save, even if null
      if (refCode != null) 'refCode': refCode,
      // Sales person specific fields
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      // keep old createdAt, only update modifiedAt
      'modifiedAt': FieldValue.serverTimestamp(),
    };
  }

  factory UserModel.fromFirestore(Map<String, dynamic> data, [String? id]) {
    return UserModel(
      userId: data['userId'] as String? ?? id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      password: data['password'] as String?,
      role: UserRoleExtension.fromFirestore(
        data['role'] as String? ?? 'user',
      ),
      country: data['country'] as String?,
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      modifiedAt: (data['modifiedAt'] is Timestamp)
          ? (data['modifiedAt'] as Timestamp).toDate()
          : null,
      isDisabled: data['isDisabled'] as bool? ?? false,
      managedByOrgIds: (data['managedByOrgIds'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      organisationId: data['organisationId'] as String?,
      refCode: data['refCode'] as String?,
      // Sales person specific fields
      address: data['address'] as String?,
      city: data['city'] as String?,
      state: data['state'] as String?,
    );
  }

  UserModel copyWith({
    String? userId,
    String? name,
    String? email,
    String? password,
    UserRole? role,
    String? country,
    DateTime? createdAt,
    DateTime? modifiedAt,
    bool? isDisabled,
    List<String>? managedByOrgIds,
    String? organisationId,
    String? refCode,
    String? address,
    String? city,
    String? state,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      country: country ?? this.country,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      isDisabled: isDisabled ?? this.isDisabled,
      managedByOrgIds: managedByOrgIds ?? this.managedByOrgIds,
      organisationId: organisationId ?? this.organisationId,
      refCode: refCode ?? this.refCode,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
    );
  }

  @override
  String toString() {
    return 'UserModel('
        'userId: $userId, '
        'name: $name, '
        'email: $email, '
        'role: $role, '
        'country: $country, '
        'organisationId: $organisationId, '
        'refCode: $refCode, '
        'isDisabled: $isDisabled'
        ')';
  }
}
