import 'package:firebase_auth/firebase_auth.dart';
import '../models/password_reset_request.dart';

/// Service for handling password reset operations using Firebase Auth directly
class PasswordResetService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Verify the password reset code and get the associated email
  /// 
  /// Parameters:
  /// - [oobCode]: The password reset code from the email link
  /// 
  /// Returns the email associated with the code if valid
  /// Throws [FirebaseAuthException] if the code is invalid or expired
  Future<String> verifyResetCode(String oobCode) async {
    try {
      // Use Firebase Auth to verify the password reset code
      final email = await _auth.verifyPasswordResetCode(oobCode);
      print('✅ Verified reset code for email: $email');
      return email;
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth error verifying reset code: ${e.code} - ${e.message}');
      
      // Re-throw with user-friendly messages
      switch (e.code) {
        case 'invalid-action-code':
          throw Exception('Invalid or expired reset code. Please request a new password reset.');
        case 'expired-action-code':
          throw Exception('Reset code has expired. Please request a new password reset.');
        case 'user-disabled':
          throw Exception('This user account has been disabled.');
        case 'user-not-found':
          throw Exception('No user found with this reset code.');
        default:
          throw Exception('Failed to verify reset code: ${e.message}');
      }
    } catch (e) {
      print('❌ Unknown error verifying reset code: $e');
      throw Exception('Failed to verify reset code. Please try again.');
    }
  }

  /// Confirm password reset with new password
  /// 
  /// Parameters:
  /// - [request]: PasswordResetRequest containing oobCode and new password
  /// 
  /// Returns PasswordResetResponse with success status
  /// Throws [FirebaseAuthException] if the operation fails
  Future<PasswordResetResponse> confirmPasswordReset(
    PasswordResetRequest request,
  ) async {
    try {
      // Use Firebase Auth to confirm the password reset
      await _auth.confirmPasswordReset(
        code: request.oobCode,
        newPassword: request.newPassword,
      );
      
      print('✅ Password reset confirmed successfully');
      
      return PasswordResetResponse(
        success: true,
        message: 'Password has been reset successfully',
      );
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth error confirming password reset: ${e.code} - ${e.message}');
      
      // Re-throw with user-friendly messages
      String errorMessage;
      switch (e.code) {
        case 'invalid-action-code':
          errorMessage = 'Invalid or expired reset code. Please request a new password reset.';
          break;
        case 'expired-action-code':
          errorMessage = 'Reset code has expired. Please request a new password reset.';
          break;
        case 'weak-password':
          errorMessage = 'Password is too weak. Please choose a stronger password.';
          break;
        case 'user-disabled':
          errorMessage = 'This user account has been disabled.';
          break;
        case 'user-not-found':
          errorMessage = 'No user found with this reset code.';
          break;
        default:
          errorMessage = 'Failed to reset password: ${e.message}';
      }
      
      return PasswordResetResponse(
        success: false,
        message: errorMessage,
      );
    } catch (e) {
      print('❌ Unknown error confirming password reset: $e');
      return PasswordResetResponse(
        success: false,
        message: 'Failed to reset password. Please try again.',
      );
    }
  }
}
