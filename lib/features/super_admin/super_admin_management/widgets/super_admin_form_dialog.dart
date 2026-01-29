import 'package:flutter/material.dart';
import 'package:trax_admin_portal/models/super_admin_model.dart';
import 'package:trax_admin_portal/theme/app_colors.dart';
import 'package:trax_admin_portal/theme/app_font_weight.dart';
import 'package:trax_admin_portal/theme/styled_app_text.dart';
import 'package:trax_admin_portal/widgets/app_primary_button.dart';
import 'package:trax_admin_portal/widgets/app_secondary_button.dart';
import 'package:trax_admin_portal/widgets/app_text_input_field.dart';
import 'package:trax_admin_portal/widgets/dialogs/app_dialog.dart';

/// Reusable dialog for adding or editing a super admin.
///
/// This dialog handles both create and update modes:
/// - **Add Mode**: Empty form, onSubmit creates new super admin
/// - **Edit Mode**: Pre-filled form, onSubmit updates existing super admin
///
/// The dialog performs validation and only calls onSubmit callback if valid.
/// The actual business logic (cloud function operations) is handled by the controller.
class SuperAdminFormDialog extends StatefulWidget {
  /// Callback when form is submitted successfully.
  /// Receives the SuperAdminModel to be created or updated.
  final Future<void> Function(SuperAdminModel superAdmin) onSubmit;

  /// Optional: Existing super admin for edit mode.
  /// If null, dialog is in "add" mode.
  final SuperAdminModel? superAdmin;

  const SuperAdminFormDialog({
    super.key,
    required this.onSubmit,
    this.superAdmin,
  });

  @override
  State<SuperAdminFormDialog> createState() => _SuperAdminFormDialogState();
}

class _SuperAdminFormDialogState extends State<SuperAdminFormDialog> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  bool _isSubmitting = false;
  bool get _isEditMode => widget.superAdmin != null;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing data if in edit mode
    final admin = widget.superAdmin;
    _nameController = TextEditingController(text: admin?.name ?? '');
    _emailController = TextEditingController(text: admin?.email ?? '');
    _phoneController = TextEditingController(text: admin?.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Validates form and submits if valid
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Build the super admin model
      final superAdmin = _isEditMode
          ? widget.superAdmin!.copyWith(
              name: _nameController.text.trim(),
              email: _emailController.text.trim(),
              phoneNumber: _phoneController.text.trim().isEmpty
                  ? null
                  : _phoneController.text.trim(),
            )
          : SuperAdminModel(
              name: _nameController.text.trim(),
              email: _emailController.text.trim(),
              phoneNumber: _phoneController.text.trim().isEmpty
                  ? null
                  : _phoneController.text.trim(),
            );

      // Call the callback (controller handles the actual cloud function operation)
      await widget.onSubmit(superAdmin);

      // Close dialog on success
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Error is already handled by controller with snackbar
      print('Error in form dialog: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: AppDialog(
        header: _buildHeader(),
        content: _buildForm(),
        footer: _buildFooter(),
      ),
    );
  }

  /// Build dialog header
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: const Color(0xFFE5E7EB)),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isEditMode ? Icons.edit : Icons.admin_panel_settings,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          AppText.styledHeadingSmall(
            context,
            _isEditMode ? 'Edit Super Admin' : 'Add Super Admin',
            weight: AppFontWeight.semiBold,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  /// Build form content
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Name field (required)
            AppTextInputField(
              label: 'Full Name',
              hintText: 'Enter full name',
              controller: _nameController,
              prefixIcon: const Icon(Icons.person_outline),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Name is required';
                }
                if (value.trim().length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Email field (required)
            AppTextInputField(
              label: 'Email',
              hintText: 'Enter email address',
              controller: _emailController,
              prefixIcon: const Icon(Icons.email_outlined),
              keyboardType: TextInputType.emailAddress,
              enabled: !_isEditMode, // Email cannot be changed in edit mode
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Email is required';
                }
                // Simple email validation
                final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                if (!emailRegex.hasMatch(value.trim())) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Phone field (optional)
            AppTextInputField(
              label: 'Phone Number (Optional)',
              hintText: 'Enter phone number',
              controller: _phoneController,
              prefixIcon: const Icon(Icons.phone_outlined),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }

  /// Build dialog footer with action buttons
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: const Color(0xFFE5E7EB)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AppSecondaryButton(
            text: 'Cancel',
            onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 12),
          AppPrimaryButton(
            text: _isEditMode ? 'Update' : 'Create',
            onPressed: _isSubmitting ? null : _handleSubmit,
            isLoading: _isSubmitting,
          ),
        ],
      ),
    );
  }
}
