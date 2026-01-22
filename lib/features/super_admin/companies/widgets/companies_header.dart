import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:trax_admin_portal/controller/auth_controller/auth_controller.dart';
import 'package:trax_admin_portal/controller/global_controllers/snackbar_message_controller.dart';
import 'package:trax_admin_portal/features/super_admin/companies/controllers/companies_controller.dart';
import 'package:trax_admin_portal/helper/app_spacing.dart';
import 'package:trax_admin_portal/theme/app_colors.dart';
import 'package:trax_admin_portal/theme/app_font_weight.dart';
import 'package:trax_admin_portal/theme/styled_app_text.dart';

/// Header widget for Companies page showing title, stats, and refresh button
class CompaniesHeader extends StatelessWidget {
  final CompaniesController controller;
  final bool isPhone;
  final AuthController authController;

  const CompaniesHeader({
    super.key,
    required this.controller,
    required this.isPhone,
    required this.authController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  isPhone
                      ? AppText.styledHeadingMedium(context, 'Companies',
                          color: AppColors.primary)
                      : AppText.styledHeadingLarge(context, 'Companies',
                          color: AppColors.primary),
                  SizedBox(height: AppSpacing.xxxs(context)),
                  Obx(() => isPhone
                        ? AppText.styledMetaSmall(
                            context,
                            '${controller.filteredCompanies.length} companies • ${controller.getTotalEventCount()} total events',
                            color: AppColors.textMuted,
                          )
                        : AppText.styledBodySmall(
                            context,
                            '${controller.filteredCompanies.length} companies • ${controller.getTotalEventCount()} total events',
                            color: AppColors.textMuted,
                          )),
                ],
              ),
            ),
            // Refresh button
            Obx(() => IconButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : controller.refreshCompanies,
                  icon: controller.isLoading.value
                      ? SizedBox(
                          width: isPhone ? 18 : 20,
                          height: isPhone ? 18 : 20,
                          child: const CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.refresh, size: isPhone ? 20 : 24),
                  tooltip: 'Refresh',
                )),
          ],
        ),
        
        // Reference Code for Sales People
        Obx(() {
          if (!authController.isSalesPerson) return const SizedBox.shrink();
          
          final refCode = authController.salesPerson.value?.refCode;
          if (refCode == null || refCode.isEmpty) return const SizedBox.shrink();
          
          return Padding(
            padding: EdgeInsets.only(top: AppSpacing.sm(context)),
            child: _buildRefCodeBadge(context, refCode),
          );
        }),
      ],
    );
  }

  /// Build reference code badge with copy button
  Widget _buildRefCodeBadge(BuildContext context, String refCode) {
    final snackbarController = Get.find<SnackbarMessageController>();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.badge_outlined,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Your Reference Code: ',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          AppText.styledBodyMedium(
            context,
            refCode,
            color: AppColors.primary,
            weight: AppFontWeight.semiBold,
            isSelectable: true,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.copy, size: 16, color: AppColors.primary),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 28,
              minHeight: 28,
            ),
            tooltip: 'Copy reference code',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: refCode));
              snackbarController.showSuccessMessage(
                'Reference code "$refCode" copied to clipboard',
              );
            },
          ),
        ],
      ),
    );
  }
}
