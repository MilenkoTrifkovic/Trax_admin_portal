import 'package:flutter/material.dart';
import 'package:trax_admin_portal/models/sales_person_model.dart';
import 'package:trax_admin_portal/theme/app_colors.dart';
import 'package:trax_admin_portal/theme/app_font_weight.dart';

/// Confirmation dialog for deleting a sales person
class DeleteSalesPersonDialog extends StatelessWidget {
  final SalesPersonModel salesPerson;
  final VoidCallback onConfirm;
  
  const DeleteSalesPersonDialog({
    super.key,
    required this.salesPerson,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Delete Sales Person',
        style: TextStyle(fontWeight: AppFontWeight.semiBold),
      ),
      content: Text(
        'Are you sure you want to delete ${salesPerson.name}? This action will mark them as disabled.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
