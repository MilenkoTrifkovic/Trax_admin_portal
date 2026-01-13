import 'package:flutter/material.dart';
import 'package:trax_admin_portal/helper/app_padding.dart';
import 'package:trax_admin_portal/helper/app_spacing.dart';
import 'package:trax_admin_portal/helper/screen_size.dart';
import 'package:trax_admin_portal/theme/app_colors.dart';
import 'package:trax_admin_portal/theme/styled_app_text.dart';
import 'package:trax_admin_portal/utils/enums/sizes.dart';

/// Reusable card widget for displaying stats like total events
class InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const InfoCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isPhone = ScreenSize.isPhone(context);

    return Container(
      padding: isPhone
          ? AppPadding.all(context, paddingType: Sizes.md)
          : AppPadding.all(context, paddingType: Sizes.lg),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isPhone ? 10 : 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: isPhone ? 20 : 24,
            ),
          ),
          AppSpacing.horizontalMd(context),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.styledMetaSmall(
                  context,
                  label,
                  color: AppColors.textMuted,
                  weight: FontWeight.w500,
                ),
                SizedBox(height: AppSpacing.xxxs(context)),
                isPhone
                    ? AppText.styledHeadingMedium(
                        context,
                        value,
                        color: color,
                      )
                    : AppText.styledHeadingLarge(
                        context,
                        value,
                        color: color,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
