import 'package:flutter/material.dart';
import 'package:trax_admin_portal/helper/app_padding.dart';
import 'package:trax_admin_portal/helper/app_spacing.dart';
import 'package:trax_admin_portal/theme/app_colors.dart';
import 'package:trax_admin_portal/theme/styled_app_text.dart';
import 'package:trax_admin_portal/utils/enums/sizes.dart';

/// Empty state widget shown when there are no transactions
class TransactionEmptyState extends StatelessWidget {
  final VoidCallback? onGiveFreeEvents;

  const TransactionEmptyState({
    super.key,
    this.onGiveFreeEvents,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppPadding.all(context, paddingType: Sizes.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: AppColors.textMuted,
          ),
          AppSpacing.verticalMd(context),
          AppText.styledBodyMedium(
            context,
            'No transactions yet',
            color: AppColors.textMuted,
            textAlign: TextAlign.center,
          ),
          AppSpacing.verticalXs(context),
          AppText.styledBodySmall(
            context,
            'Transactions will appear here once the company makes a purchase.',
            color: AppColors.textMuted,
            textAlign: TextAlign.center,
          ),
          if (onGiveFreeEvents != null) ...[
            AppSpacing.verticalLg(context),
            ElevatedButton.icon(
              onPressed: onGiveFreeEvents,
              icon: Icon(Icons.card_giftcard, size: 18),
              label: Text('Give Free Events'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade600,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
