import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:trax_admin_portal/controller/auth_controller/auth_controller.dart';
import 'package:trax_admin_portal/services/auth_services.dart';
import 'package:trax_admin_portal/services/cloud_functions_services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Controller for managing sign-in and sign-up functionality
class SignInController extends GetxController {
  final AuthServices _authServices = AuthServices();
  final CloudFunctionsService _cloudFunctionsService =
      Get.find<CloudFunctionsService>();
  final AuthController _authController = Get.find<AuthController>();

  // Observables
  final isLoading = false.obs;
  final isSignUpMode = false.obs;

  // If you later add HubSpot-style "usePassword" toggle
  final usePassword = false.obs;

  final isPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;

  final successMessage = RxnString();
  final errorMessage = RxnString();

  final authResult = Rxn<UserCredential>();

  // Navigation flags
  final shouldNavigateToEmailVerification = false.obs;
  final shouldNavigateToOrganisationInfo = false.obs;
  final shouldNavigateToHostEvents = false.obs;
  final shouldNavigateToSalesPersonDashboard = false.obs;
  final shouldNavigateToSuperAdminDashboard = false.obs;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  void toggleSignUpMode() => isSignUpMode.value = !isSignUpMode.value;
  void togglePasswordVisibility() =>
      isPasswordVisible.value = !isPasswordVisible.value;
  void toggleConfirmPasswordVisibility() =>
      isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  void togglePasswordMethod() => usePassword.value = !usePassword.value;

  // -------------------------------
  // Email/password
  // -------------------------------
  Future<void> handleEmailPasswordAuth({
    required String email,
    required String password,
  }) async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;
      _resetNavigationFlags();
      clearErrorMessage();
      clearSuccessMessage();

      UserCredential userCredential;

      if (isSignUpMode.value) {
        userCredential = await _authServices.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        await _authServices.sendEmailVerification();

        // Ensure profile exists (in case your rules require it)
        if (userCredential.user != null) {
          await _ensureUserProfileExists(userCredential.user!);
        }

        await _authController.loadUserProfile();
        authResult.value = userCredential;

        shouldNavigateToEmailVerification.value = true;
        return;
      } else {
        userCredential = await _authServices.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Ensure profile exists (in case a legacy user is missing it)
        if (userCredential.user != null) {
          await _ensureUserProfileExists(userCredential.user!);
        }

        await _postAuthRoute(userCredential);
      }
    } catch (e) {
      _showErrorMessage(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // -------------------------------
  // OAuth sign-in/up
  // -------------------------------
  Future<void> signInWithGoogle() async {
    final provider = GoogleAuthProvider()
      ..setCustomParameters({'prompt': 'select_account'});
    await _signInWithProvider(provider, label: 'Google');
  }

  Future<void> signInWithMicrosoft() async {
    final provider = OAuthProvider('microsoft.com')
      ..setCustomParameters({'prompt': 'select_account'});
    await _signInWithProvider(provider, label: 'Microsoft');
  }

  Future<void> signInWithApple() async {
    final provider = OAuthProvider('apple.com')
      ..addScope('email')
      ..addScope('name');
    await _signInWithProvider(provider, label: 'Apple');
  }

  Future<void> _signInWithProvider(
    AuthProvider provider, {
    required String label,
  }) async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;
      _resetNavigationFlags();
      clearErrorMessage();
      clearSuccessMessage();

      final auth = FirebaseAuth.instance;
      UserCredential userCredential;

      if (kIsWeb) {
        userCredential = await auth.signInWithPopup(provider);
      } else {
        userCredential = await auth.signInWithProvider(provider);
      }

      authResult.value = userCredential;

      final user = userCredential.user;
      if (user == null) {
        _showErrorMessage('Sign-in failed. Please try again.');
        return;
      }

      // ✅ create user profile if missing (new OAuth sign-up)
      await _ensureUserProfileExists(user);

      await _postAuthRoute(userCredential);
    } on FirebaseAuthException catch (e) {
      _showErrorMessage(_niceFirebaseAuthError(e));
    } catch (e) {
      _showErrorMessage(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // Create users/{uid} if missing (for OAuth sign-up)
  Future<void> _ensureUserProfileExists(User user) async {
    final ref = _db.collection('users').doc(user.uid);
    final snap = await ref.get();
    if (snap.exists) return;

    await ref.set({
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'role': 'admin', // ✅ admin portal default
      'organisationId': null,
      'createdAt': FieldValue.serverTimestamp(),
      'modifiedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Routing after any auth
  Future<void> _postAuthRoute(UserCredential userCredential) async {
    await _authController.loadUserProfile();

    final user = userCredential.user;
    if (user == null) return;

    // ✅ sales person routing (your cached value)
    final sp = _authController.salesPerson.value;
    if (sp != null && sp.isActive && !sp.isDisabled) {
      shouldNavigateToSalesPersonDashboard.value = true;
      return;
    }

    // ✅ super admin routing
    if (_authController.isSuperAdmin) {
      shouldNavigateToSuperAdminDashboard.value = true;
      return;
    }

    // ✅ only require email verification for password users
    final signedInWithPassword =
        user.providerData.any((p) => p.providerId == 'password');

    if (signedInWithPassword && !user.emailVerified) {
      shouldNavigateToEmailVerification.value = true;
      return;
    }

    if (!_authController.companyInfoExists) {
      shouldNavigateToOrganisationInfo.value = true;
      return;
    }

    shouldNavigateToHostEvents.value = true;
  }

  // Forgot password
  Future<void> handleForgotPassword(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) {
      _showErrorMessage('Please enter your email address first');
      return;
    }

    try {
      await _authServices.sendPasswordResetEmail(trimmed);
      _showSuccessMessage('Password reset email sent! Check your inbox.');
    } catch (e) {
      _showErrorMessage(e.toString());
    }
  }

  // Helpers
  void _resetNavigationFlags() {
  shouldNavigateToHostEvents.value = false;
  shouldNavigateToEmailVerification.value = false;
  shouldNavigateToOrganisationInfo.value = false;
  shouldNavigateToSalesPersonDashboard.value = false;
  shouldNavigateToSuperAdminDashboard.value = false;
  }

  void clearNavigationFlags() {
    _resetNavigationFlags();
    authResult.value = null;
  }

  void _showSuccessMessage(String message) => successMessage.value = message;
  void _showErrorMessage(String message) => errorMessage.value = message;

  void clearSuccessMessage() => successMessage.value = null;
  void clearErrorMessage() => errorMessage.value = null;

  String _niceFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'account-exists-with-different-credential':
        return 'This email already exists with a different sign-in method. Please try the original provider.';
      case 'popup-closed-by-user':
        return 'Sign-in popup was closed before completing.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled yet in Firebase.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return e.message ?? 'Authentication error. Please try again.';
    }
  }
}
