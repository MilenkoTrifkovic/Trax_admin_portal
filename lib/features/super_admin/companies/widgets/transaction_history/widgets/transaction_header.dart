import 'package:flutter/material.dart';
import 'package:trax_admin_portal/helper/app_padding.dart';
import 'package:trax_admin_portal/helper/app_spacing.dart';
import 'package:trax_admin_portal/helper/screen_size.dart';
import 'package:trax_admin_portal/theme/app_colors.dart';
import 'package:trax_admin_portal/theme/styled_app_text.dart';
import 'package:trax_admin_portal/utils/enums/sizes.dart';

/// Header widget for transaction history section
class TransactionHeader extends StatelessWidget {
  final int transactionCount;
  final VoidCallback? onGiveFreeEvents;

  const TransactionHeader({
    super.key,
    required this.transactionCount,
    this.onGiveFreeEvents,
  });

  @override
  Widget build(BuildContext context) {
    final isPhone = ScreenSize.isPhone(context);

    return Padding(
      padding: isPhone
          ? AppPadding.all(context, paddingType: Sizes.md)
          : AppPadding.symmetric(
              context,
              horizontalPadding: Sizes.lg,
              verticalPadding: Sizes.md,
            ),
      child: Row(
        children: [
          _buildIconContainer(context, isPhone),
          AppSpacing.horizontalSm(context),
          Expanded(
            child: _buildTitleColumn(context),
          ),
          if (onGiveFreeEvents != null)
            _GiveFreeEventsButton(
              onPressed: onGiveFreeEvents!,
              isPhone: isPhone,
            ),
        ],
      ),
    );
  }

  Widget _buildIconContainer(BuildContext context, bool isPhone) {
    return Container(
      padding: EdgeInsets.all(isPhone ? 8 : 10),
      decoration: BoxDecoration(
        color: AppColors.primaryAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.receipt_long,
        color: AppColors.primaryAccent,
        size: isPhone ? 18 : 20,
      ),
    );
  }

  Widget _buildTitleColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.styledBodyMedium(
          context,
          'Transaction History',
          color: AppColors.primary,
          weight: FontWeight.w600,
        ),
        AppText.styledMetaSmall(
          context,
          '$transactionCount transaction${transactionCount != 1 ? 's' : ''}',
          color: AppColors.textMuted,
        ),
      ],
    );
  }
}

/// Button to give free events
class _GiveFreeEventsButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isPhone;

  const _GiveFreeEventsButton({
    required this.onPressed,
    required this.isPhone,
  });

  @override
  Widget build(BuildContext context) {
    if (isPhone) {
      return IconButton(
        onPressed: onPressed,
        tooltip: 'Give Free Events',
        icon: Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.card_giftcard,
            color: Colors.amber.shade700,
            size: 18,
          ),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(Icons.card_giftcard, size: 16),
      label: Text('Give Free Events'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.amber.shade600,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
