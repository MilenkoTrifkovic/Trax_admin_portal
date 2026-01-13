import 'package:flutter/material.dart';
import 'package:trax_admin_portal/helper/app_spacing.dart';
import 'package:trax_admin_portal/helper/screen_size.dart';
import 'package:trax_admin_portal/theme/app_colors.dart';
import 'package:trax_admin_portal/theme/styled_app_text.dart';

/// Widget displaying company avatar, name, and organization details
class CompanyHeader extends StatelessWidget {
  final String companyName;

  const CompanyHeader({
    super.key,
    required this.companyName,
  });

  @override
  Widget build(BuildContext context) {
    final isPhone = ScreenSize.isPhone(context);
    final avatarSize = isPhone ? 48.0 : 56.0;

    return Row(
      children: [
        Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(isPhone ? 10 : 12),
          ),
          child: Center(
            child: isPhone
                ? AppText.styledHeadingSmall(
                    context,
                    companyName.isNotEmpty ? companyName[0].toUpperCase() : '?',
                    color: AppColors.primary,
                    weight: FontWeight.w700,
                  )
                : AppText.styledHeadingMedium(
                    context,
                    companyName.isNotEmpty ? companyName[0].toUpperCase() : '?',
                    color: AppColors.primary,
                  ),
          ),
        ),
        AppSpacing.horizontalMd(context),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              isPhone
                  ? AppText.styledHeadingMedium(
                      context,
                      companyName,
                      color: AppColors.primary,
                    )
                  : AppText.styledHeadingLarge(
                      context,
                      companyName,
                      color: AppColors.primary,
                    ),
              SizedBox(height: AppSpacing.xxxs(context)),
              isPhone
                  ? AppText.styledMetaSmall(
                      context,
                      'Organization Details',
                      color: AppColors.textMuted,
                    )
                  : AppText.styledBodySmall(
                      context,
                      'Organization Details',
                      color: AppColors.textMuted,
                    ),
            ],
          ),
        ),
      ],
    );
  }
}
