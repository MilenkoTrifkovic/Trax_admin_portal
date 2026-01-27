import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trax_admin_portal/helper/app_spacing.dart';
import 'package:trax_admin_portal/models/payment.dart';
import 'package:trax_admin_portal/theme/app_colors.dart';
import 'package:trax_admin_portal/theme/styled_app_text.dart';

import 'transaction_badges.dart';

/// Desktop layout content for a transaction item
class TransactionDesktopContent extends StatelessWidget {
  final Payment transaction;
  final DateFormat dateFormatter;
  final DateFormat timeFormatter;

  const TransactionDesktopContent({
    super.key,
    required this.transaction,
    required this.dateFormatter,
    required this.timeFormatter,
  });

  bool get isFreeCredit => transaction.isFree;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Gift indicator for free credits
        if (isFreeCredit)
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: Icon(
              Icons.card_giftcard,
              size: 18,
              color: Colors.amber.shade700,
            ),
          ),
        // Date column
        _buildDateColumn(context),
        // Transaction ID column or Gift source
        Expanded(
          flex: 2,
          child: isFreeCredit
              ? _buildGiftSourceColumn(context)
              : _buildTransactionIdColumn(context),
        ),
        AppSpacing.horizontalMd(context),
        // Package/Product column
        _buildPackageColumn(context),
        // Events column
        _buildEventsColumn(context),
        AppSpacing.horizontalMd(context),
        // Amount column
        _buildAmountColumn(context),
        AppSpacing.horizontalMd(context),
        // Status column
        _buildStatusColumn(),
      ],
    );
  }

  Widget _buildDateColumn(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.styledBodySmall(
            context,
            transaction.createdAt != null
                ? dateFormatter.format(transaction.createdAt!)
                : 'Unknown',
            weight: FontWeight.w500,
          ),
          AppText.styledMetaSmall(
            context,
            transaction.createdAt != null
                ? timeFormatter.format(transaction.createdAt!)
                : '',
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }

  Widget _buildGiftSourceColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.styledBodySmall(
          context,
          transaction.displaySource,
          color: Colors.amber.shade700,
          weight: FontWeight.w500,
        ),
        if (transaction.note != null && transaction.note!.isNotEmpty)
          AppText.styledMetaSmall(
            context,
            transaction.note!,
            color: AppColors.textMuted,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  Widget _buildTransactionIdColumn(BuildContext context) {
    if (transaction.transactionId != null &&
        transaction.transactionId!.isNotEmpty) {
      return TransactionIdRow(transactionId: transaction.transactionId!);
    }
    return AppText.styledMetaSmall(
      context,
      'No ID',
      color: AppColors.textMuted,
    );
  }

  Widget _buildPackageColumn(BuildContext context) {
    return Expanded(
      flex: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.styledBodyMedium(
            context,
            transaction.displayPackageName,
            weight: FontWeight.w500,
            overflow: TextOverflow.ellipsis,
          ),
          if (!isFreeCredit && transaction.userEmail != null)
            AppText.styledMetaSmall(
              context,
              transaction.userEmail!,
              color: AppColors.textMuted,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  Widget _buildEventsColumn(BuildContext context) {
    return SizedBox(
      width: 100,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm(context),
          vertical: AppSpacing.xxxs(context),
        ),
        decoration: BoxDecoration(
          color: isFreeCredit
              ? Colors.amber.withOpacity(0.1)
              : AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: AppText.styledBodySmall(
          context,
          '${transaction.events} events',
          color: isFreeCredit ? Colors.amber.shade700 : AppColors.primary,
          weight: FontWeight.w600,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildAmountColumn(BuildContext context) {
    return SizedBox(
      width: 100,
      child: AppText.styledBodyMedium(
        context,
        transaction.formattedAmount,
        color: isFreeCredit ? Colors.amber.shade700 : AppColors.success,
        weight: FontWeight.w600,
        textAlign: TextAlign.right,
      ),
    );
  }

  Widget _buildStatusColumn() {
    return SizedBox(
      width: 90,
      child: isFreeCredit
          ? const FreeCreditBadge()
          : TransactionStatusBadge(status: transaction.paymentStatus),
    );
  }
}
