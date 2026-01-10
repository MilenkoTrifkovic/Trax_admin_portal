import 'package:flutter/material.dart';
import 'package:trax_admin_portal/models/sales_person_model.dart';
import 'package:trax_admin_portal/theme/app_colors.dart';
import 'package:trax_admin_portal/theme/app_font_weight.dart';
import 'package:trax_admin_portal/theme/styled_app_text.dart';
import 'package:trax_admin_portal/utils/data/us_data.dart';
import 'package:trax_admin_portal/widgets/app_primary_button.dart';
import 'package:trax_admin_portal/widgets/app_secondary_button.dart';
import 'package:trax_admin_portal/widgets/dialogs/app_dialog.dart';

/// Reusable dialog for adding or editing a sales person.
/// 
/// This dialog handles both create and update modes:
/// - **Add Mode**: Empty form, onSubmit creates new sales person
/// - **Edit Mode**: Pre-filled form, onSubmit updates existing sales person
/// 
/// The dialog performs validation and only calls onSubmit callback if valid.
/// The actual business logic (Firestore operations) is handled by the controller.
class SalesPersonFormDialog extends StatefulWidget {
  /// Callback when form is submitted successfully.
  /// Receives the SalesPersonModel to be created or updated.
  final Future<void> Function(SalesPersonModel salesPerson) onSubmit;
  
  /// Optional: Existing sales person for edit mode.
  /// If null, dialog is in "add" mode.
  final SalesPersonModel? salesPerson;

  const SalesPersonFormDialog({
    super.key,
    required this.onSubmit,
    this.salesPerson,
  });

  @override
  State<SalesPersonFormDialog> createState() => _SalesPersonFormDialogState();
}

class _SalesPersonFormDialogState extends State<SalesPersonFormDialog> {
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  
  // Dropdown values
  String? _selectedState;
  String? _selectedCountry;
  
  // Toggle values
  bool _isActive = true;
  
  bool _isSubmitting = false;
  bool get _isEditMode => widget.salesPerson != null;

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with existing data if in edit mode
    final person = widget.salesPerson;
    _nameController = TextEditingController(text: person?.name ?? '');
    _emailController = TextEditingController(text: person?.email ?? '');
    _addressController = TextEditingController(text: person?.address ?? '');
    _cityController = TextEditingController(text: person?.city ?? '');
    
    // Initialize dropdown values
    _selectedState = person?.state;
    _selectedCountry = person?.country ?? 'United States';
    
    // Initialize toggle values
    _isActive = person?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  /// Validates form and submits if valid
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Build the sales person model
      final salesPerson = _isEditMode
          ? widget.salesPerson!.copyWith(
              name: _nameController.text.trim(),
              email: _emailController.text.trim(),
              address: _addressController.text.trim().isEmpty 
                  ? null 
                  : _addressController.text.trim(),
              city: _cityController.text.trim().isEmpty 
                  ? null 
                  : _cityController.text.trim(),
              state: _selectedState,
              country: _selectedCountry,
              isActive: _isActive,
            )
          : SalesPersonModel(
              name: _nameController.text.trim(),
              email: _emailController.text.trim(),
              address: _addressController.text.trim().isEmpty 
                  ? null 
                  : _addressController.text.trim(),
              city: _cityController.text.trim().isEmpty 
                  ? null 
                  : _cityController.text.trim(),
              state: _selectedState,
              country: _selectedCountry,
              isActive: _isActive,
            );

