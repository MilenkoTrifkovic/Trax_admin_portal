import 'package:flutter/material.dart';
import 'package:trax_admin_portal/helper/app_padding.dart';
import 'package:trax_admin_portal/helper/app_spacing.dart';
import 'package:trax_admin_portal/theme/app_colors.dart';
import 'package:trax_admin_portal/theme/styled_app_text.dart';
import 'package:trax_admin_portal/utils/enums/sizes.dart';

/// Toggle button to show more/less transactions
class TransactionToggleButton extends StatelessWidget {
  final bool isExpanded;
  final int totalCount;
  final VoidCallback? onToggle;

  const TransactionToggleButton({
    super.key,
    required this.isExpanded,
    required this.totalCount,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      child: Container(
        width: double.infinity,
        padding: AppPadding.symmetric(
          context,
          horizontalPadding: Sizes.md,
          verticalPadding: Sizes.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 20,
              color: AppColors.primaryAccent,
            ),
            AppSpacing.horizontalXs(context),
            AppText.styledBodySmall(
              context,
              isExpanded ? 'Show less' : 'Show all $totalCount transactions',
              color: AppColors.primaryAccent,
              weight: FontWeight.w500,
            ),
          ],
        ),
      ),
    );
  }
}
