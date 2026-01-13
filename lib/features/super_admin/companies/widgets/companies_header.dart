import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:trax_admin_portal/features/super_admin/companies/controllers/companies_controller.dart';
import 'package:trax_admin_portal/helper/app_spacing.dart';
import 'package:trax_admin_portal/theme/app_colors.dart';
import 'package:trax_admin_portal/theme/styled_app_text.dart';

/// Header widget for Companies page showing title, stats, and refresh button
class CompaniesHeader extends StatelessWidget {
  final CompaniesController controller;
  final bool isPhone;

  const CompaniesHeader({
    super.key,
    required this.controller,
    required this.isPhone,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
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
    );
  }
}
