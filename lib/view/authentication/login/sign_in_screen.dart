import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:trax_admin_portal/controller/auth_controller/sign_in_controller.dart';
import 'package:trax_admin_portal/controller/auth_controller/auth_controller.dart';
import 'package:trax_admin_portal/utils/navigation/app_routes.dart';
import 'package:trax_admin_portal/utils/navigation/routes.dart';
import 'package:trax_admin_portal/controller/global_controllers/snackbar_message_controller.dart';
import 'package:trax_admin_portal/view/authentication/login/widgets/sign_in_header.dart';
import 'package:trax_admin_portal/view/authentication/login/widgets/sign_in_form.dart';
import 'package:trax_admin_portal/view/authentication/login/widgets/sign_in_toggle.dart';

//TODO: UI should be redefined for this screen
class SignInScreenWidget extends StatefulWidget {
  const SignInScreenWidget({super.key});

  @override
  State<SignInScreenWidget> createState() => _SignInScreenWidgetState();
}

class _SignInScreenWidgetState extends State<SignInScreenWidget> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late final SnackbarMessageController snackbarController;
  late final SignInController controller;

  final List<Worker> _workers = [];

  @override
  void initState() {
    super.initState();

    snackbarController = Get.find<SnackbarMessageController>();

    controller = Get.isRegistered<SignInController>()
        ? Get.find<SignInController>()
        : Get.put(SignInController());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupListeners();
    });
  }

  @override
  void dispose() {
    for (final w in _workers) {
      w.dispose();
    }
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailPasswordAuth() async {
    if (!_formKey.currentState!.validate()) return;

    await controller.handleEmailPasswordAuth(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  Future<void> _handleForgotPassword() async {
    await controller.handleForgotPassword(_emailController.text.trim());
  }

  void _clearFormAndToggleMode() {
    controller.toggleSignUpMode();
    controller.usePassword.value =
        false; // ✅ reset password section if you add it in UI
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: SizedBox(
          width: 400,
          child: Card(
            elevation: 0,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SignInHeader(controller: controller),
                  SignInForm(
                    controller: controller,
                    formKey: _formKey,
                    emailController: _emailController,
                    passwordController: _passwordController,
                    confirmPasswordController: _confirmPasswordController,
                    onSubmit: _handleEmailPasswordAuth,
                    onForgotPassword: _handleForgotPassword,
                  ),
                  const SizedBox(height: 12),
                  SignInToggle(
                    controller: controller,
                    onToggle: _clearFormAndToggleMode,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _setupListeners() {
    _workers.add(ever(controller.shouldNavigateToSuperAdminDashboard, (bool go) {
      if (go) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          pushAndRemoveAllRoute(AppRoute.superAdminDashboard, context);
          controller.clearNavigationFlags();
        });
      }
    }));
    _workers.add(ever(controller.successMessage, (String? message) {
      if (message != null && message.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          snackbarController.showSuccessMessage(message);
          controller.clearSuccessMessage();
        });
      }
    }));

    _workers.add(ever(controller.errorMessage, (String? message) {
      if (message != null && message.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          snackbarController.showErrorMessage(message);
          controller.clearErrorMessage();
        });
      }
    }));

    _workers.add(ever(controller.shouldNavigateToEmailVerification, (bool go) {
      if (go) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          pushAndRemoveAllRoute(AppRoute.emailVerification, context);
          controller.clearNavigationFlags();
        });
      }
    }));

    // _workers.add(ever(controller.shouldNavigateToOrganisationInfo, (bool go) {
    //   if (go) {
    //     WidgetsBinding.instance.addPostFrameCallback((_) {
    //       pushAndRemoveAllRoute(AppRoute.hostOrganisationInfoForm, context);
    //       controller.clearNavigationFlags();
    //     });
    //   }
    // }));

    // _workers.add(ever(controller.shouldNavigateToHostEvents, (bool go) {
    //   if (go) {
    //     WidgetsBinding.instance.addPostFrameCallback((_) {
    //       pushAndRemoveAllRoute(AppRoute.hostEvents, context);
    //       controller.clearNavigationFlags();
    //     });
    //   }
    // }));

    _workers.add(ever(controller.shouldNavigateToSalesPersonDashboard, (bool go) {
      if (go) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Check user role and push to correct dashboard
          final authController = Get.find<AuthController>();
          if (authController.isSuperAdmin) {
            pushAndRemoveAllRoute(AppRoute.superAdminDashboard, context);
          } else if (authController.isSalesPerson) {
            pushAndRemoveAllRoute(AppRoute.salesPersonDashboard, context);
          }
          controller.clearNavigationFlags();
        });
      }
    }));
  }
}
