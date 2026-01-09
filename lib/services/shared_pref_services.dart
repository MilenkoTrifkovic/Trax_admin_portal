import 'package:shared_preferences/shared_preferences.dart';
import 'package:trax_admin_portal/utils/enums/user_type.dart';

/// Service class for managing shared preferences
/// Currently handles saving and retrieving user role.
class SharedPrefServices {
  void saveUserRole(UserRole role) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Save in Firestore format for consistency
    await prefs.setString('userRole', role.toFirestore());
  }

  Future<UserRole?> getUserRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? roleString = prefs.getString('userRole');
    if (roleString != null) {
      return UserRoleExtension.fromFirestore(roleString);
    }
    return null;
  }

  void clearUserRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userRole');
  }
}
