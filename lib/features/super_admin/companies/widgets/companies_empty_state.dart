import 'package:flutter/material.dart';
import 'package:trax_admin_portal/helper/app_spacing.dart';
import 'package:trax_admin_portal/theme/app_colors.dart';
import 'package:trax_admin_portal/theme/styled_app_text.dart';

/// Empty state widget shown when no companies match the filters
class CompaniesEmptyState extends StatelessWidget {
  const CompaniesEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.business_outlined,
            size: 64,
            color: AppColors.textMuted,
          ),
          AppSpacing.verticalMd(context),
          AppText.styledHeadingSmall(
            context,
            'No companies found',
            color: AppColors.textMuted,
            weight: FontWeight.w600,
          ),
          AppSpacing.verticalXs(context),
          AppText.styledBodySmall(
            context,
            'Try adjusting your search or filters',
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}
