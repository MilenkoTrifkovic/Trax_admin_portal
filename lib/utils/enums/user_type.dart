enum UserRole { superAdmin, admin, user, guest, planner, salesPerson }

/// Extension to handle conversion between Firestore format and enum
extension UserRoleExtension on UserRole {
  /// Convert enum to Firestore format (snake_case)
  String toFirestore() {
    switch (this) {
      case UserRole.superAdmin:
        return 'super_admin';
      case UserRole.admin:
        return 'admin';
      case UserRole.user:
        return 'user';
      case UserRole.guest:
        return 'guest';
      case UserRole.planner:
        return 'planner';
      case UserRole.salesPerson:
        return 'sales_person';
    }
  }

  /// Parse Firestore string (snake_case) to enum
  static UserRole fromFirestore(String firestoreValue) {
    switch (firestoreValue.toLowerCase()) {
      case 'super_admin':
        return UserRole.superAdmin;
      case 'admin':
        return UserRole.admin;
      case 'user':
        return UserRole.user;
      case 'guest':
        return UserRole.guest;
      case 'planner':
        return UserRole.planner;
      case 'sales_person':
        return UserRole.salesPerson;
      default:
        return UserRole.guest; // Default fallback
    }
  }
}