      // Call the callback (controller handles the actual Firestore operation)
      await widget.onSubmit(salesPerson);
      
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
            _isEditMode ? Icons.edit : Icons.person_add,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          AppText.styledHeadingSmall(
            context,
            _isEditMode ? 'Edit Sales Person' : 'Add Sales Person',
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
            _buildTextField(
              controller: _nameController,
              label: 'Full Name',
              hint: 'Enter full name',
              icon: Icons.person_outline,
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
            _buildTextField(
              controller: _emailController,
              label: 'Email',
              hint: 'Enter email address',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Email is required';
                }
                // Basic email validation
                final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                if (!emailRegex.hasMatch(value.trim())) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Address field (optional)
            _buildTextField(
              controller: _addressController,
              label: 'Street Address',
              hint: 'Enter street address (optional)',
              icon: Icons.home_outlined,
              required: false,
            ),
            
            const SizedBox(height: 16),
            
            // City, State, Country in rows
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _cityController,
                    label: 'City',
                    hint: 'Enter city',
                    icon: Icons.location_city_outlined,
                    required: false,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStateDropdown(),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Country dropdown
            _buildCountryDropdown(),
            
            const SizedBox(height: 24),
            
            // Active Status Toggle
            _buildActiveToggle(),
            
            const SizedBox(height: 8),
            
            // Helper text
            AppText.styledBodySmall(
              context,
              '* Required fields',
              color: AppColors.textMuted,
              style: FontStyle.italic,
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
          // Cancel button
          AppSecondaryButton(
            text: 'Cancel',
            onPressed: () => Navigator.of(context).pop(),
            enabled: !_isSubmitting,
          ),
          
          const SizedBox(width: 12),
          
          // Submit button
          AppPrimaryButton(
            text: _isEditMode ? 'Update' : 'Add',
            onPressed: _handleSubmit,
            enabled: !_isSubmitting,
            isLoading: _isSubmitting,
            backgroundColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  /// Build active status toggle
  Widget _buildActiveToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: SwitchListTile(
        title: AppText.styledBodyMedium(
          context,
          'Active Status',
          weight: AppFontWeight.medium,
          color: AppColors.primary,
        ),
        subtitle: AppText.styledBodySmall(
          context,
          _isActive 
              ? 'This sales person is currently active' 
              : 'This sales person is currently inactive',
          color: AppColors.textMuted,
        ),
        value: _isActive,
        activeColor: AppColors.success,
        onChanged: (bool value) {
          setState(() {
            _isActive = value;
          });
        },
      ),
    );
  }

  /// Build a reusable text field
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool required = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppText.styledBodyMedium(
              context,
              label,
              weight: AppFontWeight.medium,
              color: AppColors.secondary,
            ),
            if (required)
              AppText.styledBodyMedium(
                context,
                ' *',
                weight: AppFontWeight.bold,
                color: AppColors.inputError,
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
            prefixIcon: Icon(icon, size: 20, color: AppColors.textMuted),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.borderSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.inputError),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.inputError, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          style: TextStyle(
            fontSize: 14,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
  
  /// Build state dropdown field
  Widget _buildStateDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.styledBodyMedium(
          context,
          'State',
          weight: AppFontWeight.medium,
          color: AppColors.secondary,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedState,
          decoration: InputDecoration(
            hintText: 'Select state',
            hintStyle: TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
            prefixIcon: Icon(Icons.map_outlined, size: 20, color: AppColors.textMuted),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.borderSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          style: TextStyle(
            fontSize: 14,
            color: AppColors.primary,
          ),
          items: USData.states.map((String state) {
            return DropdownMenuItem<String>(
              value: state,
              child: Text(state),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedState = newValue;
            });
          },
        ),
      ],
    );
  }
  
  /// Build country dropdown field
  Widget _buildCountryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.styledBodyMedium(
          context,
          'Country',
          weight: AppFontWeight.medium,
          color: AppColors.secondary,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedCountry,
          decoration: InputDecoration(
            hintText: 'Select country',
            hintStyle: TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
            prefixIcon: Icon(Icons.public_outlined, size: 20, color: AppColors.textMuted),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.borderSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          style: TextStyle(
            fontSize: 14,
            color: AppColors.primary,
          ),
          items: ['United States'].map((String country) {
            return DropdownMenuItem<String>(
              value: country,
              child: Text(country),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedCountry = newValue;
            });
          },
        ),
      ],
    );
  }
}
