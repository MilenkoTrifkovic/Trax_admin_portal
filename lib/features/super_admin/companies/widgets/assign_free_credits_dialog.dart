import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:trax_admin_portal/features/super_admin/companies/controllers/assign_free_credits_controller.dart';
import 'package:trax_admin_portal/helper/app_padding.dart';
import 'package:trax_admin_portal/helper/app_spacing.dart';
import 'package:trax_admin_portal/theme/app_colors.dart';
import 'package:trax_admin_portal/theme/styled_app_text.dart';
import 'package:trax_admin_portal/utils/enums/sizes.dart';
import 'package:trax_admin_portal/widgets/app_primary_button.dart';
import 'package:trax_admin_portal/widgets/app_secondary_button.dart';
import 'package:trax_admin_portal/widgets/app_text_input_field.dart';
import 'package:trax_admin_portal/widgets/dialogs/app_dialog.dart';
import 'package:trax_admin_portal/widgets/dialogs/dialogs.dart';

/// Dialog for super admin to assign free event credits to a company
class AssignFreeCreditsDialog extends StatefulWidget {
  final String companyName;
  final String organisationId;

  const AssignFreeCreditsDialog({
    super.key,
    required this.companyName,
    required this.organisationId,
  });

  @override
  State<AssignFreeCreditsDialog> createState() => _AssignFreeCreditsDialogState();
}

class _AssignFreeCreditsDialogState extends State<AssignFreeCreditsDialog> {
  late final AssignFreeCreditsController controller;

  @override
  void initState() {
    super.initState();
    // Initialize controller
    controller = Get.put(
      AssignFreeCreditsController(
        organisationId: widget.organisationId,
        companyName: widget.companyName,
      ),
      tag: widget.organisationId,
    );
  }

  @override
  void dispose() {
    // Delete controller to clean up and reset state
    Get.delete<AssignFreeCreditsController>(tag: widget.organisationId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      header: _buildHeader(context, controller),
      content: _buildContent(context, controller),
      footer: _buildFooter(context, controller),
    );
  }

  Widget _buildHeader(
      BuildContext context, AssignFreeCreditsController controller) {
    return Padding(
      padding: AppPadding.all(context, paddingType: Sizes.lg),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.card_giftcard,
              color: AppColors.primaryAccent,
              size: 24,
            ),
          ),
          AppSpacing.horizontalMd(context),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.styledHeadingSmall(
                  context,
                  'Give Free Events',
                  color: AppColors.primary,
                ),
                AppText.styledBodySmall(
                  context,
                  'Assign free credits to ${widget.companyName}',
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, AssignFreeCreditsController controller) {
    return Padding(
      padding: AppPadding.symmetric(
        context,
        horizontalPadding: Sizes.lg,
        verticalPadding: Sizes.md,
      ),
      child: Form(
        key: controller.formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Events input
            AppTextInputField(
              label: 'Number of Events',
              controller: controller.eventsController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              hintText: 'Enter number of events',
              prefixIcon: Icon(Icons.event, color: AppColors.primaryAccent),
              validator: controller.validateEvents,
              autofocus: true,
              width: double.infinity,
            ),

            AppSpacing.verticalMd(context),

            // Note input (optional)
            AppTextInputField(
              label: 'Note (optional)',
              controller: controller.noteController,
              hintText: 'Add a note for this credit assignment',
              prefixIcon: Icon(Icons.note, color: AppColors.textMuted),
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(
      BuildContext context, AssignFreeCreditsController controller) {
    return Padding(
      padding: AppPadding.all(context, paddingType: Sizes.lg),
      child: Obx(
        () => Row(
          children: [
            Expanded(
              child: AppSecondaryButton(
                text: 'Cancel',
                onPressed: controller.isLoading.value 
                    ? null 
                    : () => Navigator.of(context).pop(),
                enabled: !controller.isLoading.value,
              ),
            ),
            AppSpacing.horizontalMd(context),
            Expanded(
              child: AppPrimaryButton(
                text: 'Assign Credits',
                icon: Icons.card_giftcard,
                onPressed: () => _handleSubmit(context, controller),
                isLoading: controller.isLoading.value,
                enabled: !controller.isLoading.value,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Handle submit with validation and confirmation
  void _handleSubmit(
      BuildContext context, AssignFreeCreditsController controller) {
    // Validate form
    if (!controller.validateForm()) return;

    final events = controller.getEventsCount();
    if (events == null) return;

    // Show confirmation dialog
    Dialogs.showConfirmationDialog(
      context,
      'You are about to assign $events free event${events > 1 ? 's' : ''} to ${widget.companyName}.\n\nThis action cannot be undone.',
      () {
        // Call the controller's assign method
        controller.assignCredits().then((success) {
          // Close the dialog after successful assignment
          if (success && context.mounted) {
            Navigator.of(context).pop(true);
          }
        });
      },
      title: 'Confirm Free Credits',
    );
  }
}
